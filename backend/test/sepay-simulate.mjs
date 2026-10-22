// Giả lập SePay báo tiền về cho một lịch đang chờ thanh toán (không cần chuyển tiền thật).
//   node test/sepay-simulate.mjs <appointmentId> [baseUrl] [amount]
// baseUrl mặc định http://localhost:3000; truyền URL ngrok để đi đúng đường SePay gọi.
// amount mặc định = đúng số tiền cần thu; truyền số khác để thử trường hợp lệch tiền.
import "dotenv/config"; // SEPAY_API_KEY, PAYMENT_ACCOUNT_NO từ backend/.env (chạy trong backend/)

const [id, base = "http://localhost:3000", amountArg] = process.argv.slice(2);
if (!id) {
  console.log("Cách dùng: node test/sepay-simulate.mjs <appointmentId> [baseUrl] [amount]");
  process.exit(1);
}
const call = (path, { token, body, headers = {} } = {}) =>
  fetch(base + path, {
    method: body ? "POST" : "GET",
    headers: { "content-type": "application/json", "ngrok-skip-browser-warning": "true",
      ...(token && { Authorization: `Bearer ${token}` }), ...headers },
    body: body && JSON.stringify(body),
  }).then(async (r) => ({ status: r.status, data: await r.json() }));

// Admin seed (dev) để đọc số tiền cần thu của lịch.
const { data: login } = await call("/auth/login", { body: { email: "admin@dacn.local", password: "Admin@123" } });
const { data: pending } = await call("/admin/payments?status=pending", { token: login.accessToken });
const appt = pending.find((a) => a.id === Number(id));
if (!appt) {
  console.log(`Lịch #${id} không ở trạng thái chờ thanh toán (bệnh nhân phải bấm Thanh toán → QR trước).`);
  process.exit(1);
}
const amount = Number(amountArg ?? appt.payable);
const hook = await call("/payments/sepay-webhook", {
  headers: { Authorization: `Apikey ${process.env.SEPAY_API_KEY}` },
  body: {
    id: Date.now(), // mỗi giao dịch một id, trùng id thì backend bỏ qua
    gateway: process.env.PAYMENT_BANK_NAME ?? "VietinBank",
    transactionDate: new Date().toISOString().slice(0, 19).replace("T", " "),
    accountNumber: process.env.PAYMENT_ACCOUNT_NO ?? "",
    transferType: "in",
    transferAmount: amount,
    content: `SIMULATE DACN${id}`,
    referenceCode: "SIMULATE",
  },
});
console.log(`Webhook ${amount} đ cho lịch #${id} (cần ${appt.payable} đ) → ${hook.status}`, hook.data);
