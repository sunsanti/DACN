---
last_updated: 2026-10-04
tags: [admin, module]
---

# Admin Module

**Status: IMPLEMENTED (A01/A02).** `backend/src/admin/` is wired in `app.module.ts` and
gated `@Roles('admin')`. Admin can add doctors and view each doctor's worked hours + salary.

## Backend (`backend/src/admin/`)

- `GET /admin/doctor-salaries` — per-doctor `{ doctorId, name, totalHours, hourlyRate, salary }`.
  Hours summed from `shiftAssignment` start/end times (robust vs. the legacy `duration` field);
  `salary = hours × ADMIN_HOURLY_RATE` (env, default `100000`).
- Doctor creation reuses `POST /auth/register-doctor` (admin-only, avatar required) — see [[auth-flow]].
- Salary rows include the doctor's `avatar`.
- Price list: `/diseases` CRUD (no delete) incl. `bhytCovered` — see [[api-routes]]. News: `/news` create/delete.
- Payments: `/admin/payments` (pending / paid) + confirm cash; notifications inbox fed by the SePay webhook (`payment/`). Admins **cannot** register or edit BHYT (registry is read-only).

## Frontend

- `AdminHomeScreen`: list of doctors with hours + salary (VND formatted).
- `AddDoctorScreen`: form + required avatar picker → creates a doctor account.
- `AdminNewsScreen` (AppBar newspaper icon): list / add (title, link, cover image) / delete with confirm.
- `AdminDiseaseScreen`: fixed exam fee (+ BHYT status) + price list, add/edit price and "BHYT chi trả", on/off switch.
- AppBar = bell with unread badge (polled every 15 s) → `AdminNotificationsScreen` (marks read), and a menu → `AdminPaymentsScreen` (tabs Chờ xác nhận / Đã thanh toán, "Đã nhận tiền"), Bảng giá, Tin tức, Đăng xuất.
- Routed when the logged-in account role is `admin` ([[ui-components]]).

## Not yet

- Manage/lock patient accounts; edit/delete doctors.
- Shift-management UI (backend shift APIs exist; doctor shift add currently needs the
  `duration` NOT NULL fix — see [[known-issues]]).

Related: [[auth-flow]] · [[doctor-module]] · [[api-routes]] · [[project-architecture]]
