---
last_updated: 2026-10-04
tags: [patient, appointment, module]
---

# Patient Module

`backend/src/patient/` — fully implemented. Patient profile + appointment booking, all `@Roles('patient')` and scoped by `patientId` from the JWT, with ownership checks (`assertOwns`). See [[api-routes]].

## Structure

- `patient.controller.ts` / `patient.service.ts` (implements `IPatientService`)
- `entities/` — `patient.entity.ts`, `appointment.entity.ts`, `medical_report.entity.ts` ([[database-schema]])
- `dto/` — `create_appointment`, `update_appointment`, `update_patient`, `patient`, `appointment`
- Account/login lives in [[auth-flow]] (registration creates the patient + account).

## Behavior

| Method | Notes |
| --- | --- |
| `getProfile` / `updateProfile` | `GET/PUT /patient/me` — own profile |
| `setAppointment(patientId, dto)` | reads the real DTO (apTime/address/doctorId/note); `confirmCondition=1`; validates doctor exists |
| `listAppointment(patientId)` | own appointments (doctor relation), newest first |
| `getAppointment` | detail (ownership) |
| `editAppointment(patientId, id, dto)` | real partial update (apTime/address/note), ownership |
| `deleteAppointment(patientId, id)` | ownership-checked |

## Booking flow (with availability)

The Flutter booking screen calls `GET /doctor/availability?doctorId=&date=` ([[doctor-module]]) and only shows free **30-min slots** from the doctor's registered shifts. The selected slot's ISO time becomes `apTime`.

## CCCD → BHYT + bill + payment (2026-10-04)

- CCCD is required at registration and read-only afterwards. `getProfile` adds `cccd` (owner) and `insurance` via `BhytService.findCard(cccd, birthDate)` (`billing/bhyt.service.ts`); `null` → the app hides the "Mã BHYT" field. The old self-declared card (`PATCH /patient/me/insurance`) was removed.
- Benefit level = 3rd char of the code: `1,2,5` → 100%, `3` → 95%, `4` → 80% (no đúng/trái tuyến distinction). Only BHYT-covered lines (and the exam fee if covered) are reimbursed.
- Paying: `POST /patient/appointment/:id/pay` (`payment/`), cash or VietQR; the app polls the appointment every 3 s and shows the success animation once `paid`.
- The bill is written by the doctor at completion ([[doctor-module]]); `assertOwns` loads `items` so the patient sees it in the appointment detail.

## AI report

`POST /ai/report` (patient) persists a `medical_report` linked to the appointment; the appointment must belong to the caller (IDOR guard). The doctor downloads it via `GET /doctor/report/:appointmentId`. See [[ai-integration]].

Related: [[doctor-module]] · [[api-routes]] · [[database-schema]] · [[auth-flow]]
