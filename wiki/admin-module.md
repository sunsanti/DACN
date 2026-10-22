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
- `AdminHomeScreen` (spec 05): bottom `NavigationBar` with 4 tabs in an `IndexedStack` — Bác sĩ & lương · `AdminPaymentsScreen` (sub-tabs Chờ xác nhận / Đã thanh toán, "Đã nhận tiền") · `AdminDiseaseScreen` · `AdminNewsScreen`. The 3 sub-screens have no AppBar of their own (only used as tabs). AppBar = title of the current tab, bell → `AdminNotificationsScreen` (marks read), separate Đăng xuất button. Unread count (polled every 15 s, refreshed on tab change / return) shows as a badge on the bell **and** on the Thanh toán tab, `99+` cap. No `NavigationRail`: `main.dart` caps the app at 560 px so a wide layout never triggers.
- Routed when the logged-in account role is `admin` ([[ui-components]]).

## Not yet

- Manage/lock patient accounts; edit/delete doctors.
- Shift-management UI (backend shift APIs exist; doctor shift add currently needs the
  `duration` NOT NULL fix — see [[known-issues]]).

Related: [[auth-flow]] · [[doctor-module]] · [[api-routes]] · [[project-architecture]]
