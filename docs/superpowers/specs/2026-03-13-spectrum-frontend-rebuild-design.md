# Spectrum Frontend Rebuild & Backend Expansion — Design Spec

**Date:** 2026-03-13
**Status:** Approved

## Context

Spectrum is a mobile social network for people with autism and their parents/caregivers. The app has two branches:

- **`ana/backup`** — The original Flutter app with full UI screens (Catalog, Events, Promotions, Community, Interactive Map, Notifications, Settings, etc.). All data is hardcoded/mocked. No backend. This is the source of truth for the intended feature set.
- **`development`** — A monorepo rebuild with clean architecture (Riverpod, repositories, data/domain/presentation layers), a Hono + D1 backend, and Better Auth. Has working backend endpoints for auth, posts, comments, and reactions. But many original screens were lost or replaced during the restructure.

**Goal:** Merge the original feature set with the clean architecture, upgrade to Forui for UI consistency, and wire everything to real backend endpoints.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| UI Framework | Forui (verify exact Flutter SDK constraint at implementation time; fallback to Material 3 with shared widgets if Flutter upgrade is blocked) | Modern components, customizable theming, works alongside Material |
| Frontend Architecture | Feature-based clean architecture (data/domain/presentation per feature) | Consistency — every feature gets all layers, even if initially thin |
| Testing Strategy | Critical path TDD (auth, post creation, feed loading) | Focus on flows that matter most, expand coverage later |
| Mocked Data | Replace all with real backend endpoints | Even for features where full spec isn't known, have at least basic CRUD endpoints |
| Branch Strategy | Work on `development`, merge to `main` only for deploy | `main` is auto-deployed to Cloudflare |
| Database | Cloudflare D1 (SQLite-based) via Prisma adapter | Already in use; CLAUDE.md to be updated from outdated "Neon Postgres" reference |

## Architecture

### Frontend Structure

```
frontend/lib/
├── core/
│   ├── constants/           # AppColors, AppStrings
│   ├── router/              # GoRouter configuration
│   ├── themes/              # Forui theme + Material theme bridge
│   └── utils/               # Shared utilities
├── features/
│   ├── auth/
│   │   ├── data/            # AuthRepository
│   │   ├── domain/          # User model
│   │   └── presentation/
│   │       ├── providers/   # AuthNotifier (Riverpod)
│   │       ├── screens/     # Login, Signup, Welcome, ForgotPassword, ResetPassword
│   │       └── widgets/
│   ├── home/
│   │   ├── data/            # HomeRepository (dashboard data)
│   │   ├── domain/          # DashboardSummary model
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/     # HomeScreen (dashboard)
│   │       └── widgets/
│   ├── community/
│   │   ├── data/            # CommunityRepository (posts, comments, reactions)
│   │   ├── domain/          # Post, Comment, Discussion models
│   │   └── presentation/
│   │       ├── providers/   # FeedNotifier
│   │       ├── screens/     # FeedScreen, PostDetailScreen, CommunityScreen (discussions)
│   │       └── widgets/     # PostCard, DiscussionCard
│   ├── catalog/
│   │   ├── data/            # CatalogRepository
│   │   ├── domain/          # Organization, Service models
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/     # CatalogScreen
│   │       └── widgets/
│   ├── events/
│   │   ├── data/            # EventsRepository
│   │   ├── domain/          # Event model
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/     # EventsScreen
│   │       └── widgets/
│   ├── promotions/
│   │   ├── data/            # PromotionsRepository
│   │   ├── domain/          # Promotion model
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/     # PromotionsScreen
│   │       └── widgets/
│   ├── notifications/
│   │   ├── data/            # NotificationsRepository
│   │   ├── domain/          # Notification model
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/     # NotificationsScreen
│   │       └── widgets/
│   ├── map/
│   │   ├── data/            # MapRepository
│   │   ├── domain/          # Location, MapMarker models
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/     # InteractiveMapScreen
│   │       └── widgets/
│   └── profile/
│       ├── data/            # ProfileRepository
│       ├── domain/          # UserProfile, Settings models
│       └── presentation/
│           ├── providers/
│           ├── screens/     # ProfileScreen, SettingsScreen, PersonalInfoScreen, PrivacyScreen
│           └── widgets/
├── shared/
│   ├── widgets/             # AppButton, AppCard, AppTextField, AppErrorWidget, AppLoadingWidget, NavigationShell
│   ├── services/            # ApiClient
│   └── providers/           # apiClientProvider
```

### Feature Renames and Dispositions

- **"Organizations"** (in `development`) → renamed to **"Catalog"**. The existing `features/organizations/` directory and `/organizations` route will be migrated.
- **"Resources"** (stub in `development`) → **removed**. The concept is decomposed into Catalog (services/organizations), Events, and Promotions as separate features.

### Bottom Navigation Layout

4 tabs (same count as current, updated features):

| Tab | Feature | Icon |
|-----|---------|------|
| Home | Dashboard with summary cards linking to Events, Catalog, etc. | home |
| Community | Feed + Discussions | people |
| Catalog | Organizations & Services directory | search/storefront |
| Profile | Profile, Settings, Personal Info, Privacy | person |

Events, Promotions, Notifications, and Map are accessible via Home dashboard cards or in-app navigation (not top-level tabs).

### Backend Expansion

Current endpoints (keep as-is):
- `POST /api/auth/sign-up/email` — Register
- `POST /api/auth/sign-in/email` — Sign in
- `POST /api/auth/sign-out` — Sign out
- `GET /api/auth/get-session` — Get session
- `GET /api/me` — Current user profile
- `GET /api/health` — Health check
- `GET/POST/DELETE /api/posts` — Posts CRUD
- `PUT /api/posts/:id` — Update post (new — currently missing)
- `GET/POST/DELETE /api/posts/:id/comments` — Comments CRUD
- `PUT/DELETE /api/posts/:id/reactions` — Reactions

New endpoints needed:

**Profile:**
- `PUT /api/me` — Update profile (name, image, userType)
- `PUT /api/me/settings` — Update user settings/preferences
- `GET /api/me/settings` — Get user settings

**Catalog (Organizations/Services):**
- `GET /api/catalog` — List organizations (paginated, filterable by category, search via `?q=`)
- `GET /api/catalog/:id` — Get organization details
- `POST /api/catalog` — Create organization (requires `professional` or `educator` userType)
- `PUT /api/catalog/:id` — Update organization (owner only)
- `DELETE /api/catalog/:id` — Delete organization (owner only)

**Events:**
- `GET /api/events` — List events (paginated, filterable by date/category)
- `GET /api/events/:id` — Get event details
- `POST /api/events` — Create event
- `PUT /api/events/:id` — Update event (owner only)
- `DELETE /api/events/:id` — Delete event (owner only)
- `POST /api/events/:id/rsvp` — RSVP to event
- `DELETE /api/events/:id/rsvp` — Cancel RSVP

**Promotions:**
- `GET /api/promotions` — List promotions (paginated, filterable by `?organizationId=`)
- `GET /api/promotions/:id` — Get promotion details
- `POST /api/promotions` — Create promotion
- `PUT /api/promotions/:id` — Update promotion (owner only)
- `DELETE /api/promotions/:id` — Delete promotion (owner only)

**Notifications:**
- `GET /api/notifications` — List user notifications (paginated)
- `PUT /api/notifications/:id/read` — Mark as read
- `PUT /api/notifications/read-all` — Mark all as read
- `DELETE /api/notifications/:id` — Delete notification

**Map/Locations:**
- `GET /api/locations?lat=<float>&lng=<float>&radius=<km>` — Query Organizations by proximity (uses Organization model's lat/lng fields, not a separate model). SQLite uses bounding-box pre-filter with application-level Haversine distance calculation.
- Map feature calls `GET /api/catalog/:id` directly for detail views (no separate `/locations/:id` alias)

**Dashboard:**
- `GET /api/dashboard` — Aggregated dashboard data

Dashboard response schema:
```json
{
  "user": { "name": "string", "userType": "string" },
  "upcomingEvents": { "count": 0, "items": [{ "id": "", "title": "", "startDate": "" }] },
  "unreadNotifications": 0,
  "recentPosts": { "count": 0, "items": [{ "id": "", "content": "", "authorName": "" }] },
  "myRsvps": { "count": 0 }
}
```
- `count` = total across all records; `items` = at most 5 entries (capped summary, not paginated)
- Sub-arrays are summaries — full lists are accessed via their respective endpoints

**Community search:**
- Existing `GET /api/posts` gains `?q=searchTerm` query parameter for search
- Note: SQLite FTS5 is available in D1 but not through Prisma — implement via `prisma.$queryRaw` or fall back to `LIKE`-based search

**Authorization model:** No separate admin role. Write/update/delete permissions use `userType` (e.g., `professional` and `educator` can create catalog entries) combined with ownership checks (only the creator can edit/delete their own records). This keeps it simple and avoids a separate role system.

**Pagination:** All new list endpoints use the same cursor-based pagination pattern as existing posts/comments endpoints: `?cursor=<id>&limit=<1-50>` query parameters, response includes `nextCursor` field.

**OpenAPI Contracts:** New contract files to be added in `contracts/` for each endpoint group:
- `contracts/catalog.yaml`
- `contracts/events.yaml`
- `contracts/promotions.yaml`
- `contracts/notifications.yaml`
- `contracts/profile.yaml`
- `contracts/dashboard.yaml`

**Backend middleware refactor:** Consolidate duplicate Prisma/Auth middleware into a single `app.use("/api/*", ...)` block with the health check route registered above it (already the case).

### Prisma Schema Additions

New models to add alongside existing User, Session, Account, Verification, Post, Comment, Reaction.

**User model additions** (reverse relations):
```prisma
// Add to existing User model:
events          Event[]
notifications   Notification[]
settings        UserSettings?
eventRsvps      EventAttendee[]
organizations   Organization[]
promotions      Promotion[]
```

**New models:**

```prisma
model Organization {
  id          String   @id @default(cuid())
  name        String
  description String?
  category    String
  address     String?
  phone       String?
  email       String?
  website     String?
  imageUrl    String?
  rating      Float?
  features    String   @default("[]") // JSON array
  latitude    Float?
  longitude   Float?
  ownerId     String
  owner       User     @relation(fields: [ownerId], references: [id])
  promotions  Promotion[]
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

model Event {
  id          String   @id @default(cuid())
  title       String
  description String?
  category    String
  location    String?
  startDate   DateTime
  endDate     DateTime?
  imageUrl    String?
  organizerId String
  organizer   User     @relation(fields: [organizerId], references: [id])
  attendees   EventAttendee[]
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@index([startDate])
}

model EventAttendee {
  id        String   @id @default(cuid())
  eventId   String
  event     Event    @relation(fields: [eventId], references: [id], onDelete: Cascade)
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@unique([eventId, userId])
}

model Promotion {
  id             String        @id @default(cuid())
  title          String
  description    String?
  category       String
  discount       String?
  validFrom      DateTime
  validUntil     DateTime?
  imageUrl       String?
  organizationId String?
  organization   Organization? @relation(fields: [organizationId], references: [id], onDelete: SetNull)
  createdById    String
  createdBy      User          @relation(fields: [createdById], references: [id])
  createdAt      DateTime      @default(now())
  updatedAt      DateTime      @updatedAt

  @@index([validFrom])
}

model Notification {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  type      String   // "comment", "like", "event_reminder", "system"
  title     String
  body      String?
  data      String?  // JSON payload for navigation
  read      Boolean  @default(false)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId, createdAt])
}

model UserSettings {
  id                    String   @id @default(cuid())
  userId                String   @unique
  user                  User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  notificationsEnabled  Boolean  @default(true)
  emailNotifications    Boolean  @default(true)
  darkMode              Boolean  @default(false)
  language              String   @default("en")
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
}
```

Note: Index sort order (`sort: Desc`) removed — SQLite/D1 does not support directional indexes in Prisma. Ordering is handled at query time via `orderBy`.

### Shared Widget Library (Forui-based)

Thin wrappers around Forui components that enforce the app's design system:

- **AppButton** — Wraps `FButton`. Variants: primary (cyan), secondary (coral), outlined, text-only. Consistent padding, border radius.
- **AppTextField** — Wraps `FTextField`. Consistent label placement, validation style, filled background.
- **AppCard** — Wraps `FCard`. Consistent elevation, border radius, padding.
- **AppErrorWidget** — Standardized error display with retry action.
- **AppLoadingWidget** — Consistent loading indicator / skeleton.
- **NavigationShell** — Bottom navigation using Forui's `FBottomNavigationBar`.

All screens use these shared widgets instead of raw Material or Forui components directly, ensuring one place to change styling globally.

### Theming

Forui theme configured to match existing palette:
- Primary: Cyan (#4ECDC4)
- Primary Foreground: White
- Secondary: Coral (#FF6B6B)
- Secondary Foreground: White
- Background: #F0F4F8
- Card Background: White
- Text Dark: #2E3A59
- Text Gray: #8B95A7
- Destructive: #FF5252

Material theme bridged via `toApproximateMaterialTheme()` for any Material widgets still in use.

## Phases

### Implementation Order Within Each Phase

Each phase follows this sequence:
1. Define OpenAPI contract for new endpoints
2. Write backend tests (Vitest)
3. Implement backend endpoints
4. Define frontend domain models
5. Implement frontend repository + provider (with tests for critical paths)
6. Build screens with Forui + shared widgets
7. Wire screens to real data

### Phase 1 — Infrastructure
- Upgrade Flutter to latest stable (verify Forui compatibility; fallback to Material 3 shared widgets if blocked)
- Add Forui dependency
- Configure Forui theme to match cyan/coral palette
- Bridge Material theme via `toApproximateMaterialTheme()`
- Build shared widget library: AppButton, AppTextField, AppCard, AppErrorWidget, AppLoadingWidget
- Enforce clean architecture folder structure for all 9 features (create data/domain/presentation directories)
- Set up test infrastructure for critical path TDD
- **Refactor backend middleware into single `app.use("/api/*", ...)` block** (blocking — must complete before any new routes are added in subsequent phases)
- **Fix existing Prisma schema indexes**: remove `sort: Desc` from Post and Comment model indexes for D1 compatibility
- Update CLAUDE.md to reflect D1 instead of Neon Postgres
- Create database seed script with sample data (ported from hardcoded data in ana/backup)

### Phase 2 — Auth
- Rebuild Login, Signup, Welcome/Onboarding screens using Forui + shared widgets
- Add Forgot Password and Reset Password screens (ported from ana/backup, rebuilt with Forui)
- Wire to existing Better Auth backend (endpoints already exist)
- Backend: configure Better Auth password reset (requires email delivery — use Resend or Cloudflare Email Workers)
- OpenAPI: update `contracts/auth.yaml` with password reset endpoints
- Tests: sign up flow, sign in flow, session management

### Phase 3 — Home & Navigation
- Rebuild Home dashboard with Forui (replace all hardcoded data)
- Rebuild bottom navigation (4 tabs: Home, Community, Catalog, Profile)
- Backend: `GET /api/dashboard` endpoint
- OpenAPI: `contracts/dashboard.yaml`
- Wire Home screen to real user data (greeting uses authenticated user name)
- Wire dashboard cards to real counts

### Phase 4 — Community
- Port full Community screen from ana/backup (discussions with tabs, search, replies)
- Rebuild with Forui + clean architecture layers
- Backend: add `?q=` search parameter to existing `GET /api/posts`, add `PUT /api/posts/:id`
- OpenAPI: update `contracts/community.yaml`
- Tests: post creation, feed loading

### Phase 5 — Catalog
- Port Catalog screen from ana/backup
- Rebuild with Forui + clean architecture layers
- Backend: Organization model + CRUD endpoints with ownership checks
- OpenAPI: `contracts/catalog.yaml`
- Wire frontend to real data

### Phase 6 — Events
- Port Events screen from ana/backup
- Rebuild with Forui + clean architecture layers
- Backend: Event + EventAttendee models, CRUD + RSVP endpoints
- OpenAPI: `contracts/events.yaml`
- Wire frontend to real data

### Phase 7 — Promotions
- Port Promotions screen from ana/backup
- Rebuild with Forui + clean architecture layers
- Backend: Promotion model + CRUD endpoints (filterable by organizationId)
- OpenAPI: `contracts/promotions.yaml`
- Wire frontend to real data

### Phase 8 — Profile & Settings
- Rebuild Profile screen with real user data
- Port Settings, Personal Info, Privacy screens from ana/backup
- Rebuild with Forui + clean architecture layers
- Backend: `PUT /api/me`, UserSettings model + endpoints
- OpenAPI: `contracts/profile.yaml`
- Wire frontend to real data

### Phase 9 — Notifications
- Port Notifications screen from ana/backup
- Rebuild with Forui + clean architecture layers
- Backend: Notification model + endpoints
- OpenAPI: `contracts/notifications.yaml`
- Wire frontend to real data

### Phase 10 — Interactive Map
- Port Interactive Map screen from ana/backup
- Rebuild with Forui + clean architecture layers
- Backend: `GET /api/locations` queries Organization model by lat/lng proximity
- Map package candidate: `flutter_map` with OpenStreetMap (no API key required) or `google_maps_flutter` (requires API key)
- Wire frontend to real data

## Screen Inventory

Complete list of screens across both branches, with target status:

| Screen | Source | Feature | Phase |
|--------|--------|---------|-------|
| Login | both branches | auth | 2 |
| Signup | both branches | auth | 2 |
| Welcome/Onboarding | both branches | auth | 2 |
| Forgot Password | ana/backup | auth | 2 |
| Reset Password | ana/backup | auth | 2 |
| Home Dashboard | both branches | home | 3 |
| Main Navigation Shell | both branches | shared | 3 |
| Community/Discussions | ana/backup (full) | community | 4 |
| Feed | development | community | 4 |
| Post Detail | development | community | 4 |
| Catalog | ana/backup (was "catalog_screen") | catalog | 5 |
| Events | ana/backup | events | 6 |
| Promotions | ana/backup | promotions | 7 |
| Profile | both branches | profile | 8 |
| Settings | ana/backup | profile | 8 |
| Personal Info | ana/backup | profile | 8 |
| Privacy | ana/backup | profile | 8 |
| Notifications | ana/backup | notifications | 9 |
| Interactive Map | ana/backup | map | 10 |

## Testing Strategy

**Critical path TDD** — tests written before implementation for these flows:
- Auth: sign up → sign in → session validation → sign out
- Community: create post → view in feed → add comment → like
- Feed: load posts → pagination → refresh

**Implementation order within each phase:**
1. Write backend tests first (Vitest)
2. Implement backend to make tests pass
3. Write frontend repository/provider tests
4. Build UI

Test infrastructure:
- Backend: Vitest with D1 test database
- Frontend: flutter_test with mocked repositories (Riverpod overrides)
- Shared: MockSecureStorage (already exists)

## Data Seeding

A seed script will be created to populate the D1 database with sample data ported from the hardcoded data in `ana/backup`:
- Organizations from the catalog screen
- Sample events
- Sample promotions
- Sample community discussions

This ensures the app has content to display immediately after deployment.

## Out of Scope (for now)
- Direct messaging between users
- User discovery / search / follow
- Push notifications (only in-app notifications)
- Admin panel / admin role system
- Analytics/reporting
- Content moderation tools
- Accessibility audit (will be addressed separately)
- Email delivery for password reset (Phase 2 will configure but may defer full email infrastructure)
