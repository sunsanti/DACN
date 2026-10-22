---
last_updated: 2026-10-04
tags: [auth, security, jwt, avatar]
---

# Auth Flow

**Status: IMPLEMENTED.** JWT auth with three roles (`patient`, `doctor`, `admin`).

## Pieces

- `backend/src/auth/` — `AuthController` (`/auth/register`, `/auth/login`, `/auth/register-doctor`), `AuthService` (bcrypt + `JwtService`), `AccountEntity` (email, passwordHash, role, patient/doctor link).
- Global guards (`app.module.ts`, `APP_GUARD`): `JwtAuthGuard` then `RolesGuard`. Every route needs a JWT unless marked `@Public()` (register, login, bhyt-lookup; bhyt-lookup is also rate-limited by `ThrottlerGuard`, 10/min/IP). `@Roles(...)` gates by role, `@CurrentUser()` gives `{sub, role, patientId?, doctorId?}`.
- JWT secret/TTL: `JWT_SECRET`, `JWT_EXPIRES` (env; dev fallback secret in `auth.module.ts`).
- Admin is seeded (`admin@dacn.local` / `Admin@123`); patients self-register; only admins create doctors.

## Register / login (multipart since 2026-10-04)

| Route | Body | Notes |
| --- | --- | --- |
| `POST /auth/register` | `multipart/form-data` (JSON still accepted) | **`cccd` required** (12 digits, unique → 409 `CCCD đã được đăng ký`, not editable later); `avatar` image optional. BHYT is **not** typed by the patient: it is looked up by CCCD in `bhyt_registry` |
| `POST /auth/register-doctor` (admin) | `multipart/form-data` | `avatar` image **required** (400 `Bác sĩ phải có ảnh đại diện`) |
| `POST /auth/login` | JSON | — |

Login/register response: `{ accessToken, role, patientId?, doctorId?, name, avatarUrl }`.
- `avatarUrl` is the server path (`/uploads/avatars/<uuid>.jpg`) or `null`; admin gets `name: "Admin"`.
- **Key naming:** only the login/register response uses `avatarUrl`; entities returned elsewhere (`/doctor/list`, `/patient/me`, appointment `doctor`/`patient` relations, `/admin/doctor-salaries`) expose the column as **`avatar`** (`''` = none).
- `multipart` sends every field as a string → DTO `age` has `@Type(() => Number)`.
- Upload failures (bad DTO, duplicate email, …) delete the just-uploaded file (`CleanupUploadOnError`, see [[api-routes]] › Uploads).

## Flutter

`AuthResult` carries `name` + `avatarUrl`; `TokenStore` persists them with token/role so the header avatar survives an app restart. `AuthGate` (`main.dart`) routes by role.

Related: [[api-routes]] · [[admin-module]] · [[critical-constraints]]
