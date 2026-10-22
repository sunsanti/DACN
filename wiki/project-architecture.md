---
last_updated: 2026-06-02
tags: [architecture, overview]
---

# Project Architecture

DACN is a medical appointment platform: a **NestJS 11 + TypeORM 0.3 + PostgreSQL** REST backend with a **Flutter** cross-platform client. The domain covers patients booking appointments, doctors confirming/rescheduling them, and doctors registering work shifts. Auth and the admin area are scaffolded but not yet implemented.

## High-Level Layout

```
DACN/
├── backend/        NestJS API (the real code lives here)
│   └── src/
│       ├── main.ts            bootstrap, Swagger at /api, listens on :3000
│       ├── app.module.ts      wires Patient + Doctor + Database modules
│       ├── database/          TypeOrmModule.forRoot (Postgres connection)
│       ├── data-source.ts     standalone DataSource for TypeORM CLI migrations
│       ├── auth/login/        STUB — empty service
│       ├── common/            guards (STUB) + public.decorator
│       ├── admin/             STUB — empty controller/service/module
│       ├── patient/           patient + appointment features
│       ├── doctor/            doctor + shift features
│       └── migrations/        TypeORM migrations
└── frontend/       Flutter app — currently default starter (only lib/main.dart)
```

## Backend Stack

- **NestJS 11** (`@nestjs/common`, `@nestjs/core`, platform-express)
- **TypeORM 0.3** + **PostgreSQL** via `pg`, `@nestjs/typeorm`
- **Swagger** (`@nestjs/swagger`) — UI served at `GET /api`
- Server listens on **port 3000**
- `start` script forces `TZ=Asia/Ho_Chi_Minh`

## Module status (all wired as of 2026-06-03)

| Area | Status |
| --- | --- |
| Auth (`auth/`) | ✅ account + JWT + global guards (`JwtAuthGuard`, `RolesGuard`) |
| Patient module | ✅ profile + appointment CRUD (availability-based booking) |
| Doctor module | ✅ appointments (confirm/examine/re-exam) + real-dated shifts + availability |
| Admin module | ✅ wired; add/edit doctor + salary-by-hours |
| AI module | ✅ proxies Python service; report PDF persisted ([[ai-integration]]) |
| Database module | ✅ env-based Postgres connection |
| Flutter frontend | ✅ all 3 role UIs (Provider + dio) — [[ui-components]] |

Backend has an **e2e smoke test** (`npm run test:e2e`).

## Key Modules

- [[database-schema]] — entities, relations, migrations
- [[api-routes]] — all HTTP endpoints
- [[patient-module]] — appointment booking
- [[doctor-module]] — appointment confirmation + shift management
- [[auth-flow]] — current (unimplemented) auth state
- [[admin-module]] — admin stub
- [[ui-components]] — Flutter client
- [[known-issues]] — WIP bugs, hardcoded data, TODOs
- [[critical-constraints]] — hard rules

## How to Run (backend)

```bash
cd backend
npm install
npm run start:dev        # nest start --watch, port 3000
# migrations:
npm run typeorm migration:run
```

Requires a local Postgres with database `dacn_db` (see [[database-schema]] for connection details — credentials are currently hardcoded, see [[known-issues]]).
