---
type: meta
last_updated: 2026-06-02
---

# Wiki Triggers

Maps code areas and topics to wiki articles. Used by commit, feature-explore, and feature-build.

## File-Path Triggers

| Files touched                                                              | Articles to load / update |
| -------------------------------------------------------------------------- | ------------------------- |
| `backend/src/**/*.controller.ts`                                           | `api-routes.md`           |
| `backend/src/auth/**`, `backend/src/common/guards/**`                      | `auth-flow.md`            |
| `backend/src/database/**`, `backend/src/migrations/**`, `**/entities/**`   | `database-schema.md`      |
| `backend/src/patient/**`                                                   | `patient-module.md`       |
| `backend/src/doctor/**`                                                    | `doctor-module.md`        |
| `backend/src/admin/**`                                                     | `admin-module.md`         |
| `backend/src/common/**`                                                    | `core-modules.md`         |
| `backend/src/ai/**`                                                        | `ai-integration.md`       |
| `AI/**` (Python service, model, gemini)                                    | `ai-integration.md`       |
| `frontend/lib/**`                                                          | `ui-components.md`        |

Additional triggers (any → update required on commit):

- A constraint changed (timezone, JWT TTL, DB connection settings)
- A wiki summary paragraph is now factually wrong

## Topic-Keyword Triggers

| Keywords                                          | Articles to load     |
| ------------------------------------------------- | -------------------- |
| auth / login / logout / JWT / token / guard       | `auth-flow.md`       |
| schema / DB / database / migration / entity / TypeORM | `database-schema.md` |
| route / endpoint / controller / API / Swagger     | `api-routes.md`      |
| patient / bệnh nhân                               | `patient-module.md`  |
| doctor / bác sĩ                                   | `doctor-module.md`   |
| admin / quản trị                                  | `admin-module.md`    |
| UI / screen / widget / Flutter / màn hình         | `ui-components.md`   |

Fallback: if no keyword matches, load `project-architecture.md` as baseline (create this article when project structure stabilizes).

## Usage by Skill

| Skill             | Table         | On what input                     |
| ----------------- | ------------- | --------------------------------- |
| `commit`          | File-Path     | Files in the diff                 |
| `feature-explore` | Topic-Keyword | Keywords in requirements          |
| `feature-build`   | File-Path     | Feature spec Scope file list      |
| `wiki-lookup`     | Both          | The argument (file path or topic) |
