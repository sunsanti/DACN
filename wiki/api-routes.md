---
last_updated: 2026-10-04 (đợt 2)
tags: [api, routes, controllers, swagger, auth]
---

# API Routes

All HTTP endpoints of the NestJS backend. Swagger UI at **`GET /api`** (Bearer auth supported). Base URL dev: `http://localhost:3000`.

**Auth:** a global `JwtAuthGuard` protects everything; only `@Public()` routes are open. Role gating via `@Roles(...)`. See [[auth-flow]]. JWT carries `{sub, role, patientId?, doctorId?}`.

## Auth — `@Controller('auth')`

| Method | Path | Access | Notes |
| --- | --- | --- | --- |
| POST | `/auth/register` | `@Public` | Patient self-registration (multipart): **`cccd` required** (12 digits, unique → 409), optional `avatar`. BHYT is looked up by CCCD (no self-declared card) |
| POST | `/auth/bhyt-lookup` | `@Public` + throttle 10/min/IP | Pre-registration BHYT preview `{cccd, birthDate}` → `{found:false}` or `{found, cardNumber (masked 3+4), rate, validTo, status}`. Read-only |
| POST | `/auth/login` | `@Public` | `{email,password}` → `{accessToken, role, patientId?, doctorId?, name, avatarUrl}` |
| POST | `/auth/register-doctor` | `admin` | Admin creates a doctor (multipart, **`avatar` required**) |

## Patient — `@Controller('patient')` `@Roles('patient')`

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/patient/me` | Own profile + full `cccd` (owner only) + `insurance`: `null` or `{cardNumber, validFrom, validTo, rate, status}` from the BHYT registry (CCCD + birth date must match) |
| POST | `/patient/appointment/:id/pay` | `{method: 'cash'\|'qr'}` → `pending`; QR returns `qr = {payload (VietQR string), bankName, accountNo, accountName, amount, content: DACN{id}}`; 503 if bank env missing |
| PUT | `/patient/me` | Update own profile (`UpdatePatientDTO`) |
| POST | `/patient/create-appointment` | `{apTime, address, doctorId, note?}`; patientId from JWT; confirmCondition=1 |
| GET | `/patient/list-appointment` | Own appointments |
| GET | `/patient/appointment/:id` | Detail (ownership-checked) incl. bill (`examFee, examFeeCovered, total, insuranceRate, insuranceCovered, payable, insuranceCardNumber` + `items[]` with `bhytCovered`) and payment (`paymentStatus` unpaid/pending/paid, `paymentMethod`, `paidAt`) |
| PUT | `/patient/reschedule-appointment/:id` | `{apTime, note?}` — change to a free slot, **once**; confirmed → back to pending |
| POST | `/patient/cancel-appointment/:id` | `{reason}` — cancel (keeps the row; not a delete) |

## Doctor — `@Controller('doctor')` (per-method roles)

Open to any authenticated user (patient booking needs these):
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/doctor/list` | All doctors (for the booking dropdown) |
| GET | `/doctor/availability?doctorId=&date=` | Free 30-min slots = doctor's ACTIVE shift windows that day − booked times |

Admin-only (`@Roles('admin')`):
| GET | `/doctor/detail/:id` | Doctor detail |
| PUT | `/doctor/update/:id` | Edit doctor (`UpdateDoctorDTO`) |

Doctor-only (`@Roles('doctor')`):
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/doctor/list-unAcpappointment` | Pending (confirmCondition=1) for this doctor |
| GET | `/doctor/list-appointment` | Confirmed (0) for this doctor |
| GET | `/doctor/list-completed` | Examined (2) for this doctor |
| GET | `/doctor/appointment/:id` | Detail + patient info (ownership) |
| POST | `/doctor/confirm-appointment/:id` | Confirm → 0; `{note,confirmDate}` writes **doctorNote** (not patient note) |
| POST | `/doctor/complete/:id` | **Send diagnosis:** `{diseaseIds: number[]}` (≥1, unique, active) → 2 + bill snapshot: `EXAM_FEE` + disease prices; BHYT (card by CCCD) reimburses only covered parts (exam fee if `EXAM_FEE_BHYT_COVERED`, lines with `bhytCovered`). `payable 0` → `paid`. One transaction. 400 if not confirmed / canceled / bad ids |
| POST | `/doctor/cancel-appointment/:id` | `{reason}` — reject (pending) / cancel (confirmed); reason sent to patient |
| PUT | `/doctor/reschedule-appointment/:id` | `{apTime}` — move a confirmed appt to a free slot of the doctor's availability; once; stays confirmed |
| POST | `/doctor/re-examination` | Create a new confirmed appointment for a patient |
| DELETE | `/doctor/appointment/:id` | Hard-delete (legacy; UI uses cancel) |
| GET | `/doctor/report/:appointmentId` | Download the patient's AI report PDF (own appointments only, `assertOwns` → 403) |
| GET | `/doctor/shift-templates?date=` | Time-of-day templates; with `date` each also has `registered`/`capacity` (max 4 doctors) |
| POST | `/doctor/register-shift` | `{shiftId, date}` → ACTIVE assignment on a real date; 409 if that shift already has 4 ACTIVE doctors |
| GET | `/doctor/my-shifts` | This doctor's shift assignments |
| GET | `/doctor/shift-overview` | (`doctor`/`admin`) ACTIVE shifts of the current week (Mon → Sun) + which doctor |
| POST | `/doctor/cancel-assignment/:id` | Cancel → pays hours worked (clamp now to [start,end]−start) |
| DELETE | `/doctor/assignment/:id` | Delete an assignment |

## Admin — `@Controller('admin')` `@Roles('admin')`

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/admin/doctor-salaries` | Per-doctor `{totalHours, hourlyRate, salary}` (ACTIVE full + CANCELED partial × `ADMIN_HOURLY_RATE`) |

## Diseases (price list) — `@Controller('diseases')`

| Method | Path | Access | Notes |
| --- | --- | --- | --- |
| GET | `/diseases` | `admin`, `doctor` | `{examFee, examFeeBhytCovered, items[]}` — doctors see only `active`, admin sees all |
| POST | `/diseases` | `admin` | `{name, price, bhytCovered?}` (price ≥ 0); duplicate name → 409 |
| PATCH | `/diseases/:id` | `admin` | `{name?, price?, active?, bhytCovered?}` — **no DELETE**, switch off instead |

## News — `@Controller('news')`

| Method | Path | Access | Notes |
| --- | --- | --- | --- |
| GET | `/news?limit=` | authenticated | Newest first, `limit` clamped to 1..50 (default 50) |
| POST | `/news` | `admin` | multipart `title`, `url` (http/https only), `image` (required) |
| DELETE | `/news/:id` | `admin` | Deletes the row **and** its image file |

## Payment — `payment/` module

| Method | Path | Access | Notes |
| --- | --- | --- | --- |
| POST | `/payments/sepay-webhook` | `@Public` + header `Authorization: Apikey <SEPAY_API_KEY>` | SePay → us on each bank transfer. Dedup by SePay `id`. `DACN{id}` in content + amount == `payable` → `paid` + admin notification; else warning notification. Always `{success:true}` (401 bad key, 503 key not configured) |
| GET | `/admin/payments?status=pending\|paid` | `admin` | Bills waiting for confirmation / paid |
| POST | `/admin/payments/:id/confirm` | `admin` | pending → paid (cash, or a transfer handled by hand); `paidBy` = admin account |
| GET | `/admin/notifications` · `/admin/notifications/unread-count` | `admin` | Inbox (money received / transfers to check) |
| POST | `/admin/notifications/read-all` | `admin` | Mark all read |

## Uploads (static)

`GET /uploads/<avatars|news>/<uuid>.<ext>` — served by `useStaticAssets` (after `enableCors`), **public, no JWT**. Images only (jpeg/png/webp, ≤ 2 MB), server-chosen UUID names. Shared helper `backend/src/common/upload.ts` (`imageUpload`, `toPublicPath`, `removeUpload`, `CleanupUploadOnError`). Never store medical data here.

## AI — `@Controller('ai')` `@ApiBearerAuth`

Proxy to the Python AI service (`AI_SERVICE_URL`, default `:8000`). See [[ai-integration]].

| Method | Path | Access | Notes |
| --- | --- | --- | --- |
| POST | `/ai/diagnose-image` | authenticated | multipart `image` → top-3 (Swin V2 `.pth`) |
| POST | `/ai/chat` | authenticated | `{symptoms}` → top-3 (Gemini) |
| POST | `/ai/report` | `patient` | multipart `symptoms` (required, else 400) + optional `image` + `appointmentId` → PDF; saves `medical_report`; appointment ownership-checked (IDOR guard) |

## Conventions

- `confirmCondition`: **1=pending, 0=confirmed, 2=examined** (rule 3 in [[critical-constraints]]).
- `:id` params use `ParseIntPipe`; date DTOs use `@Type(() => Date)` / `IsDateString`.
- Ownership checks (`assertOwns`) on patient & doctor appointment mutations.

Related: [[patient-module]] · [[doctor-module]] · [[admin-module]] · [[auth-flow]] · [[database-schema]]
