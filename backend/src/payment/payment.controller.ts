import { Body, Controller, Get, Headers, HttpCode, Param, ParseIntPipe, Post, Query } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { PaymentService } from "./payment.service";
import { PayDTO, SepayWebhookDTO } from "./payment.dto";
import { Public } from "../common/decorators/public.decorator";
import { Roles } from "../common/decorators/roles.decorator";
import { CurrentUser } from "../common/decorators/current-user.decorator";
import type { JwtPayload } from "../auth/jwt-payload.interface";

@ApiTags("payment")
@ApiBearerAuth()
@Controller()
export class PaymentController {
    constructor(private readonly paymentService: PaymentService) {}

    /** Patient chooses cash or VietQR for an examined appointment. */
    @Roles("patient")
    @Post("patient/appointment/:id/pay")
    pay(@CurrentUser() user: JwtPayload, @Param("id", ParseIntPipe) id: number, @Body() dto: PayDTO) {
        return this.paymentService.pay(user.patientId!, id, dto.method);
    }

    /** SePay → us when money arrives. Auth: `Authorization: Apikey <SEPAY_API_KEY>` (no JWT). */
    @Public()
    @Post("payments/sepay-webhook")
    @HttpCode(200)
    sepayWebhook(@Headers("authorization") auth: string | undefined, @Body() dto: SepayWebhookDTO) {
        this.paymentService.assertWebhookKey(auth);
        return this.paymentService.handleWebhook(dto);
    }

    @Roles("admin")
    @Get("admin/payments")
    payments(@Query("status") status?: string) {
        return this.paymentService.listPayments(status === "paid" ? "paid" : "pending");
    }

    @Roles("admin")
    @Post("admin/payments/:id/confirm")
    confirm(@CurrentUser() user: JwtPayload, @Param("id", ParseIntPipe) id: number) {
        return this.paymentService.confirm(user.sub, id);
    }

    @Roles("admin")
    @Get("admin/notifications")
    notifications() {
        return this.paymentService.listNotifications();
    }

    @Roles("admin")
    @Get("admin/notifications/unread-count")
    unreadCount() {
        return this.paymentService.unreadCount();
    }

    @Roles("admin")
    @Post("admin/notifications/read-all")
    readAll() {
        return this.paymentService.readAll();
    }
}
