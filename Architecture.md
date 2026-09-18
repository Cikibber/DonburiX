# Architecture.md — Lecturer GitHub Tracker

## 1. Purpose

Simple full-stack web app helping lecturers monitor student GitHub repository activity.

Flow:
`Lecturer button click -> Backend calls GitHub REST API -> Insert only new commits into MySQL -> Dashboard reads MySQL only.`

No automatic GitHub polling. No auth in v1. Single lecturer assumed.

## 2. Tech Stack

* Frontend: React + TypeScript + Vite + Tailwind CSS
* Backend: Node.js + TypeScript + Express
* Database: MySQL 8 via Docker Compose
* ORM: Prisma with migrations + seed
* API style: REST, JSON property names in PascalCase
* GitHub: GitHub REST API `GET /repos/{Owner}/{RepositoryName}/commits`
* Monorepo: npm workspaces, TypeScript project references

## 3. Repository Layout

```text
./
  Architecture.md
  README.md
  package.json
  tsconfig.json
  docker-compose.yml
  .env.example
  apps/
    web/
      package.json
      vite.config.ts
      tailwind.config.js
      src/
        main.tsx
        App.tsx
        routes/
        pages/
          DashboardPage.tsx
          CourseManagementPage.tsx
          StudentManagementPage.tsx
          RepositoryManagementPage.tsx
          StudentProgressDetailPage.tsx
        components/
          SummaryCard.tsx
          StatusBadge.tsx
          DataTable.tsx
          ConfirmDialog.tsx
          EmptyState.tsx
          CourseSelector.tsx
        api/
          Client.ts
        hooks/
    api/
      package.json
      prisma/
        schema.prisma
        migrations/
        seed.ts
      src/
        index.ts
        app.ts
        env.ts
        routes/
          CourseRoutes.ts
          StudentRoutes.ts
          RepositoryRoutes.ts
          SyncRoutes.ts
          DashboardRoutes.ts
        controllers/
        services/
          CourseService.ts
          StudentService.ts
          RepositoryService.ts
          GithubService.ts
          SyncService.ts
          DashboardService.ts
        mappers/
        utils/
          ParseRepositoryUrl.ts
  packages/
    shared/
      package.json
      tsconfig.json
      src/
        models/
          Course.ts
          Student.ts
          Repository.ts
          Commit.ts
        enums/
          ActivityStatus.ts
        dto/
          DashboardResponse.ts
          SyncResult.ts
        constants/
        index.ts
```

`apps/web` and `apps/api` import all domain/DTO types from `@lecturer-github-tracker/shared`. No duplication. No Prisma import in frontend.

## 4. Workspace / Build Contract

Root `package.json`:

* `workspaces: ["apps/*", "packages/*"]`
* scripts: `dev`, `build`, `migrate`, `seed`

`packages/shared` name: `@lecturer-github-tracker/shared`, exports `./src/index.ts`, built with `tsc -b`.

`apps/api/package.json` depends on `"@lecturer-github-tracker/shared": "workspace:*"`.
`apps/web/package.json` depends on `"@lecturer-github-tracker/shared": "workspace:*"`.

TypeScript paths + references ensure `shared` compiles before `web` / `api`. Vite resolves workspace package via Node resolution.

## 5. Shared Package

```text
packages/shared/src/
  models/Course.ts
  models/Student.ts
  models/Repository.ts
  models/Commit.ts
  enums/ActivityStatus.ts
  dto/DashboardResponse.ts
  dto/SyncResult.ts
  index.ts
```

Example shapes (PascalCase JSON):

```ts
interface Course { Id: number; Name: string; Semester: string; Year: number; CreatedAt: string; }
interface Student { Id: number; CourseId: number; StudentNumber: string; Name: string; Email: string; GithubUsername: string; CreatedAt: string; }
interface Repository { Id: number; StudentId: number; Name: string; RepositoryUrl: string; Owner: string; RepositoryName: string; IsActive: boolean; LastSyncedAt: string | null; CreatedAt: string; CommitCount?: number; }
interface Commit { Id: number; RepositoryId: number; Sha: string; Message: string; AuthorName: string; AuthorEmail: string; CommittedAt: string; CommitUrl: string; CreatedAt: string; }
enum ActivityStatus { ACTIVE = "ACTIVE", INACTIVE = "INACTIVE", NO_COMMIT = "NO_COMMIT" }
interface SyncResult { RepositoryId: number; FetchedCommitCount: number; NewCommitCount: number; ExistingCommitCount: number; LastSyncedAt: string; Message: string; }
interface CourseDashboardResponse { TotalStudents: number; TotalRepositories: number; TotalCommits: number; ActiveStudents: number; InactiveStudents: number; StudentsWithoutCommits: number; Students: StudentProgressItem[]; }
interface StudentProgressItem { StudentId: number; StudentName: string; StudentNumber: string; RepositoryCount: number; TotalCommits: number; LatestCommitAt: string | null; ActivityStatus: ActivityStatus; }
```

Backend maps Prisma snake/lowercase entities to these PascalCase DTOs in `mappers/` before response. Frontend consumes only these.

## 6. Database Model (Prisma, MySQL)

Prisma models stay in `apps/api/prisma/schema.prisma`. Database-specific, not shared.

Entities:

* `Course(Id, Name, Semester, Year, CreatedAt)`
* `Student(Id, CourseId -> Course, StudentNumber, Name, Email, GithubUsername, CreatedAt)`
* `Repository(Id, StudentId -> Student, Name, RepositoryUrl, Owner, RepositoryName, IsActive, LastSyncedAt?, CreatedAt)`
* `Commit(Id, RepositoryId -> Repository, Sha, Message, AuthorName, AuthorEmail, CommittedAt, CommitUrl, CreatedAt)`

Constraints:

* `@@unique([RepositoryId, Sha])` on Commit.
* Indexes on `Student(CourseId)`, `Repository(StudentId)`, `Commit(RepositoryId, CommittedAt)`.
* Sync never deletes / overwrites commits. Insert-only via `createMany(skipDuplicates: true)` or existence check.
* `LastSyncedAt` updated only after successful sync.

Seed: 1 course, 3 students, 1 public repository per student (e.g. `octocat/Hello-World`, `facebook/react`, `vercel/next.js` or lecturer-chosen teaching repos).

## 7. Backend Architecture

Layers: `Routes -> Controllers -> Services -> Prisma`. `GithubService` isolated for external calls. `SyncService` orchestrates fetch + insert-only save.

Required routes:

```text
GET    /api/courses
POST   /api/courses
GET    /api/courses/:Id
PUT    /api/courses/:Id
DELETE /api/courses/:Id
GET    /api/courses/:CourseId/students
POST   /api/courses/:CourseId/students
PUT    /api/students/:Id
DELETE /api/students/:Id
GET    /api/students/:Id/repositories
POST   /api/students/:Id/repositories
PUT    /api/repositories/:Id
DELETE /api/repositories/:Id
POST   /api/repositories/:Id/sync
POST   /api/courses/:CourseId/sync
GET    /api/courses/:CourseId/dashboard
GET    /api/students/:Id/progress
```

Behavior:

* Course/Student/Repository CRUD: validate input, return shared DTOs, 404 if missing.
* Repository URL validation: accept `https://github.com/owner/repository` with optional trailing `/`, `.git`. Parser `ParseRepositoryUrl.ts` extracts `Owner`, `RepositoryName`. Reject others with Indonesian message.
* `POST /api/repositories/:Id/sync`: load repository, call GitHub, compute `FetchedCommitCount`, insert new only, recount, update `LastSyncedAt`, return `SyncResult`.
* `POST /api/courses/:CourseId/sync`: iterate active repositories in course sequentially, collect per-repo `SyncResult`, continue on single failure, return array + summary.
* `GET /api/courses/:CourseId/dashboard`: aggregate from MySQL only. Compute `ActivityStatus` per student from max `CommittedAt`.
* `GET /api/students/:Id/progress`: student info + repositories + commits ordered `CommittedAt DESC` + totals.

ActivityStatus rules:

* `NO_COMMIT`: no stored commit.
* `INACTIVE`: latest commit older than 14 days.
* `ACTIVE`: latest commit within 14 days.

## 8. GitHub Integration

* `GET https://api.github.com/repos/{Owner}/{RepositoryName}/commits?per_page=100`
* Headers: `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`, optional `Authorization: Bearer GITHUB_TOKEN`.
* Map GitHub fields: `sha -> Sha`, `commit.message -> Message`, `commit.author.name/email -> AuthorName/AuthorEmail`, `commit.author.date -> CommittedAt`, `html_url -> CommitUrl`.
* Public repos first. Private repos without token surface GitHub 404/403 as meaningful Indonesian error.
* Rate limit: on 403 + `X-RateLimit-Remaining: 0`, return `429` with reset time message. No retry loop in v1.
* Invalid/unavailable repo: forward concise Indonesian error, do not update `LastSyncedAt`.

## 9. Frontend Architecture

React + Vite + Tailwind. Simple router, fetch client using shared response types.

Pages:

1. Dashboard: course selector, 5 summary cards, student progress table, `Sync All Repositories` button. Opens with MySQL data only. Shows loading, success, error states.
2. Course Management: list, create/edit form, open dashboard button.
3. Student Management: list per course, add/edit form incl. GitHub username.
4. Repository Management: list per student, add/edit URL form, `Sync Commits` button, last sync + stored commit count.
5. Student Progress Detail: student info, repository list, totals, commit history table (Message, Author, Date, SHA, GitHub link).

Components: cards, tables, badges, forms, delete confirmation dialog, empty states. Responsive lecturer dashboard. No charts in v1.

All UI text Indonesian. Status colors: Active green, Inactive orange, No Commit red.

## 10. Docker / Env

`docker-compose.yml`: MySQL 8 service, persistent volume, healthcheck, port `3306`.

`.env.example`:

```text
DATABASE_URL="mysql://tracker:tracker@localhost:3306/lecturer_github_tracker"
GITHUB_TOKEN=""
PORT=3001
WEB_PORT=5173
```

Backend reads `DATABASE_URL`, optional `GITHUB_TOKEN` via `env.ts`. Frontend uses `VITE_API_BASE_URL`.

README must document: install, Docker MySQL start, Prisma migrate + seed, backend start, frontend start, GitHub token setup.

## 11. Code Rules

* No comments unless truly necessary.
* PascalCase: classes, types, interfaces, enums, React components, Prisma models, DTOs, JSON properties.
* camelCase allowed only for local variables/functions.
* Lines below 150 chars where practical.
* Clean folder structure above. No auth code in v1.

## 12. Deliverables / Acceptance

Complete `apps/web`, `apps/api`, `packages/shared`, Prisma schema + migration + seed, Docker Compose, `.env.example`, README. App builds successfully. Basic CRUD + manual sync verified against public repos.
