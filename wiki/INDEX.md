# Knowledge Base Index

_Last updated: 2026-10-04_

## Topics

| File                     | Summary                                                            |
| ------------------------ | ----------------------------------------------------------------- |
| [[project-report]]       | Tóm tắt báo cáo ĐACN1 (tầm nhìn AI/Flutter) + đối chiếu code     |
| [[ai-integration]]       | Kế hoạch tích hợp AI: Python service (.pth) + Gemini proxy qua NestJS |
| [[project-architecture]] | High-level overview — NestJS backend + Flutter, wired vs. stubbed |
| [[database-schema]]      | TypeORM entities (incl. news, disease, appointment_item), migrations |
| [[api-routes]]           | All HTTP endpoints (auth, patient, doctor, diseases, news, uploads, AI) |
| [[patient-module]]       | Patient records + appointment booking                             |
| [[doctor-module]]        | Appointment confirm/reschedule + shift scheduling                 |
| [[auth-flow]]            | JWT + roles; multipart register with avatar / BHYT card            |
| [[admin-module]]         | Admin — salaries, doctors, news, price list                       |
| [[ui-components]]        | Flutter app, 3 roles; avatar, news carousel, bill widgets          |
| [[known-issues]]         | WIP bugs, hardcoded data, security debt, TODOs                    |
| [[critical-constraints]] | Project hard rules — read before any route or module work         |
| [[wiki-triggers]]        | File-path + topic-keyword → article mapping                       |
| [[log]]                  | Chronological record of wiki changes                              |

## Quick Reference

- **Backend** lives in `backend/src/` (NestJS 11 + TypeORM + Postgres `dacn_db`, port 3000, Swagger `/api`).
- **Modules**: auth, patient, doctor, admin, ai, news, disease (+ `billing/` util). Flutter app covers all 3 roles.
- **`confirmCondition`**: `1` = pending, `0` = confirmed, `2` = examined (bill written here).
- **Payment**: `paymentStatus` unpaid → pending (cash/QR) → paid (SePay webhook or admin). BHYT by CCCD from the read-only `bhyt_registry`.
- **Shift model**: `ShiftAssignment` join entity carries status (`ACTIVE`/`CANCELED`/`REPLACED`) + duration.
- Start with [[project-architecture]], then [[database-schema]] → [[api-routes]].
