---
last_updated: 2026-10-04
tags: [doctor, shift, appointment, module]
---

# Doctor Module

`backend/src/doctor/` — fully implemented. Two concerns: (1) doctors managing patient appointments (confirm / reschedule / mark-examined / re-examination / delete + AI report download), and (2) a **real-dated shift system** powering availability + salary. All doctor routes are `@Roles('doctor')` and scope by `doctorId` from the JWT; ownership enforced via `assertOwns` / `assertOwnsAssignment`. See [[api-routes]] for the full route list.

## Appointment operations

`confirmCondition`: **1=pending, 0=confirmed, 2=examined**.

- `listUnacceptedAppointment` / `listAcceptedAppointment` / `listCompletedAppointment` — by status, filtered to this doctor, with `patient` relation.
- `getAppointmentDetail` — detail + patient info.
- `confirmAppointment` → 0; `reAppointment` reschedules.
- `completeAppointment(doctorId, id, diseaseIds)` — the "send diagnosis" step: only a confirmed, non-canceled appointment; all `diseaseIds` must exist and be active; bill = `EXAM_FEE` (env, default 150000, via `DiseaseService.examFee`) + Σ disease prices; BHYT = `round(coveredBase × rate)` where `coveredBase` = exam fee (if `EXAM_FEE_BHYT_COVERED`) + lines with `bhytCovered`, and the card comes from `BhytService.findCard(patient.cccd, birthDate)` and must be valid on `apTime`. `payable 0` → `paymentStatus = paid`. Writes `confirmCondition=2` + totals + `appointment_item` rows in **one transaction**. `DoctorModule` imports `DiseaseModule`.
- `reExamination(doctorId, patientId, apTime, address, note)` — creates a NEW confirmed appointment for a patient (follow-up).
- `deleteAppointment` — ownership-checked.
- `getReport(appointmentId)` — returns the stored AI PDF bytes.

## Shift system (real date + time)

`ShiftEntity` = time-of-day templates (morning 06–12, afternoon 12–20, seeded by migration). `ShiftAssignmentEntity` = a doctor working a real-dated window with `status` (ACTIVE / CANCELED) + `duration` (double precision hours).

- `registerShift(doctorId, shiftId, dateStr)` — template gives the time-of-day, `dateStr` the day → real `startTime`/`endTime`, duration = full hours.
- `myShifts` / `shiftOverview` (all doctors) — list assignments.
- `cancelAssignment` — `status=CANCELED`, `duration = clamp(now,start,end) − start` (**pays hours actually worked**).
- `deleteAssignment` — remove.
- `availability(doctorId, dateStr)` — free **30-min slots** = that doctor's ACTIVE shift windows on the date, minus already-booked appointment times. Open to any authenticated user (patients book against it).

## Admin-facing (in this controller)

- `GET /doctor/list` (any authenticated — patient booking dropdown, includes `avatar`), `GET /doctor/detail/:id`, `PUT /doctor/update/:id` (admin).
- `POST /doctor/create-doctor` was **removed** (2026-10-04): it let any logged-in user create a hard-coded doctor. Doctors are created only via `POST /auth/register-doctor`.

## Legacy (superseded, see [[known-issues]])

`addShift`/`cancel-shift`/`delete-shift/:doctorId/...`/`list-shift/:id` + `ShiftDTO` — older shift API, kept but replaced by the clean shift endpoints above.

Related: [[patient-module]] · [[admin-module]] · [[api-routes]] · [[database-schema]] · [[auth-flow]]
