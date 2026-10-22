import {
    BadRequestException,
    ForbiddenException,
    Injectable,
    NotFoundException,
    ServiceUnavailableException,
    UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { InjectRepository } from "@nestjs/typeorm";
import { timingSafeEqual } from "crypto";
import { IsNull, QueryFailedError, Repository } from "typeorm";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { buildVietQr } from "../billing/vietqr.util";
import { NotificationEntity } from "./notification.entity";
import { PaymentTransactionEntity } from "./payment-transaction.entity";
import { SepayWebhookDTO } from "./payment.dto";

const vnd = (n: number) => `${n.toLocaleString("vi-VN")} đ`;
/** Transfer note for an appointment; the webhook matches it back. */
export const transferContent = (appointmentId: number) => `DACN${appointmentId}`;

@Injectable()
export class PaymentService {
    private readonly bank: { bin?: string; name?: string; accountNo?: string; accountName?: string };
    private readonly sepayKey?: string;

    constructor(
        @InjectRepository(AppointmentEntity) private readonly appointments: Repository<AppointmentEntity>,
        @InjectRepository(NotificationEntity) private readonly notifications: Repository<NotificationEntity>,
        config: ConfigService,
    ) {
        this.bank = {
            bin: config.get<string>("PAYMENT_BANK_BIN"),
            name: config.get<string>("PAYMENT_BANK_NAME"),
            accountNo: config.get<string>("PAYMENT_ACCOUNT_NO"),
            accountName: config.get<string>("PAYMENT_ACCOUNT_NAME"),
        };
        this.sepayKey = config.get<string>("SEPAY_API_KEY") || undefined;
    }

    // ---------- patient ----------

    /** Patient picks cash or QR for an examined appointment with an unpaid bill. */
    async pay(patientId: number, appointmentId: number, method: "cash" | "qr") {
        const a = await this.appointments.findOne({ where: { id: appointmentId }, relations: ["patient"] });
        if (!a) throw new NotFoundException("Lịch khám không tồn tại");
        if (a.patient?.id !== patientId) throw new ForbiddenException("Không phải lịch của bạn");
        if (a.confirmCondition !== 2 || a.payable === null) throw new BadRequestException("Lịch chưa có hoá đơn");
        if (a.paymentStatus === "paid") throw new BadRequestException("Lịch đã được thanh toán");
        if (a.payable <= 0) throw new BadRequestException("Không cần thanh toán");

        let qr: Record<string, unknown> | undefined;
        if (method === "qr") {
            const { bin, accountNo, name, accountName } = this.bank;
            if (!bin || !accountNo) throw new ServiceUnavailableException("Chưa cấu hình tài khoản nhận");
            const content = transferContent(a.id);
            qr = {
                payload: buildVietQr({ bin, accountNo, amount: a.payable, content }),
                bankName: name ?? bin,
                accountNo,
                accountName: accountName ?? "",
                amount: a.payable,
                content,
            };
        }
        await this.appointments.update({ id: a.id }, { paymentMethod: method, paymentStatus: "pending" });
        return { paymentStatus: "pending", method, payable: a.payable, qr };
    }

    // ---------- SePay webhook ----------

    /** `Authorization: Apikey <SEPAY_API_KEY>` — constant-time compare. */
    assertWebhookKey(header: string | undefined) {
        if (!this.sepayKey) throw new ServiceUnavailableException("Chưa cấu hình SEPAY_API_KEY");
        const expected = Buffer.from(`Apikey ${this.sepayKey}`);
        const got = Buffer.from(header ?? "");
        if (got.length !== expected.length || !timingSafeEqual(got, expected)) {
            throw new UnauthorizedException("Sai API key");
        }
    }

    /**
     * One incoming bank transfer. Idempotent on SePay's `id` (SePay retries up to 7 times).
     * Matching "DACN{id}" + exact amount → paid + "money received" notification; anything else → warning.
     */
    async handleWebhook(tx: SepayWebhookDTO) {
        if (tx.transferType !== "in") return { success: true };

        await this.appointments.manager
            .transaction(async (m) => {
                const id = Number(/DACN(\d+)/i.exec(tx.content)?.[1]);
                const a = id
                    ? await m.findOne(AppointmentEntity, { where: { id }, relations: ["patient", "doctor"] })
                    : null;
                const matched = !!a && a.paymentStatus !== "paid" && a.payable !== null && tx.transferAmount === a.payable;

                // unique sepayId → a retry throws here and the whole transaction is skipped
                await m.insert(PaymentTransactionEntity, {
                    sepayId: String(tx.id),
                    appointment: a ? { id: a.id } : null,
                    amount: tx.transferAmount,
                    content: tx.content,
                    matched,
                });

                if (matched) {
                    await m.update(AppointmentEntity, { id: a.id }, {
                        paymentStatus: "paid", paymentMethod: "qr", paidAt: new Date(), paidBy: null,
                    });
                    await m.insert(NotificationEntity, {
                        title: `Đã nhận ${vnd(tx.transferAmount)}`,
                        body: `Bệnh nhân ${a.patient.name} đã chuyển khoản ${vnd(tx.transferAmount)} cho lịch #${a.id}, khám bởi BS. ${a.doctor.name}. Nội dung CK: "${tx.content}".`,
                        appointmentId: a.id,
                    });
                } else {
                    await m.insert(NotificationEntity, {
                        title: "⚠️ Giao dịch cần kiểm tra",
                        body: !a
                            ? `Nhận ${vnd(tx.transferAmount)} nhưng không tìm thấy lịch khám từ nội dung "${tx.content}".`
                            : a.paymentStatus === "paid"
                              ? `Nhận ${vnd(tx.transferAmount)} cho lịch #${a.id} (BN ${a.patient.name}) nhưng lịch đã được thanh toán trước đó.`
                              : `Nhận ${vnd(tx.transferAmount)} cho lịch #${a.id} (BN ${a.patient.name}, BS. ${a.doctor.name}) nhưng cần thu ${vnd(a.payable ?? 0)}. Chưa đánh dấu đã thanh toán.`,
                        appointmentId: a?.id ?? null,
                    });
                }
            })
            .catch((e: unknown) => {
                if (e instanceof QueryFailedError && (e as QueryFailedError<Error & { code?: string }>).driverError?.code === "23505") return; // duplicate retry
                throw e;
            });
        return { success: true };
    }

    // ---------- admin ----------

    listPayments(status: "pending" | "paid") {
        return this.appointments.find({
            where: { paymentStatus: status, cancelReason: IsNull() },
            relations: ["patient", "doctor"],
            order: status === "paid" ? { paidAt: "DESC" } : { apTime: "DESC" },
            take: 100,
        });
    }

    /** Admin marks a pending bill paid (cash at the counter, or a transfer handled by hand). */
    async confirm(adminAccountId: number, appointmentId: number) {
        const a = await this.appointments.findOne({ where: { id: appointmentId } });
        if (!a) throw new NotFoundException("Lịch khám không tồn tại");
        if (a.paymentStatus !== "pending") throw new BadRequestException("Lịch không ở trạng thái chờ xác nhận");
        await this.appointments.update({ id: a.id }, { paymentStatus: "paid", paidAt: new Date(), paidBy: adminAccountId });
        return { id: a.id, paymentStatus: "paid" };
    }

    listNotifications() {
        return this.notifications.find({ order: { createdAt: "DESC", id: "DESC" }, take: 100 });
    }

    async unreadCount() {
        return { count: await this.notifications.count({ where: { readAt: IsNull() } }) };
    }

    async readAll() {
        await this.notifications.update({ readAt: IsNull() }, { readAt: new Date() });
        return { ok: true };
    }
}
