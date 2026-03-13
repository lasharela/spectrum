# Spectrum MVP Design: Auth + Community Feed

## Overview

Spectrum is a social network for people with autism and their parents/caregivers. This spec covers the MVP: restructuring the existing Flutter app into a monorepo with a TypeScript backend, implementing authentication and a community feed.

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Frontend | Flutter + Riverpod | Existing app, Riverpod for async/testable state |
| Backend | Hono (TypeScript) | Runs on CF Workers + Node.js (portable) |
| Database | Neon (Postgres) | Free tier, Prisma-compatible, serverless |
| ORM | Prisma (edge client) | User's preferred ORM, `@prisma/adapter-neon` for Workers |
| Auth | Better Auth | Self-hosted, Prisma adapter, no vendor lock-in |
| Deploy | Cloudflare Workers | 100K req/day free tier |
| Monorepo | pnpm workspaces | Fast, strict deps, disk efficient |

### Prisma on Cloudflare Workers

Prisma runs on Workers via the edge client configuration:
- Use `@prisma/client/edge` (not the standard client)
- Use `@prisma/adapter-neon` with `@neondatabase/serverless` driver
- Better Auth receives this edge-configured Prisma instance via its Prisma adapter
- **Fallback plan:** If Better Auth's Prisma adapter does not work with the edge client during implementation, switch to Drizzle ORM (edge-native, Better Auth has a Drizzle adapter). This is validated in implementation step 3 before building auth.

## MVP Scope

**In scope:**
- Auth: sign-up, sign-in, sign-out, get current user
- Community feed: create/delete posts, paginated feed, comments, reactions (like/unlike)
- Monorepo restructure with clean separation

**Out of scope (future):**
- Magic link auth
- Image uploads
- Post editing
- Nested comments
- Organizations/resources features (keep existing mock data)
- Push notifications
- Real-time updates

## Monorepo Structure

```
spectrum/
├── contracts/                    # OpenAPI specs (source of truth)
│   ├── auth.yaml
│   └── community.yaml
├── backend/
│   ├── src/
│   │   ├── index.ts              # Hono app entry
│   │   ├── auth/
│   │   │   └── auth.ts           # Better Auth config
│   │   ├── middleware/
│   │   │   └── session.ts        # Auth guard middleware
│   │   ├── routes/
│   │   │   ├── auth.ts           # Mount Better Auth handler on /api/auth/*
│   │   │   └── community.ts     # Posts/comments/reactions
│   │   ├── db/
│   │   │   ├── schema.prisma
│   │   │   ├── migrations/
│   │   │   └── client.ts         # Prisma edge client (Neon adapter)
│   │   └── types/
│   │       └── context.ts        # Hono context types
│   ├── test/
│   │   ├── routes/
│   │   │   ├── auth.test.ts
│   │   │   └── community.test.ts
│   │   ├── middleware/
│   │   │   └── session.test.ts
│   │   └── setup.ts
│   ├── wrangler.toml
│   ├── package.json
│   └── tsconfig.json
├── frontend/                     # Flutter app (moved from root)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   ├── router/app_router.dart
│   │   │   ├── themes/
│   │   │   └── utils/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   ├── domain/
│   │   │   │   │   └── user.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── screens/
│   │   │   │       ├── providers/
│   │   │   │       │   └── auth_provider.dart
│   │   │   │       └── widgets/
│   │   │   ├── community/
│   │   │   │   ├── data/
│   │   │   │   │   └── community_repository.dart
│   │   │   │   ├── domain/
│   │   │   │   │   ├── post.dart
│   │   │   │   │   └── comment.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── screens/
│   │   │   │       │   ├── feed_screen.dart
│   │   │   │       │   └── post_detail_screen.dart
│   │   │   │       ├── providers/
│   │   │   │       │   └── feed_provider.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── post_card.dart
│   │   │   │           └── comment_list.dart
│   │   │   └── ... (home, profile, etc. — unchanged)
│   │   ├── shared/
│   │   │   ├── api/
│   │   │   │   └── api_client.dart
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   │   └── api_provider.dart
│   │   │   ├── services/
│   │   │   └── widgets/
│   │   │       └── main_navigation_shell.dart
│   │   └── main.dart
│   ├── test/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/auth_repository_test.dart
│   │   │   │   └── presentation/auth_provider_test.dart
│   │   │   └── community/
│   │   │       ├── data/community_repository_test.dart
│   │   │       └── presentation/feed_provider_test.dart
│   │   ├── shared/
│   │   │   └── api/api_client_test.dart
│   │   └── helpers/
│   │       └── mocks.dart
│   └── pubspec.yaml
├── pnpm-workspace.yaml
├── package.json                  # Root scripts
├── CLAUDE.md
└── README.md
```

## API Contracts

### Auth (`contracts/auth.yaml`)

Better Auth provides its own HTTP handler mounted at `/api/auth/*`. The Flutter client calls these endpoints directly. Better Auth's built-in routes handle:

| Endpoint | Method | Body / Params | Response |
|----------|--------|---------------|----------|
| `POST /api/auth/sign-up/email` | POST | `{ email, password, name }` | `{ user, session, token }` |
| `POST /api/auth/sign-in/email` | POST | `{ email, password }` | `{ user, session, token }` |
| `POST /api/auth/sign-out` | POST | — | `{ success: true }` |
| `GET /api/auth/get-session` | GET | — (Bearer token) | `{ user, session }` |

**Custom `userType` field:** Better Auth supports additional user fields via its `user.additionalFields` config. The `userType` field is declared in the Better Auth config and included in the Prisma schema. It is accepted during sign-up and returned in session/user responses. Server-side validation ensures `userType` is one of: `parent`, `autistic_individual`, `professional`, `educator`, `therapist`, `supporter` — rejected with `VALIDATION_ERROR` otherwise (via Zod validation in a Better Auth `before` hook or custom sign-up wrapper).

**Custom endpoint for profile:**

| Endpoint | Method | Body / Params | Response |
|----------|--------|---------------|----------|
| `GET /api/me` | GET | — (Bearer token) | `{ user }` (with userType) |

### Community (`contracts/community.yaml`)

All endpoints require authentication (Bearer token).

| Endpoint | Method | Body / Params | Response | Auth |
|----------|--------|---------------|----------|------|
| `GET /api/posts` | GET | `?cursor=&limit=20` | `{ posts[], nextCursor }` | Required |
| `POST /api/posts` | POST | `{ content, tags[] }` | `{ post }` | Required |
| `GET /api/posts/:id` | GET | — | `{ post }` | Required |
| `DELETE /api/posts/:id` | DELETE | — | `{ success: true }` | Required, author only (403 otherwise) |
| `GET /api/posts/:id/comments` | GET | `?cursor=&limit=20` | `{ comments[], nextCursor }` | Required |
| `POST /api/posts/:id/comments` | POST | `{ content }` | `{ comment }` | Required |
| `PUT /api/posts/:id/reactions` | PUT | — | `{ liked: true, likesCount }` | Required |
| `DELETE /api/posts/:id/reactions` | DELETE | — | `{ liked: false, likesCount }` | Required |
| `DELETE /api/posts/:id/comments/:commentId` | DELETE | — | `{ success: true }` | Required, author only (403 otherwise) |

**Pagination:** cursor-based using `id`. Default limit: 20.

**Note:** `GET /api/posts/:id` returns only the post (no inline comments). Comments are always fetched via the paginated `GET /api/posts/:id/comments` endpoint.

**Reactions:** Explicit like (`PUT`) and unlike (`DELETE`) instead of a toggle, to avoid race conditions on rapid taps.

### Error Responses

All errors follow the shape `{ error: string, code: string }` with appropriate HTTP status codes.

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid auth token |
| `FORBIDDEN` | 403 | Action not allowed (e.g., deleting another user's post) |
| `NOT_FOUND` | 404 | Resource does not exist |
| `VALIDATION_ERROR` | 400 | Invalid request body or params |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

### Health Check

| Endpoint | Method | Response |
|----------|--------|----------|
| `GET /api/health` | GET | `{ status: "ok" }` |

No authentication required.

## Database Schema

```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Better Auth requires specific fields on the User model.
// Custom fields (userType) are added via Better Auth's additionalFields config.
model User {
  id            String    @id @default(cuid())
  email         String    @unique
  emailVerified Boolean   @default(false)
  name          String
  image         String?
  userType      String    // parent, autistic_individual, professional, educator, therapist, supporter
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  posts     Post[]
  comments  Comment[]
  reactions Reaction[]

  // Better Auth relations
  sessions Session[]
  accounts Account[]
}

// Better Auth session table
model Session {
  id        String   @id @default(cuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  ipAddress String?
  userAgent String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// Better Auth account table (for OAuth providers in the future)
model Account {
  id                    String    @id @default(cuid())
  userId                String
  accountId             String
  providerId            String
  accessToken           String?
  refreshToken          String?
  accessTokenExpiresAt  DateTime?
  refreshTokenExpiresAt DateTime?
  scope                 String?
  idToken               String?
  password              String?
  createdAt             DateTime  @default(now())
  updatedAt             DateTime  @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// Better Auth verification table (email verification, password reset)
model Verification {
  id         String   @id @default(cuid())
  identifier String
  value      String
  expiresAt  DateTime
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
}

model Post {
  id            String   @id @default(cuid())
  content       String
  tags          String[]
  authorId      String
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  likesCount    Int      @default(0)
  commentsCount Int      @default(0)

  author    User       @relation(fields: [authorId], references: [id])
  comments  Comment[]
  reactions Reaction[]

  @@index([createdAt(sort: Desc)])
}

model Comment {
  id        String   @id @default(cuid())
  content   String
  authorId  String
  postId    String
  createdAt DateTime @default(now())

  author User @relation(fields: [authorId], references: [id])
  post   Post @relation(fields: [postId], references: [id], onDelete: Cascade)

  @@index([postId, createdAt(sort: Desc)])
}

model Reaction {
  id        String   @id @default(cuid())
  authorId  String
  postId    String
  createdAt DateTime @default(now())

  author User @relation(fields: [authorId], references: [id])
  post   Post @relation(fields: [postId], references: [id], onDelete: Cascade)

  @@unique([authorId, postId])
}
```

Key decisions:
- User model includes Better Auth required fields (`emailVerified`, `image`, `sessions`, `accounts`) plus custom `userType`
- Better Auth tables (Session, Account, Verification) are explicitly defined to avoid schema conflicts
- `updatedAt` on Post for future editing support
- Database indexes on `Post.createdAt` and `Comment(postId, createdAt)` for paginated queries
- `likesCount`/`commentsCount` denormalized on Post for fast reads (updated via transaction)
- Cascade delete on comments/reactions when post is deleted
- One reaction per user per post enforced at DB level (`@@unique`)

User types: `parent`, `autistic_individual`, `professional`, `educator`, `therapist`, `supporter`

## Backend Architecture

**Hono app (`src/index.ts`):**
- Mount Better Auth handler on `/api/auth/*` (Better Auth's default path)
- Mount community routes on `/api/posts/*`
- Mount health endpoint on `/api/health`
- Apply CORS middleware (allow `*` in dev, specific origins in prod)
- Apply session middleware to `/api/posts/*` and `/api/me`

**Auth (`src/auth/auth.ts`):**
- Better Auth instance configured with:
  - Prisma adapter (receives edge-configured Prisma client)
  - Email + password provider
  - `user.additionalFields: { userType: { type: "string", required: true } }`
  - Session management via Bearer tokens
- Better Auth's handler is mounted directly on Hono — it handles sign-up, sign-in, sign-out, and session validation internally

**Auth routes (`src/routes/auth.ts`):**
- Mounts Better Auth's built-in handler at `/api/auth/*` using `app.on(["GET", "POST"], "/api/auth/**", ...)`
- Custom `GET /api/me` endpoint that uses Better Auth's `auth.api.getSession()` to return user data with `userType`

**Middleware (`src/middleware/session.ts`):**
- Uses Better Auth's `auth.api.getSession()` to validate the session from request headers
- Attaches user to Hono context variable
- Returns 401 with `{ error: "Not authenticated", code: "UNAUTHORIZED" }` if invalid/missing

**Community routes (`src/routes/community.ts`):**
- Thin route handlers: validate input (Zod), call Prisma, return response
- No service layer for MVP (YAGNI)
- Post delete authorization: check `post.authorId === context.user.id`, return 403 if not author
- Comment delete authorization: check `comment.authorId === context.user.id`, return 403 if not author
- Input validation limits: post content max 5000 chars, comment content max 2000 chars, max 5 tags per post, tags are free-form strings (max 30 chars each)
- Reaction like/unlike in a Prisma transaction: upsert/delete reaction + update `likesCount`

**Cloudflare Workers config (`wrangler.toml`):**
- `DATABASE_URL` as a secret (set via `wrangler secret put`)
- `compatibility_date` set to current
- Uses `@prisma/adapter-neon` with `@neondatabase/serverless` for DB connection

## Flutter Architecture

**State management migration:**
- Wrap app in `ProviderScope` (Riverpod)
- Remove Provider dependency from pubspec

**API client (`shared/api/api_client.dart`):**
- Dio HTTP client
- Base URL from environment/config (localhost for dev, Workers URL for prod)
- Auth interceptor: reads token from secure storage, adds `Authorization: Bearer <token>` header
- Error interceptor: maps API errors to typed exceptions
- Use `flutter_secure_storage` for token persistence (not SharedPreferences)

**Auth flow:**
- `AuthRepository`: HTTP calls to Better Auth endpoints (`/api/auth/sign-up/email`, etc.)
- `AuthProvider` (Riverpod `AsyncNotifier`): manages auth state, persists token via `flutter_secure_storage`, exposes `signUp()`, `signIn()`, `signOut()`, `currentUser`
- Router redirect logic: unauthenticated → `/onboarding`, authenticated → `/home`
- Existing login/signup screens rewired to `AuthProvider`. Signup screen updated to include all 6 user types (`autistic_individual` and `supporter` added to existing 4)

**Community feed:**
- `CommunityRepository`: HTTP calls to `/api/posts/*`
- `FeedProvider` (Riverpod `AsyncNotifier`): paginated feed state with cursor, `loadMore()`, `createPost()`, `deletePost()`
- `FeedScreen`: replaces community placeholder with scrollable post list, pull-to-refresh, infinite scroll
- `PostDetailScreen`: single post with paginated comments
- `PostCard` widget: displays post content, author, tags, like/comment counts, like action
- `CommentList` widget: paginated comment display with add comment

**Dependency changes (pubspec.yaml):**
- Add: `flutter_riverpod`, `dio`, `flutter_secure_storage`
- Remove: `provider`, all Firebase packages (already commented out)
- Keep: everything else

## Testing Strategy (TDD)

### Backend (Vitest)
- Test against a real Neon test database (separate DB or Neon branch)
- Each test file resets DB state via Prisma `deleteMany` in `beforeEach`
- Tests cover:
  - Auth flows: signup (with userType) → signin → get-session → signout
  - Post CRUD: create, list (pagination + cursor), get, delete (own only, 403 for others)
  - Comments: create, list (pagination), delete (own only, 403 for others)
  - Reactions: like (PUT), unlike (DELETE), count updates (transaction correctness)
  - Auth guard: rejects unauthenticated requests with 401
  - Health endpoint: returns `{ status: "ok" }`
  - Input validation: rejects invalid bodies with 400 + VALIDATION_ERROR

### Frontend (flutter_test)
- Repository tests: mock Dio, verify correct request URLs/bodies/headers, verify response parsing
- Provider tests: mock repository, verify state transitions (loading → data → error)
- Widget tests for new screens (feed, post detail, post creation)
- Test helpers: shared mock classes, fixture data matching API contracts

### Contract compliance
- Both sides test against the same API shape defined in `contracts/`
- If a contract changes, tests on both sides should fail
- No code generation from contracts for MVP — manual alignment verified by tests

## Implementation Order

1. **Monorepo restructure** — move Flutter to `frontend/`, create `backend/` and `contracts/`, set up pnpm workspace, update CLAUDE.md to reflect new stack and directory structure
2. **Contracts** — write OpenAPI specs for auth and community
3. **Backend foundation** — Hono + Prisma edge client + Neon setup, health endpoint, **validate Better Auth + Prisma edge compatibility** (fallback to Drizzle if needed)
4. **Backend auth** — Better Auth integration with userType, TDD
5. **Backend community** — Posts/comments/reactions endpoints, TDD
6. **Flutter API layer** — Dio client, secure storage, Riverpod setup
7. **Flutter auth** — Rewire login/signup screens, auth state, router guards
8. **Flutter community** — Feed screen, post detail, post creation
9. **Deploy** — Cloudflare Workers deployment, connect Flutter to live API
