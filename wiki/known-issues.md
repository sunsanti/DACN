---
last_updated: 2026-06-03
tags: [issues, tech-debt, todo]
---

# Known Issues & Tech Debt

Most of the 2026-06-02 issues have been resolved during the full build-out + harden phase. This now tracks what's **fixed** (history) and what **remains**.

## ✅ Fixed (2026-06-03)

- **Hardcoded DB credentials** → moved to `DB_*` env (`ConfigService` runtime + `dotenv` CLI), defaults kept for dev.
- **No authentication** → global `JwtAuthGuard` + `RolesGuard`, `@Public()` only on `/auth/*`. ([[auth-flow]])
- **Hardcoded handlers** → `setAppointment` reads the DTO; `listAppointment` uses `patientId` from JWT; `editAppointment` persists; `register*` create real records.
- **`cancelShift` duration formula bug** → shifts redesigned to real date+time; duration computed correctly (cancel pays worked hours).
- **Route typo** `confirm-appointmnet` → `POST /doctor/confirm-appointment/:id`.
- **`ParseIntPipe`** applied to `:id` params; date DTOs use `@Type(() => Date)`.
- **IDOR** → ownership checks (`assertOwns`) on patient & doctor appointment ops and `/ai/report`.
- **Admin module** implemented + registered; **Flutter** built out for all 3 roles.
- `shiftAssignment.duration` INTEGER → `double precision` (fractional hours).

## ⚠️ Remaining tech debt

- **`DoctorService.calculateTime()`** — empty stub (planned QR-based payment); not used.
- **Legacy shift endpoints** (`addShift`, `cancel-shift`, `delete-shift/:doctorId/...`, `list-shift/:id`, `ShiftDTO`) superseded by the clean shift API — candidates for removal.
- **DB config still duplicated** between `database.module.ts` and `data-source.ts` (now both read the same `DB_*` env, so low risk).
- **JWT default secret fallback** (`'dev-secret-change-me'`) if `JWT_SECRET` missing — fine for dev, set a real secret for any real deployment.
- **No refresh token / password reset** (out of scope per spec).
- **Doctor availability** assumes a doctor registers shifts; no recurring-schedule support (one shift per registration).

Related: [[project-architecture]] · [[doctor-module]] · [[auth-flow]] · [[critical-constraints]]
