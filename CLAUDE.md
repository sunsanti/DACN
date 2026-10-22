# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

DACN is a medical appointment app (university project, Vietnamese UI/docs). It has three parts that run as separate processes:

- `backend/`: NestJS 11 + TypeORM 0.3 + PostgreSQL (`dacn_db`). REST API on `0.0.0.0:3000`, Swagger UI at `/api`.
- `frontend/`: a Flutter client (Provider + dio) with patient, doctor and admin UIs.
- `AI/`: a FastAPI service on `:8000`. It runs skin-disease image classification with a Swin V2 `.pth` model and symptom analysis through Gemini. Only NestJS calls it (via `backend/src/ai/`); Flutter never calls it directly.

`wiki/` is the project knowledge base. Start with `wiki/INDEX.md`. `wiki/wiki-triggers.md` maps each code area to the article you should update when you change that area. Read `wiki/critical-constraints.md` before you touch routes, the DB or modules.

## Commands

Backend (run from `backend/`):

```bash
npm run start:dev            # runs AI (uvicorn :8000, AI/.venv) + API (nest --watch) via concurrently
npm run start:backend        # API only
npm start                    # API with TZ=Asia/Ho_Chi_Minh
npm run lint                 # eslint --fix
npm test                     # unit tests (jest, rootDir src, *.spec.ts)
npx jest src/path/to/file.spec.ts            # single unit test
npm run test:e2e                             # e2e (test/*.e2e-spec.ts), hits the real dev DB
npx jest --config ./test/jest-e2e.json test/patient-flow.e2e-spec.ts   # single e2e file
npm run typeorm migration:run                # apply migrations (src/data-source.ts)
npm run typeorm migration:generate src/migrations/<Name>
npx ts-node src/reset-db.ts  # DESTRUCTIVE: truncate all data, re-seed admin (admin@dacn.local / Admin@123) + 3 shift templates
node test/api-smoke.mjs      # end-to-end smoke against a running API (:3000) + AI (:8000); creates uitest_* data
```

To bootstrap a new DB, run `backend/schema.sql` (a pg_dump) in pgAdmin against an empty `dacn_db`. Then run `npm run typeorm migration:run`: the dump records migrations 1–6, so this applies the newer ones (doctor avatar, news, BHYT/pricing).

Frontend (run from `frontend/`):

```bash
flutter pub get
flutter run                                          # base URL chosen per platform in lib/config/api_config.dart
flutter run --dart-define=API_BASE=http://<LAN_IP>:3000   # real device
flutter analyze
flutter test
```

AI service (run from `AI/`): `pip install -r requirements.txt`, then `uvicorn app:app --port 8000`. It needs `GEMINI_API_KEY` in `AI/.env`. The `.pth` weights file is gitignored.

## Backend architecture

- **Auth is global.** `app.module.ts` registers `JwtAuthGuard`, then `RolesGuard`, as `APP_GUARD`, so every route requires a JWT by default. Use `@Public()` to opt out (only `/auth/login` and `/auth/register` do). Use `@Roles('patient'|'doctor'|'admin')` to role-gate and `@CurrentUser()` to get the caller (decorators are in `common/decorators/`). Patients self-register, admins create doctors, and the admin account is seeded.
- **Ownership checks are required.** Doctor actions on an appointment go through `assertOwns` in `doctor.service`. `ai.service.buildReport` checks that the appointment belongs to the calling patient. New endpoints that act on someone's records need the same kind of IDOR check.
- **There are two DB configs.** `database/database.module.ts` is the runtime config (ConfigService, autoLoadEntities). `data-source.ts` is the TypeORM CLI/reset config (dotenv, explicit entity list). Add each new entity to `data-source.ts`. Both read `DB_*` env vars with dev defaults.
- **`synchronize: false` always.** Every schema change goes through a migration in `src/migrations/`.
- **Domain:** `AccountEntity` (auth) links to a `PatientEntity` or `DoctorEntity`. `AppointmentEntity` links patient and doctor and holds separate doctor and patient notes, a cancel reason and a reschedule-once flag. `ShiftEntity` holds time-of-day templates (morning, afternoon, evening). `ShiftAssignmentEntity` is the doctor↔shift join with a real date, a status (`ACTIVE`/`CANCELED`/`REPLACED`) and a computed `duration` in hours. Admin salary is hours × `ADMIN_HOURLY_RATE`. `MedicalReportEntity` stores the AI-generated PDF (pdfkit).
- **`confirmCondition` on appointments: `1` = pending, `0` = confirmed, `2` = examined.** Do not invert it.
- **Uploads.** `common/upload.ts` handles image uploads (jpeg/png/webp, ≤ 2 MB, UUID names) into `backend/uploads/` (gitignored), served publicly at `/uploads/*` (no JWT). Add `CleanupUploadOnError` after `FileInterceptor` so failed requests delete the file. Only avatars and news images go there, never medical data.
- **Billing.** Admin keeps a price list (`disease`). When the doctor completes a visit (`POST /doctor/complete/:id {diseaseIds}`), the bill (`EXAM_FEE` + disease prices − BHYT if the patient's card is valid on the visit day) is snapshotted on the appointment + `appointment_item` rows. Math lives in `billing/billing.util.ts` (unit-tested).
- The server timezone is fixed to `Asia/Ho_Chi_Minh`. Appointment and shift timestamps depend on it.
- **CCCD → BHYT.** Registration requires a 12-digit CCCD (`patient.cccd`, `select: false`). BHYT comes only from the read-only `bhyt_registry` (seeded by migration, no API writes it) via `BhytService.findCard(cccd, birthDate)`. Only BHYT-covered parts are reimbursed (`disease.bhytCovered`, `EXAM_FEE_BHYT_COVERED`).
- **Payments** (`payment/`): patient picks cash or VietQR (`billing/vietqr.util.ts` builds the EMVCo string; Flutter renders it with `qr_flutter`). The SePay webhook `POST /payments/sepay-webhook` (`Authorization: Apikey <SEPAY_API_KEY>`) marks the bill paid when `DACN{id}` + exact amount match and notifies admins; cash is confirmed by an admin. To receive real webhooks in dev, expose `:3000` (e.g. ngrok) and set that URL in the SePay dashboard; `test/api-smoke.mjs` simulates the webhook.
- DB session timezone is set to `Asia/Ho_Chi_Minh` in both DB configs (the Postgres container runs in UTC).
- Env vars (`backend/.env`, never committed): `DB_*`, `JWT_SECRET`, `JWT_EXPIRES`, `AI_SERVICE_URL`, `ADMIN_HOURLY_RATE`, `EXAM_FEE` (fixed exam fee in VND, default 150000), `EXAM_FEE_BHYT_COVERED` (default true), `PAYMENT_BANK_BIN`, `PAYMENT_BANK_NAME`, `PAYMENT_ACCOUNT_NO`, `PAYMENT_ACCOUNT_NAME` (receiving account for VietQR), `SEPAY_API_KEY`.

## Frontend architecture

The layers run `screens/` → `providers/` (ChangeNotifier: auth, appointment, doctor, admin, registered in `main.dart`) → `services/` (dio calls) → `models/`. `core/dio_client.dart` attaches the JWT from `token_store.dart` (shared_preferences). `AuthGate` in `main.dart` routes the user to the patient, doctor or admin home screen by role. PDF opening is split by platform with conditional imports (`pdf_opener_io.dart` / `pdf_opener_web.dart`).
