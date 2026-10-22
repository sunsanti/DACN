---
last_updated: 2026-10-04
tags: [database, schema, typeorm]
---

# Database Schema

PostgreSQL database `dacn_db` accessed through TypeORM 0.3. **Seven** entities: patients, doctors, appointments, the shift-scheduling pair (`shift` + `shiftAssignment`), plus **`account`** (auth) and **`medical_report`** (AI PDFs). `synchronize` is **false** everywhere — schema changes go through migrations. DB connection reads `DB_*` from env (see [[critical-constraints]]).

## Auth & report tables (added 2026-06-03)

- **`account`** — `id`, `email` UNIQUE, `passwordHash` (bcrypt), `role` (`patient`/`doctor`/`admin`), `patientId?` FK, `doctorId?` FK (OneToOne, SET NULL), `createdAt`. Migration seeds one admin (`admin@dacn.local`). See [[auth-flow]].
- **`medical_report`** — `id`, `appointmentId` FK (CASCADE), `pdf` BYTEA, `createdAt`. Stores the AI report PDF. See [[ai-integration]].
- **`shiftAssignment.duration`** is now `double precision` (fractional hours).
- **`appointment.confirmCondition`**: `1`=pending, `0`=confirmed, **`2`=examined**.
- **`appointment`** review fields (2026-06-04): `doctorNote` (doctor's note, separate from patient `note`), `cancelReason` + `canceledBy` (`patient`/`doctor`) — if `cancelReason` set, the appointment is canceled (kept, not deleted; excluded from active lists; frees its slot), `rescheduled` boolean (one-time reschedule guard).

## Avatars, news, BHYT, billing (added 2026-10-04)

- **`patient.avatar`** (existing column, now used) / **`doctor.avatar`** `varchar NOT NULL DEFAULT ''` — server path `/uploads/avatars/<uuid>.<ext>`, `''` = none (migration `AddDoctorAvatar`).
- **`news`** — `id`, `title` varchar(200), `url` varchar(2000), `imagePath`, `createdAt` (migration `CreateNews`).
- **`patient`** BHYT card: `insuranceNumber` varchar(15), `insuranceValidFrom` date, `insuranceValidTo` date — all three set or all NULL.
- **`disease`** — admin price list: `id`, `name` varchar(200) UNIQUE, `price` int CHECK ≥ 0, `active` bool (no delete; switch off).
- **`appointment`** bill snapshot (NULL = no bill yet): `examFee`, `total`, `insuranceRate` real, `insuranceCovered`, `payable`.
- **`appointment_item`** — one row per disease on the bill: `appointmentId` FK (CASCADE), `name`, `price` (snapshot text/number, **no FK to `disease`**, so later price edits never change old bills).
- Migration `AddInsuranceAndPricing`. Bill math: `billing/billing.util.ts` (`calcBill`, unit-tested).
- `reset-db.ts` truncates `news` and `disease` too; files under `backend/uploads/` are not wiped.

## CCCD → BHYT, payment (added 2026-10-04, đợt 2 — migration `CccdBhytPayment`)

- **`patient.cccd`** varchar(12) UNIQUE NULL, `select: false` (never leaks through relations; only `/patient/me` reads it). The self-declared card columns (`insuranceNumber/ValidFrom/ValidTo`) were **dropped**.
- **`bhyt_registry`** — read-only stand-in for BHXH data: `cccd` UNIQUE, `cardNumber` UNIQUE, `fullName`, `birthDate`, `validFrom`, `validTo`. Seeded by the migration (5 people); **no API writes it**; `reset-db.ts` keeps it. A patient has BHYT iff a row exists for their CCCD **and** the birth date matches.
- **`disease.bhytCovered`**, **`appointment_item.bhytCovered`** (snapshot) — only covered lines are reimbursed.
- **`appointment`**: + `examFeeCovered`, `insuranceCardNumber` (snapshot), `paymentMethod` (`cash`/`qr`), `paymentStatus` (`unpaid` default / `pending` / `paid`), `paidAt`, `paidBy` (admin account; NULL = webhook/automatic).
- **`payment_transaction`** — every SePay webhook accepted: `sepayId` UNIQUE (retry dedup), `appointmentId?`, `amount`, `content`, `matched`, `createdAt`.
- **`notification`** — admin inbox: `title`, `body`, `appointmentId?`, `readAt?`, `createdAt`.
- **Timezone:** both DB configs set the session `timezone=Asia/Ho_Chi_Minh` (`extra.options`). The Postgres container runs in UTC; before this, `now()` defaults (`createdAt`) were stored 7h behind the wall clock Node uses for `timestamp` columns. Rows created before the fix keep the old offset.

## Connection

Defined twice (keep them in sync):

- `backend/src/database/database.module.ts` — runtime (`TypeOrmModule.forRoot`), `autoLoadEntities: true`, loads `**/*.entity.{ts,js}`
- `backend/src/data-source.ts` — standalone `DataSource` for the TypeORM CLI (`npm run typeorm`), explicit entity list, migrations glob `src/migrations/*.ts`

```
type: postgres   host: localhost   port: 5432
username: postgres   password: 123456   database: dacn_db
synchronize: false
```

> ⚠️ Credentials are hardcoded in source — see [[known-issues]].

## Entities

### `patient` — `PatientEntity`
`id` (PK), `name`, `gender`, `age`, `birthDate`, `email`, `phone`, `address`, `createAt`, `avatar`
- `OneToMany` → `appointments`

### `doctor` — `DoctorEntity`
`id` (PK), `name`, `age`, `dateOfBirth` (timestamp), `gender`, `phone`, `address`, `email`
- `OneToMany` → `appointments`
- `OneToMany` → `shiftAssignments`
- (a commented-out `ManyToMany` to `shift` was replaced by the `ShiftAssignment` join entity)

### `appointment` — `AppointmentEntity`
`id` (PK), `apTime` (date), `confirmDate` (timestamp, nullable), `address`, `note` (text, nullable), `confirmCondition` (number), `doctorName`
- `ManyToOne` → `patient`
- `ManyToOne` → `doctor`

**`confirmCondition` semantics (important):**
- `1` = pending / not yet confirmed by doctor
- `0` = confirmed
(See `DoctorService.listUnacceptedAppointment` → filters `confirmCondition: 1`; `confirmAppointment` sets it to `0`.)

### `shift` — `ShiftEntity`
`id` (PK), `type` (`'morning' | 'afternoon'`), `startTime` (timestamp), `endTime` (timestamp)
- `OneToMany` → `shiftAssignments`
- (`emergency` column was dropped in the migration)

### `shiftAssignment` — `ShiftAssignmentEntity` (join + state)
`id` (PK), `type` (string), `startTime`, `endTime`, `status` (`'ACTIVE' | 'CANCELED' | 'REPLACED'`), `duration` (number)
- `ManyToOne` → `doctor`
- `ManyToOne` → `shift`

This is the heart of shift scheduling: each row is one doctor working one shift, with a lifecycle status. Cancelling sets `status = CANCELED` and computes `duration`.

## Relationships

```
PatientEntity 1───* AppointmentEntity *───1 DoctorEntity
DoctorEntity  1───* ShiftAssignmentEntity *───1 ShiftEntity
```

## Migrations

- Location: `backend/src/migrations/`
- Run: `npm run typeorm migration:run` (alias for `typeorm-ts-node-commonjs -d src/data-source.ts`)
- Existing: `1778318539844-UpdateShiftAssignment` — creates `shiftAssignment` table with FKs to `doctor` and `shift`, drops `shift.emergency`.

Related: [[api-routes]] · [[doctor-module]] · [[patient-module]]
