---
last_updated: 2026-10-04
---

# Critical Constraints

Hard rules for this project. Read before touching routes, DB, or modules.

## Rules

| #   | Rule                                                                                          | Why                                                                 |
| --- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1   | Server timezone is fixed to `Asia/Ho_Chi_Minh` (`start` script in `backend/package.json`)    | Appointment / shift timestamps must be consistent for VN users      |
| 2   | `synchronize: false` — never enable TypeORM auto-sync; schema changes go through migrations   | Auto-sync can silently drop/alter medical data                      |
| 3   | `confirmCondition`: `1` = pending, `0` = confirmed. Do not invert.                            | The whole appointment flow (doctor list/confirm) depends on this    |
| 4   | Keep `database.module.ts` and `data-source.ts` connection config + entity list in sync        | Two separate Postgres configs (runtime autoLoad vs CLI explicit list) |
| 5   | Auth IS enforced: global `JwtAuthGuard` (APP_GUARD) protects everything; `@Public()` only on `/auth/login` + `/auth/register`. Role-gate with `@Roles('patient'\|'doctor'\|'admin')` | Medical data must not be public (F01 shipped) |
| 6   | Secrets go in `.env`, never in source. DB creds read from `DB_*` env (defaults kept for dev); JWT/Gemini keys env-only | Source is committed; secrets must not be |
| 7   | AI runs as a **separate Python process** (`AI/`, FastAPI :8000); NestJS proxies to it          | `.pth` (PyTorch) can't run in Node; key `GEMINI_API_KEY` + `AI_SERVICE_URL` in `.env` only |
| 8   | Ownership checks on resource access: doctor confirm/reschedule (`assertOwns`); patient `/ai/report` appointment must belong to the caller | Prevent IDOR — acting on another user's records |
| 9   | `/uploads/*` is public (no JWT): images only (jpeg/png/webp ≤ 2 MB, UUID names). Never put medical data there; keep `useStaticAssets` after `enableCors` | Static files bypass the guards; CanvasKit web needs CORS |
| 10  | Bills are snapshots: `appointment` totals + `appointment_item` name/price, no FK to `disease`; never recompute an existing bill | Price-list edits must not change past bills |
| 11  | `patient.cccd` is `select: false`; read it only with an explicit `addSelect` for the owner or for billing. BHYT comes only from the read-only `bhyt_registry` (CCCD + birth date) — no API may write it | CCCD is sensitive personal data; admins must not register BHYT |
| 12  | SePay webhook: verify `Authorization: Apikey` (constant-time), dedup on SePay `id`, mark `paid` only when `DACN{id}` matches **and** amount == `payable`; anything else → admin notification, never auto-paid | Bank apps may let payers edit the amount; SePay retries up to 7× |
| 13  | DB session timezone = `Asia/Ho_Chi_Minh` in both DB configs | Postgres container is UTC; `now()` defaults must match Node's wall clock |

## Notes (state as of 2026-06-03, harden phase done)

- **Rule 5 (DONE):** global `JwtAuthGuard` + `RolesGuard` via `APP_GUARD` (F01). `/doctor/list` + `/doctor/create-doctor` are authenticated but not role-gated (patient booking needs the list).
- **Rule 6 (DONE for DB):** `DB_HOST/PORT/USER/PASSWORD/NAME` via `ConfigService` (runtime) + `dotenv` (`data-source.ts` CLI), defaults preserved. Also env: `JWT_SECRET`, `JWT_EXPIRES`, `AI_SERVICE_URL`, `ADMIN_HOURLY_RATE`.
- **Rule 7:** `npm run start:dev` runs both processes (concurrently, no `-k` so AI failure doesn't kill the API). Backend binds `0.0.0.0`; CORS enabled for Flutter web. Never commit `.pth` or keys.
- **Rule 8 (NEW, harden):** `assertOwns` in `doctor.service`; patient-id check in `ai.service.buildReport`. Shift `duration` now computed (add = end−start, cancel = now−start), replacing the old buggy formula.

_This file is loaded by feature-explore and feature-build when constraint-sensitive work is detected._
