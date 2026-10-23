// End-to-end API smoke test for all 3 roles against a RUNNING backend (:3000) + AI service (:8000).
// Creates uitest_* accounts/shifts/appointments in the dev DB on every run.
//   cd backend && node test/api-smoke.mjs
import { readFileSync } from "node:fs";
import pg from "pg";
import "dotenv/config"; // SEPAY_API_KEY / PAYMENT_* from backend/.env (run from backend/)

const B = "http://localhost:3000";
const run = Date.now();
// unique 12-digit CCCD per registration in this run ("9" prefix never collides with the seeded registry)
let cccdSeq = 0;
const newCccd = () => `9${String(run).slice(-8)}${String(cccdSeq++).padStart(3, "0")}`;
let pass = 0, fail = 0;
const results = [];
process.on("uncaughtException", (e) => { console.log(results.join("\n")); console.log("CRASH", e.message); process.exit(1); });

async function call(method, path, { token, body, form } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload;
  if (form) payload = form;
  else if (body !== undefined) { headers["content-type"] = "application/json"; payload = JSON.stringify(body); }
  const r = await fetch(B + path, { method, headers, body: payload });
  const ct = r.headers.get("content-type") || "";
  const data = ct.includes("json") ? await r.json() : ct.includes("pdf") ? Buffer.from(await r.arrayBuffer()) : await r.text();
  return { status: r.status, data, ct };
}

function check(name, cond, extra = "") {
  cond ? pass++ : fail++;
  results.push(`${cond ? "PASS" : "FAIL"}  ${name}${extra ? "  — " + extra : ""}`);
}
// multipart body: plain fields + optional file {field, buf, type, name}
const formOf = (fields, file) => {
  const f = new FormData();
  for (const [k, v] of Object.entries(fields)) f.append(k, String(v));
  if (file) f.append(file.field, new Blob([file.buf], { type: file.type }), file.name);
  return f;
};
const ok = (r) => r.status >= 200 && r.status < 300;
const msg = (r) => `${r.status} ${typeof r.data === "object" && !Buffer.isBuffer(r.data) ? JSON.stringify(r.data).slice(0, 160) : ""}`;

// date helpers (server TZ = Asia/Ho_Chi_Minh, +07:00)
const day = (n) => { const d = new Date(Date.now() + n * 864e5); return d.toISOString().slice(0, 10); };

// ---------- auth ----------
const admin = await call("POST", "/auth/login", { body: { email: "admin@dacn.local", password: "Admin@123" } });
check("Admin đăng nhập", ok(admin), msg(admin));
const A = admin.data.accessToken;

const bad = await call("POST", "/auth/login", { body: { email: "admin@dacn.local", password: "sai" } });
check("Sai mật khẩu bị từ chối", bad.status === 401, msg(bad));

const noTok = await call("GET", "/patient/me");
check("Không có token bị chặn (401)", noTok.status === 401, msg(noTok));

const docEmail = `uitest_doctor_${run}@dacn.local`, patEmail = `uitest_patient_${run}@dacn.local`;
const img = readFileSync(new URL("../../AI/input_images/Acne_vulgaris_on_a_very_oily_skin.jpg", import.meta.url));
const avatarFile = { field: "avatar", buf: img.subarray(0, Math.min(img.length, 1.5e6)), type: "image/jpeg", name: "a.jpg" };
const docFields = { email: docEmail, password: "Test@123", name: "UI Test Doctor", gender: "Nam", age: 40,
  dateOfBirth: "1986-01-01", phone: "0900000001", address: "Huế" };
const regDocNoImg = await call("POST", "/auth/register-doctor", { token: A, form: formOf(docFields) });
check("Tạo bác sĩ không có ảnh bị từ chối (400)", regDocNoImg.status === 400, msg(regDocNoImg));
const regDoc = await call("POST", "/auth/register-doctor", { token: A, form: formOf(docFields, avatarFile) });
check("Admin tạo bác sĩ (kèm ảnh)", ok(regDoc), msg(regDoc));

const regPat = await call("POST", "/auth/register", { body: {
  email: patEmail, password: "Test@123", name: "UI Test Patient", age: 22, birthDate: "2004-05-05",
  gender: "Nữ", phone: "0900000002", address: "Đà Nẵng", cccd: newCccd() } });
check("Bệnh nhân tự đăng ký", ok(regPat), msg(regPat));

const dupPat = await call("POST", "/auth/register", { body: {
  email: patEmail, password: "Test@123", name: "x", age: 22, birthDate: "2004-05-05",
  gender: "Nữ", phone: "0900000002", address: "x", cccd: newCccd() } });
check("Đăng ký trùng email bị từ chối", !ok(dupPat), msg(dupPat));

// ---------- avatar ----------
const { readdirSync } = await import("node:fs");
const avatarDir = new URL("../uploads/avatars/", import.meta.url);
const nAvatars = () => readdirSync(avatarDir).length;
check("Đăng ký không ảnh → avatarUrl null", ok(regPat) && regPat.data.avatarUrl === null, msg(regPat));
const patImgEmail = `uitest_patimg_${run}@dacn.local`;
const patImgFields = { email: patImgEmail, password: "Test@123", name: "UI Img Patient", age: 22,
  birthDate: "2004-05-05", gender: "Nữ", phone: "0900000009", address: "Huế", cccd: newCccd() };
const regImg = await call("POST", "/auth/register", { form: formOf(patImgFields, avatarFile) });
check("Đăng ký kèm ảnh → có avatarUrl", ok(regImg) && regImg.data.avatarUrl?.startsWith("/uploads/avatars/"), msg(regImg));
const getImg = await fetch(B + regImg.data.avatarUrl);
check("Tải được ảnh avatar (không cần token)", getImg.status === 200, String(getImg.status));
const loginImg = await call("POST", "/auth/login", { body: { email: patImgEmail, password: "Test@123" } });
check("Login trả name + avatarUrl", loginImg.data.name === "UI Img Patient" && loginImg.data.avatarUrl === regImg.data.avatarUrl, msg(loginImg));
let before = nAvatars();
const dupImg = await call("POST", "/auth/register", { form: formOf(patImgFields, avatarFile) });
check("Email trùng kèm ảnh → 409, không để file rác", dupImg.status === 409 && nAvatars() === before, `${msg(dupImg)} files ${before}->${nAvatars()}`);
before = nAvatars();
const badDto = await call("POST", "/auth/register", { form: formOf({ ...patImgFields, email: "not-an-email" }, avatarFile) });
check("DTO sai kèm ảnh → 400, không để file rác", badDto.status === 400 && nAvatars() === before, `${msg(badDto)} files ${before}->${nAvatars()}`);
const pdfAvatar = await call("POST", "/auth/register", { form: formOf({ ...patImgFields, email: `x${run}@dacn.local` }, { field: "avatar", buf: Buffer.from("%PDF-1.4"), type: "application/pdf", name: "a.pdf" }) });
check("Avatar là PDF → 400", pdfAvatar.status === 400, msg(pdfAvatar));
const bigAvatar = await call("POST", "/auth/register", { form: formOf({ ...patImgFields, email: `y${run}@dacn.local` }, { ...avatarFile, buf: Buffer.alloc(2.5e6) }) });
check("Avatar > 2MB → 4xx", bigAvatar.status >= 400 && bigAvatar.status < 500, msg(bigAvatar));

const D = (await call("POST", "/auth/login", { body: { email: docEmail, password: "Test@123" } })).data.accessToken;
const P = (await call("POST", "/auth/login", { body: { email: patEmail, password: "Test@123" } })).data.accessToken;
check("Bác sĩ + bệnh nhân đăng nhập", !!D && !!P);

const patAsAdmin = await call("GET", "/admin/doctor-salaries", { token: P });
check("Bệnh nhân gọi API admin bị chặn (403)", patAsAdmin.status === 403, msg(patAsAdmin));

// ---------- patient profile ----------
const me = await call("GET", "/patient/me", { token: P });
check("Bệnh nhân xem hồ sơ", ok(me), msg(me));
const upd = await call("PUT", "/patient/me", { token: P, body: { address: "Đà Nẵng (đã sửa)" } });
check("Bệnh nhân sửa hồ sơ", ok(upd), msg(upd));

// ---------- doctor shifts ----------
const tpl = await call("GET", "/doctor/shift-templates", { token: D });
check("Bác sĩ xem mẫu ca", ok(tpl) && tpl.data.length >= 1, msg(tpl));
const morning = tpl.data[0];
const reg1 = await call("POST", "/doctor/register-shift", { token: D, body: { shiftId: morning.id, date: day(2) } });
check("Bác sĩ đăng ký ca (ngày +2)", ok(reg1), msg(reg1));
const reg2 = await call("POST", "/doctor/register-shift", { token: D, body: { shiftId: morning.id, date: day(3) } });
check("Bác sĩ đăng ký ca (ngày +3)", ok(reg2), msg(reg2));
const regDup = await call("POST", "/doctor/register-shift", { token: D, body: { shiftId: morning.id, date: day(2) } });
check("Đăng ký trùng ca bị từ chối", !ok(regDup), msg(regDup));
const regPast = await call("POST", "/doctor/register-shift", { token: D, body: { shiftId: morning.id, date: day(-2) } });
check("Đăng ký ca ngày quá khứ bị từ chối", !ok(regPast), msg(regPast));
const reg3 = await call("POST", "/doctor/register-shift", { token: D, body: { shiftId: tpl.data[tpl.data.length - 1].id, date: day(4) } });
const myShifts = await call("GET", "/doctor/my-shifts", { token: D });
check("Bác sĩ xem ca của mình", ok(myShifts) && myShifts.data.length >= 3, msg(myShifts));
const toCancel = (myShifts.data.find?.((s) => JSON.stringify(s).includes(day(4))) || {});
const cAssign = await call("POST", `/doctor/cancel-assignment/${toCancel.id}`, { token: D });
check("Bác sĩ hủy ca (ngày +4)", ok(cAssign), msg(cAssign) + ` id=${toCancel.id}`);
const overview = await call("GET", "/doctor/shift-overview", { token: D });
check("Xem tổng quan ca", ok(overview), msg(overview));

// ---------- booking ----------
const docs = await call("GET", "/doctor/list", { token: P });
const myDoc = docs.data.find((d) => d.email === docEmail);
check("Bệnh nhân thấy danh sách bác sĩ", ok(docs) && !!myDoc, msg(docs));
check("Danh sách bác sĩ có avatar", myDoc?.avatar?.startsWith("/uploads/avatars/"), JSON.stringify(myDoc?.avatar));
const av = await call("GET", `/doctor/availability?doctorId=${myDoc.id}&date=${day(2)}`, { token: P });
check("Xem khung giờ trống", ok(av) && av.data.length > 0, `${av.status} slots=${av.data.length}`);
const slots = av.data;

const book = async (i, note) => call("POST", "/patient/create-appointment", { token: P, body: {
  apTime: slots[i], address: "Phòng khám 1", doctorId: myDoc.id, note } });
const b1 = await book(0, "Đau đầu");
check("Đặt lịch #1", ok(b1), msg(b1));
const b2 = await book(1, "Ho");
check("Đặt lịch #2", ok(b2), msg(b2));
const b3 = await book(2, "Ngứa da");
check("Đặt lịch #3", ok(b3), msg(b3));
const bDup = await book(0, "trùng giờ");
check("Đặt trùng khung giờ bị từ chối", !ok(bDup), msg(bDup));
const bOff = await call("POST", "/patient/create-appointment", { token: P, body: {
  apTime: `${day(5)}T09:00:00+07:00`, address: "x", doctorId: myDoc.id } });
check("Đặt giờ ngoài ca trực bị từ chối", !ok(bOff), msg(bOff));

const list = await call("GET", "/patient/list-appointment", { token: P });
check("Bệnh nhân xem danh sách lịch", ok(list) && list.data.length === 3, `${list.status} n=${list.data.length}`);
const [a1, a2, a3] = [b1.data.id, b2.data.id, b3.data.id];
const det = await call("GET", `/patient/appointment/${a1}`, { token: P });
check("Bệnh nhân xem chi tiết lịch", ok(det), msg(det));

// patient reschedule once
const av2 = await call("GET", `/doctor/availability?doctorId=${myDoc.id}&date=${day(3)}`, { token: P });
const rs1 = await call("PUT", `/patient/reschedule-appointment/${a2}`, { token: P, body: { apTime: av2.data[0] } });
check("Bệnh nhân dời lịch #2 (lần 1)", ok(rs1), msg(rs1));
const rs2 = await call("PUT", `/patient/reschedule-appointment/${a2}`, { token: P, body: { apTime: av2.data[1] } });
check("Dời lịch lần 2 bị từ chối", !ok(rs2), msg(rs2));

// AI
const fd = new FormData();
fd.append("image", new Blob([img], { type: "image/jpeg" }), "acne.jpg");
fd.append("symptoms", "Nổi mụn đỏ ở mặt, da nhờn, hơi đau");
fd.append("appointmentId", String(a3));
const t0 = Date.now();
const rep = await call("POST", "/ai/report", { token: P, form: fd });
check("Bệnh nhân gửi ảnh + triệu chứng → PDF", ok(rep) && rep.ct.includes("pdf"), `${rep.status} ${rep.ct} ${Buffer.isBuffer(rep.data) ? rep.data.length + "B" : JSON.stringify(rep.data).slice(0, 200)} ${Date.now() - t0}ms`);

// ---------- doctor appointment flow ----------
const pend = await call("GET", "/doctor/list-unAcpappointment", { token: D });
check("Bác sĩ xem lịch chờ", ok(pend) && pend.data.length === 3, `${pend.status} n=${pend.data.length}`);
const cf1 = await call("POST", `/doctor/confirm-appointment/${a1}`, { token: D, body: { note: "Nhớ nhịn ăn sáng", confirmDate: new Date().toISOString() } });
check("Bác sĩ xác nhận lịch #1", ok(cf1), msg(cf1));
const cf3 = await call("POST", `/doctor/confirm-appointment/${a3}`, { token: D, body: { note: "Mang theo đơn thuốc cũ", confirmDate: new Date().toISOString() } });
check("Bác sĩ xác nhận lịch #3", ok(cf3), msg(cf3));
const rj2 = await call("POST", `/doctor/cancel-appointment/${a2}`, { token: D, body: { reason: "Bác sĩ bận đột xuất" } });
check("Bác sĩ từ chối lịch #2 kèm lý do", ok(rj2), msg(rj2));
const conf = await call("GET", "/doctor/list-appointment", { token: D });
check("Bác sĩ xem lịch đã xác nhận", ok(conf) && conf.data.length === 2, `${conf.status} n=${conf.data.length}`);
const pdf = await call("GET", `/doctor/report/${a3}`, { token: D });
check("Bác sĩ tải báo cáo AI (PDF)", ok(pdf) && pdf.ct.includes("pdf"), `${pdf.status} ${pdf.ct}`);

const avD = await call("GET", `/doctor/availability?doctorId=${myDoc.id}&date=${day(3)}`, { token: D });
const drs = await call("PUT", `/doctor/reschedule-appointment/${a1}`, { token: D, body: { apTime: avD.data[avD.data.length - 1] } });
check("Bác sĩ dời lịch #1", ok(drs), msg(drs));
// price list (admin) — doctor picks diseases when sending the diagnosis
const dz1 = await call("POST", "/diseases", { token: A, body: { name: `Viêm da ${run}`, price: 50000 } });
const dz2 = await call("POST", "/diseases", { token: A, body: { name: `Xét nghiệm máu ${run}`, price: 100000 } });
check("Admin tạo bảng giá bệnh", dz1.status === 201 && dz2.status === 201, `${msg(dz1)} ${msg(dz2)}`);
const doneNoDz = await call("POST", `/doctor/complete/${a3}`, { token: D, body: { diseaseIds: [] } });
check("Hoàn thành không chọn bệnh → 400", doneNoDz.status === 400, msg(doneNoDz));
const done = await call("POST", `/doctor/complete/${a3}`, { token: D, body: { diseaseIds: [dz1.data.id] } });
check("Bác sĩ đánh dấu khám xong #3 (kèm bệnh)", ok(done), msg(done));
const comp = await call("GET", "/doctor/list-completed", { token: D });
check("Bác sĩ xem lịch đã khám", ok(comp) && comp.data.length === 1, `${comp.status} n=${comp.data.length}`);
const re = await call("POST", "/doctor/re-examination", { token: D, body: {
  patientId: me.data.id, apTime: avD.data[0], address: "Phòng khám 1", note: "Tái khám sau 1 tuần" } });
check("Bác sĩ tạo lịch tái khám", ok(re), msg(re));

// IDOR: another doctor's token must not act on this appointment
const otherDocEmail = `uitest_doctor2_${run}@dacn.local`;
await call("POST", "/auth/register-doctor", { token: A, form: formOf({
  email: otherDocEmail, password: "Test@123", name: "UI Test Doctor 2", gender: "Nữ", age: 35,
  dateOfBirth: "1991-01-01", phone: "0900000003", address: "Huế" }, avatarFile) });
const D2 = (await call("POST", "/auth/login", { body: { email: otherDocEmail, password: "Test@123" } })).data.accessToken;
const idor = await call("POST", `/doctor/cancel-appointment/${a1}`, { token: D2, body: { reason: "hack" } });
check("Bác sĩ khác không hủy được lịch người khác (IDOR)", !ok(idor), msg(idor));

// patient cancel
const pc = await call("POST", `/patient/cancel-appointment/${a1}`, { token: P, body: { reason: "Bận việc" } });
check("Bệnh nhân hủy lịch #1 kèm lý do", ok(pc), msg(pc));

// ---------- admin ----------
const sal = await call("GET", "/admin/doctor-salaries", { token: A });
const mine = sal.data.find?.((s) => s.doctorId === myDoc.id);
check("Admin xem lương bác sĩ", ok(sal) && !!mine, `${sal.status} ${JSON.stringify(mine)}`);
const dd = await call("GET", `/doctor/detail/${myDoc.id}`, { token: A });
check("Admin xem chi tiết bác sĩ", ok(dd), msg(dd));
const du = await call("PUT", `/doctor/update/${myDoc.id}`, { token: A, body: { phone: "0911111111" } });
check("Admin sửa thông tin bác sĩ", ok(du), msg(du));

// ---------- CCCD → BHYT + bảng giá + hoá đơn ----------
// The BHYT registry is read-only (no API) → insert this run's people directly, delete them at the end.
const db = new pg.Client({ host: process.env.DB_HOST ?? "localhost", port: Number(process.env.DB_PORT ?? 5432),
  user: process.env.DB_USER ?? "postgres", password: process.env.DB_PASSWORD ?? "123456", database: process.env.DB_NAME ?? "dacn_db" });
await db.connect();

// shift cap: D takes a place, 3 filler rows (no doctor) make it 4/4 → D2 is refused
const capReg = await call("POST", "/doctor/register-shift", { token: D, body: { shiftId: morning.id, date: day(80) } });
await db.query(`INSERT INTO "shiftAssignment" (type, "startTime", "endTime", status, duration, "shiftId")
  SELECT type, "startTime", "endTime", status, duration, "shiftId" FROM "shiftAssignment", generate_series(1, 3) WHERE id = $1`, [capReg.data.id]);
const capTpl = await call("GET", `/doctor/shift-templates?date=${day(80)}`, { token: D });
const capM = capTpl.data.find?.((t) => t.id === morning.id) ?? {};
check("Mẫu ca theo ngày có số người / tối đa", capM.registered === 4 && capM.capacity === 4, JSON.stringify(capM));
const capFull = await call("POST", "/doctor/register-shift", { token: D2, body: { shiftId: morning.id, date: day(80) } });
check("Ca đủ 4 bác sĩ → 409", capFull.status === 409, msg(capFull));
await db.query(`DELETE FROM "shiftAssignment" WHERE "doctorId" IS NULL AND "startTime" = (SELECT "startTime" FROM "shiftAssignment" WHERE id = $1)`, [capReg.data.id]);

const EXAM = 150000;
const bhyt = {}; // tag → {cccd, birthDate}
for (const [tag, level, from, to] of [["80", "4", "2026-01-01", "2030-12-31"], ["full", "1", "2026-01-01", "2030-12-31"],
                                      ["exp", "4", "2024-01-01", day(1)], ["dob", "4", "2026-01-01", "2030-12-31"]]) {
  const cccd = newCccd();
  bhyt[tag] = { cccd, birthDate: "1996-01-01" };
  await db.query(`INSERT INTO bhyt_registry ("cccd","cardNumber","fullName","birthDate","validFrom","validTo") VALUES ($1,$2,$3,$4,$5,$6)`,
    [cccd, `DN${level}${cccd}`, `BHYT ${tag}`, "1996-01-01", from, to]);
}
const regCccd = async (tag, cccd, birthDate = "1996-01-01") => {
  const email = `uitest_bhyt_${tag}_${run}@dacn.local`;
  const r = await call("POST", "/auth/register", { form: formOf({ email, password: "Test@123", name: `BHYT ${tag}`,
    age: 30, birthDate, gender: "Nữ", phone: "0900000010", address: "Huế", cccd }) });
  return { r, token: r.data?.accessToken };
};
const noCccd = await call("POST", "/auth/register", { body: { email: `uitest_nocccd_${run}@dacn.local`, password: "Test@123",
  name: "x", age: 30, birthDate: "1996-01-01", gender: "Nữ", phone: "0900000010", address: "x" } });
check("Đăng ký thiếu CCCD → 400", noCccd.status === 400, msg(noCccd));
const badCccd = await regCccd("badcccd", "07920300011a");
check("CCCD có chữ / sai độ dài → 400", badCccd.r.status === 400, msg(badCccd.r));
const p80 = await regCccd("80", bhyt["80"].cccd);
check("Đăng ký bằng CCCD có trong danh bạ", ok(p80.r), msg(p80.r));
const dupCccd = await regCccd("dup", bhyt["80"].cccd);
check("CCCD đã đăng ký → 409", dupCccd.r.status === 409, msg(dupCccd.r));
const me80 = await call("GET", "/patient/me", { token: p80.token });
check("Hồ sơ: CCCD đầy đủ (chính chủ) + insurance 80% còn hạn",
  me80.data.cccd === bhyt["80"].cccd && me80.data.insurance?.cardNumber === `DN4${bhyt["80"].cccd}` && me80.data.insurance.rate === 0.8 && me80.data.insurance.status === "valid",
  JSON.stringify({ cccd: me80.data.cccd, ins: me80.data.insurance }));
const pDob = await regCccd("dob", bhyt.dob.cccd, "1997-02-02");
const meDob = await call("GET", "/patient/me", { token: pDob.token });
check("Ngày sinh lệch danh bạ → insurance null", ok(pDob.r) && meDob.data.insurance === null, JSON.stringify(meDob.data.insurance));
const pNone = await regCccd("none", newCccd());
const meNone = await call("GET", "/patient/me", { token: pNone.token });
check("CCCD không có trong danh bạ → insurance null", meNone.data.insurance === null, JSON.stringify(meNone.data.insurance));
const pFull = await regCccd("full", bhyt.full.cccd);
const pExp = await regCccd("exp", bhyt.exp.cccd);
const oldPatch = await call("PATCH", "/patient/me/insurance", { token: p80.token, body: {} });
check("API khai thẻ cũ đã bỏ → 404", oldPatch.status === 404, msg(oldPatch));

const patDz = await call("POST", "/diseases", { token: P, body: { name: "x", price: 1 } });
check("Bệnh nhân tạo bệnh → 403", patDz.status === 403, msg(patDz));
const dupDz = await call("POST", "/diseases", { token: A, body: { name: `Viêm da ${run}`, price: 1 } });
check("Tên bệnh trùng → 409", dupDz.status === 409, msg(dupDz));
const dzSoi = await call("POST", "/diseases", { token: A, body: { name: `Soi da ${run}`, price: 80000, bhytCovered: false } });
check("Tạo dịch vụ không BHYT", dzSoi.status === 201 && dzSoi.data.bhytCovered === false, msg(dzSoi));
const dz3 = await call("POST", "/diseases", { token: A, body: { name: `Ngừng áp dụng ${run}`, price: 70000 } });
await call("PATCH", `/diseases/${dz3.data.id}`, { token: A, body: { active: false } });
const dzDoc = await call("GET", "/diseases", { token: D });
const dzAdm = await call("GET", "/diseases", { token: A });
check("Bác sĩ không thấy bệnh đã tắt, admin vẫn thấy; có examFee + examFeeBhytCovered",
  dzDoc.data.examFee === EXAM && dzDoc.data.examFeeBhytCovered === true && !dzDoc.data.items.some((d) => d.id === dz3.data.id) && dzAdm.data.items.some((d) => d.id === dz3.data.id),
  `doc=${dzDoc.data.items?.length} adm=${dzAdm.data.items?.length} fee=${dzDoc.data.examFee} cov=${dzDoc.data.examFeeBhytCovered}`);

// book + confirm one appointment per patient on day(3)
await call("POST", "/doctor/register-shift", { token: D, body: { shiftId: tpl.data[1].id, date: day(3) } }); // more free slots
const avBill = (await call("GET", `/doctor/availability?doctorId=${myDoc.id}&date=${day(3)}`, { token: D })).data;
let slotI = 0;
const bookConfirm = async (token, confirm = true) => {
  const b = await call("POST", "/patient/create-appointment", { token, body: { apTime: avBill[slotI++], address: "PK 1", doctorId: myDoc.id } });
  if (confirm) await call("POST", `/doctor/confirm-appointment/${b.data.id}`, { token: D, body: { note: "ok", confirmDate: new Date().toISOString() } });
  return b.data.id;
};
const ap80 = await bookConfirm(p80.token);
const docView = (await call("GET", `/doctor/appointment/${ap80}`, { token: D })).data;
check("Bác sĩ xem lịch không thấy CCCD bệnh nhân", docView.patient && !("cccd" in docView.patient), JSON.stringify(Object.keys(docView.patient ?? {})));
const apPending = await bookConfirm(p80.token, false);
const pendDone = await call("POST", `/doctor/complete/${apPending}`, { token: D, body: { diseaseIds: [dz1.data.id] } });
check("Hoàn thành lịch đang chờ → 400", pendDone.status === 400, msg(pendDone));
const apCancel = await bookConfirm(p80.token);
await call("POST", `/patient/cancel-appointment/${apCancel}`, { token: p80.token, body: { reason: "bận" } });
const cancDone = await call("POST", `/doctor/complete/${apCancel}`, { token: D, body: { diseaseIds: [dz1.data.id] } });
check("Hoàn thành lịch đã huỷ → 400", cancDone.status === 400, msg(cancDone));

const dupIds = await call("POST", `/doctor/complete/${ap80}`, { token: D, body: { diseaseIds: [dz1.data.id, dz1.data.id] } });
const ghost = await call("POST", `/doctor/complete/${ap80}`, { token: D, body: { diseaseIds: [999999] } });
const offDz = await call("POST", `/doctor/complete/${ap80}`, { token: D, body: { diseaseIds: [dz1.data.id, dz3.data.id] } });
const otherDoc = await call("POST", `/doctor/complete/${ap80}`, { token: D2, body: { diseaseIds: [dz1.data.id] } });
const still = await call("GET", `/patient/appointment/${ap80}`, { token: p80.token });
check("diseaseIds trùng/không tồn tại/đã tắt → 400, bác sĩ khác → 403, chưa ghi items",
  dupIds.status === 400 && ghost.status === 400 && offDz.status === 400 && otherDoc.status === 403 && still.data.items.length === 0 && still.data.payable === null,
  `${dupIds.status} ${ghost.status} ${offDz.status} ${otherDoc.status} items=${still.data.items?.length}`);

// spec example: exam 150k [BHYT] + Viêm da 50k [BHYT] + Soi da 80k [không] , 80% → total 280k, BHYT 160k, pay 120k
const bill80 = await call("POST", `/doctor/complete/${ap80}`, { token: D, body: { diseaseIds: [dz1.data.id, dzSoi.data.id] } });
const b = (await call("GET", `/patient/appointment/${ap80}`, { token: p80.token })).data;
check("Hoá đơn ví dụ spec: total 280k, BHYT 160k, trả 120k, cờ BHYT từng dòng, unpaid",
  ok(bill80) && b.examFee === EXAM && b.examFeeCovered === true && b.total === 280000 && b.insuranceRate === 0.8 && b.insuranceCovered === 160000 && b.payable === 120000
  && b.items.length === 2 && b.items.find((i) => i.name.startsWith("Soi da")).bhytCovered === false && b.insuranceCardNumber === `DN4${bhyt["80"].cccd}` && b.paymentStatus === "unpaid",
  JSON.stringify({ total: b.total, cov: b.insuranceCovered, pay: b.payable, card: b.insuranceCardNumber, st: b.paymentStatus }));
const again = await call("POST", `/doctor/complete/${ap80}`, { token: D, body: { diseaseIds: [dz1.data.id] } });
check("Không hoàn thành lại lần 2 (đã khám)", again.status === 400, msg(again));

const apFull = await bookConfirm(pFull.token);
await call("POST", `/doctor/complete/${apFull}`, { token: D, body: { diseaseIds: [dz1.data.id] } });
const bFull = (await call("GET", `/patient/appointment/${apFull}`, { token: pFull.token })).data;
check("Thẻ 100% + toàn bộ BHYT → payable 0, tự paid", bFull.payable === 0 && bFull.paymentStatus === "paid" && !!bFull.paidAt, JSON.stringify({ pay: bFull.payable, st: bFull.paymentStatus }));

const apExp = await bookConfirm(pExp.token);
await call("POST", `/doctor/complete/${apExp}`, { token: D, body: { diseaseIds: [dz1.data.id] } });
const bExp = (await call("GET", `/patient/appointment/${apExp}`, { token: pExp.token })).data;
check("Thẻ hết hạn trước ngày khám → BHYT 0, trả đủ", bExp.insuranceCovered === 0 && bExp.payable === 200000 && bExp.insuranceCardNumber === null, JSON.stringify({ cov: bExp.insuranceCovered, pay: bExp.payable }));

const apNone = await bookConfirm(pNone.token);
await call("POST", `/doctor/complete/${apNone}`, { token: D, body: { diseaseIds: [dz1.data.id] } });
const bNone = (await call("GET", `/patient/appointment/${apNone}`, { token: pNone.token })).data;
check("Không có BHYT → trả đủ", bNone.insuranceCovered === 0 && bNone.payable === 200000, JSON.stringify({ pay: bNone.payable }));

await call("PATCH", `/diseases/${dz1.data.id}`, { token: A, body: { price: 999000, bhytCovered: false } });
const after = (await call("GET", `/patient/appointment/${ap80}`, { token: p80.token })).data;
check("Đổi giá + cờ BHYT sau khi khám → hoá đơn cũ giữ nguyên",
  after.total === 280000 && after.items.find((i) => i.name.startsWith("Viêm da")).price === 50000 && after.items.find((i) => i.name.startsWith("Viêm da")).bhytCovered === true,
  JSON.stringify({ total: after.total }));
const docSeen = (await call("GET", `/doctor/appointment/${ap80}`, { token: D })).data;
check("Bác sĩ cũng thấy hoá đơn", docSeen.payable === 120000 && docSeen.items.length === 2, `pay=${docSeen.payable}`);

// ---------- thanh toán + VietQR + webhook SePay + thông báo ----------
const crc16 = (str) => { let c = 0xffff; for (const b of Buffer.from(str)) { c ^= b << 8; for (let i = 0; i < 8; i++) c = c & 0x8000 ? ((c << 1) ^ 0x1021) & 0xffff : (c << 1) & 0xffff; } return c.toString(16).toUpperCase().padStart(4, "0"); };
const payNotExamined = await call("POST", `/patient/appointment/${apPending}/pay`, { token: p80.token, body: { method: "cash" } });
const payOther = await call("POST", `/patient/appointment/${ap80}/pay`, { token: pNone.token, body: { method: "cash" } });
const payPaid = await call("POST", `/patient/appointment/${apFull}/pay`, { token: pFull.token, body: { method: "cash" } });
const payBadMethod = await call("POST", `/patient/appointment/${ap80}/pay`, { token: p80.token, body: { method: "card" } });
check("Thanh toán lịch chưa khám / người khác / đã paid / phương thức lạ → 400/403/400/400",
  payNotExamined.status === 400 && payOther.status === 403 && payPaid.status === 400 && payBadMethod.status === 400,
  `${payNotExamined.status} ${payOther.status} ${payPaid.status} ${payBadMethod.status}`);
const payCash = await call("POST", `/patient/appointment/${ap80}/pay`, { token: p80.token, body: { method: "cash" } });
check("Chọn tiền mặt → pending", ok(payCash) && payCash.data.paymentStatus === "pending" && payCash.data.method === "cash" && payCash.data.payable === 120000, msg(payCash));
const payQr = await call("POST", `/patient/appointment/${ap80}/pay`, { token: p80.token, body: { method: "qr" } });
const pl = payQr.data.qr?.payload ?? "";
check("Đổi sang QR → payload VietQR đúng BIN/STK/số tiền/nội dung + CRC hợp lệ",
  ok(payQr) && pl.includes(`0006${process.env.PAYMENT_BANK_BIN}`) && pl.includes(process.env.PAYMENT_ACCOUNT_NO) && pl.includes("5406120000")
  && pl.includes(`DACN${ap80}`) && pl.slice(-4) === crc16(pl.slice(0, -4)) && payQr.data.qr.content === `DACN${ap80}`,
  pl);

const hook = (body, key = process.env.SEPAY_API_KEY) => fetch(B + "/payments/sepay-webhook", { method: "POST",
  headers: { "content-type": "application/json", Authorization: `Apikey ${key}` }, body: JSON.stringify(body) })
  .then(async (r) => ({ status: r.status, data: await r.json() }));
const unread = async () => (await call("GET", "/admin/notifications/unread-count", { token: A })).data.count;
await call("POST", "/admin/notifications/read-all", { token: A });
const txBase = { gateway: "MBBank", transactionDate: "2026-10-04 10:00:00", accountNumber: process.env.PAYMENT_ACCOUNT_NO, transferType: "in", referenceCode: "FT1" };
const sid = (n) => Number(`${String(run).slice(-9)}${n}`);
const hookBadKey = await hook({ ...txBase, id: sid(1), transferAmount: 120000, content: `DACN${ap80}` }, "wrong");
check("Webhook sai API key → 401", hookBadKey.status === 401, JSON.stringify(hookBadKey));
const hookWrongAmt = await hook({ ...txBase, id: sid(2), transferAmount: 100000, content: `MBVCB.123 DACN${ap80} chuyen tien` });
const afterWrongAmt = (await call("GET", `/patient/appointment/${ap80}`, { token: p80.token })).data;
check("Webhook số tiền lệch → success, vẫn pending, có cảnh báo", hookWrongAmt.status === 200 && hookWrongAmt.data.success === true && afterWrongAmt.paymentStatus === "pending" && (await unread()) === 1,
  JSON.stringify({ hook: hookWrongAmt, st: afterWrongAmt.paymentStatus }));
const hookGood = await hook({ ...txBase, id: sid(3), transferAmount: 120000, content: `MBVCB.456 dacn${ap80} chuyen tien` });
const paidAppt = (await call("GET", `/patient/appointment/${ap80}`, { token: p80.token })).data;
const hookNotes = (await call("GET", "/admin/notifications", { token: A })).data;
const hookNote = hookNotes.find((n) => n.appointmentId === ap80 && n.title.startsWith("Đã nhận"));
check("Webhook đúng → paid (qr) + thông báo có tên BN, BS, số tiền",
  hookGood.data.success === true && paidAppt.paymentStatus === "paid" && paidAppt.paymentMethod === "qr" && !!paidAppt.paidAt
  && hookNote?.body.includes("BHYT 80") && hookNote.body.includes("UI Test Doctor") && hookNote.body.includes("120.000"),
  JSON.stringify({ st: paidAppt.paymentStatus, hookNote: hookNote?.body }));
const nBefore = hookNotes.length;
const hookRetry = await hook({ ...txBase, id: sid(3), transferAmount: 120000, content: `MBVCB.456 dacn${ap80} chuyen tien` });
const notesAfter = (await call("GET", "/admin/notifications", { token: A })).data;
check("SePay gửi lại cùng id → không tạo thêm thông báo", hookRetry.data.success === true && notesAfter.length === nBefore, `${nBefore}→${notesAfter.length}`);
const hookOut = await hook({ ...txBase, id: sid(4), transferType: "out", transferAmount: 5000, content: "phi" });
const hookUnknown = await hook({ ...txBase, id: sid(5), transferAmount: 5000, content: "ck linh tinh" });
check("Tiền ra bỏ qua; không rõ lịch → cảnh báo", hookOut.data.success === true && hookUnknown.data.success === true
  && (await call("GET", "/admin/notifications", { token: A })).data[0].title.includes("kiểm tra"), "");
const payAfterPaid = await call("POST", `/patient/appointment/${ap80}/pay`, { token: p80.token, body: { method: "cash" } });
check("Đã paid → không thanh toán lại (400)", payAfterPaid.status === 400, msg(payAfterPaid));

// cash confirmed by admin
await call("POST", `/patient/appointment/${apNone}/pay`, { token: pNone.token, body: { method: "cash" } });
const payPend = await call("GET", "/admin/payments?status=pending", { token: A });
check("Admin thấy lịch chờ xác nhận", ok(payPend) && payPend.data.some((x) => x.id === apNone && x.patient?.name === "BHYT none"), `n=${payPend.data.length}`);
const patAdmin = await call("POST", `/admin/payments/${apNone}/confirm`, { token: pNone.token });
check("Bệnh nhân gọi API admin → 403", patAdmin.status === 403, msg(patAdmin));
const payConf = await call("POST", `/admin/payments/${apNone}/confirm`, { token: A });
const payConf2 = await call("POST", `/admin/payments/${apNone}/confirm`, { token: A });
const nonePaid = (await call("GET", `/patient/appointment/${apNone}`, { token: pNone.token })).data;
check("Admin xác nhận tiền mặt → paid; xác nhận lại → 400", ok(payConf) && payConf2.status === 400 && nonePaid.paymentStatus === "paid" && nonePaid.paidBy !== null,
  `${payConf.status} ${payConf2.status} ${nonePaid.paymentStatus}`);
const paidList = await call("GET", "/admin/payments?status=paid", { token: A });
check("Danh sách đã thanh toán có cả QR và tiền mặt", [ap80, apNone].every((id) => paidList.data.some((x) => x.id === id)), `n=${paidList.data.length}`);
await call("POST", "/admin/notifications/read-all", { token: A });
check("read-all → unread 0", (await unread()) === 0, "");


// ---------- news ----------
const newsDir = new URL("../uploads/news/", import.meta.url);
const nNews = () => { try { return readdirSync(newsDir).length; } catch { return 0; } };
const newsImg = { ...avatarFile, field: "image" };
const newsFields = { title: `Tin smoke ${run}`, url: "https://suckhoedoisong.vn/bai-viet" };
const n1 = await call("POST", "/news", { token: A, form: formOf(newsFields, newsImg) });
check("Admin tạo tin tức (kèm ảnh)", n1.status === 201 && n1.data.imagePath?.startsWith("/uploads/news/"), msg(n1));
const nImg = await fetch(B + n1.data.imagePath);
check("Tải được ảnh tin tức", nImg.status === 200, String(nImg.status));
const nPat = await call("POST", "/news", { token: P, form: formOf(newsFields, newsImg) });
check("Bệnh nhân tạo tin → 403", nPat.status === 403, msg(nPat));
const nDoc = await call("POST", "/news", { token: D, form: formOf(newsFields, newsImg) });
check("Bác sĩ tạo tin → 403", nDoc.status === 403, msg(nDoc));
before = nNews();
const nJs = await call("POST", "/news", { token: A, form: formOf({ ...newsFields, url: "javascript:alert(1)" }, newsImg) });
check("URL javascript: → 400, không file rác", nJs.status === 400 && nNews() === before, `${msg(nJs)} files ${before}->${nNews()}`);
const nNoImg = await call("POST", "/news", { token: A, form: formOf(newsFields) });
check("Tin không ảnh → 400", nNoImg.status === 400, msg(nNoImg));
const nPdf = await call("POST", "/news", { token: A, form: formOf(newsFields, { field: "image", buf: Buffer.from("%PDF-1.4"), type: "application/pdf", name: "a.pdf" }) });
check("Ảnh tin là PDF → 400", nPdf.status === 400 && nNews() === before, msg(nPdf));
const nBig = await call("POST", "/news", { token: A, form: formOf(newsFields, { ...newsImg, buf: Buffer.alloc(2.5e6) }) });
check("Ảnh tin > 2MB → 4xx, không file rác", nBig.status >= 400 && nBig.status < 500 && nNews() === before, `${msg(nBig)} files ${before}->${nNews()}`);
const n2 = await call("POST", "/news", { token: A, form: formOf({ ...newsFields, title: `Tin mới hơn ${run}` }, newsImg) });
const nList = await call("GET", "/news?limit=5", { token: P });
check("Bệnh nhân xem tin, ≤5, mới nhất đầu", ok(nList) && nList.data.length <= 5 && nList.data[0].id === n2.data.id, `${nList.status} n=${nList.data.length}`);
const nNoTok = await call("GET", "/news");
check("Xem tin không token → 401", nNoTok.status === 401, msg(nNoTok));
const nDelPat = await call("DELETE", `/news/${n1.data.id}`, { token: P });
check("Bệnh nhân xoá tin → 403", nDelPat.status === 403, msg(nDelPat));
const nDel = await call("DELETE", `/news/${n1.data.id}`, { token: A });
const gone = await fetch(B + n1.data.imagePath);
check("Admin xoá tin → file ảnh bị xoá", ok(nDel) && gone.status === 404, `${nDel.status} img=${gone.status}`);
await call("DELETE", `/news/${n2.data.id}`, { token: A });

// keep the shared price list clean: this run's test diseases (bills keep name/price snapshots, no FK)
await db.query(`DELETE FROM disease WHERE name LIKE $1`, [`% ${run}`]);
await db.query(`DELETE FROM bhyt_registry WHERE "fullName" LIKE 'BHYT %' AND cccd LIKE $1`, [`9${String(run).slice(-8)}%`]);
// free this run's places on future shifts (max 4 doctors/shift), else repeated runs fill them up
await db.query(`UPDATE "shiftAssignment" SET status = 'CANCELED' WHERE "doctorId" = $1 AND status = 'ACTIVE'`, [myDoc.id]);
await db.end();

console.log(results.join("\n"));
console.log(`\n${pass} passed, ${fail} failed`);
console.log(`ACCOUNTS: doctor=${docEmail} patient=${patEmail} pw=Test@123`);
process.exit(fail ? 1 : 0);
