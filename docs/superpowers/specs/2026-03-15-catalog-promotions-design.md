# Catalog & Promotions Feature Design

**Date:** 2026-03-15
**Status:** Approved

## Context

Spectrum is a mobile social network for people with autism and their parents/caregivers. The app has a working Community feature (feed, posts, comments, reactions) built with clean architecture (Forui, Riverpod, repository pattern, Hono + D1 backend). Community serves as the UI template for new features.

**Source of truth for content/data:** `temp/ana-backup/` (extracted from the `ana/backup` branch) — the original Flutter app with hardcoded catalog (1563 lines) and promotions (974 lines) screens.

**Source of truth for UI patterns:** `frontend/lib/features/community/` — clean architecture with Forui components.

**Execution order:** Catalog first (Phase 5), then Promotions (Phase 7). Each has 3 sub-phases: Frontend UI with mock data → Backend → Wire up.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| UI Framework | Forui (same as Community) | Consistency across app |
| Card component | Reuse Popular Places card from Home | Already exists, avoid duplication |
| Filter UX | Popup with checkboxes (not modal) + badge count on filter icon | Inspired by Community's filter button pattern, adapted for multi-select groups |
| Filter data | DB-driven (admin manages options) | Flexibility to add/remove without app updates |
| Filter chip colors | No per-item colors, use Forui default checkbox style | Keep UI simple |
| Detail screens | Yes for both Catalog and Promotions | MVP flexibility — room for map, ratings, linked content |
| Star rating | Display on card, rate from detail screen only | Keep cards clean, rating is intentional action |
| Saved items | Single shared table (itemType + itemId) | One pattern for both features |
| Saved soft delete | If linked item deleted, saved entry silently hidden | No error for user |
| Expired promotions | Hidden from list automatically | Clean UX; permanent promos use null expiresAt |
| Countdown timer | Reuse/enhance `_formatTimeRemaining` pattern from `PromotionCarousel`; add package only if needed | Matches home carousel behavior, avoids unnecessary dependency |
| Claim Offer | Record in DB table, no extra logic for MVP | Future extensibility |
| Tabs | FTabs two-tab layout (Browse + Saved), icons if easy | Same component as Community tabs |
| Execution order | Catalog first, Promotions reuses patterns | Front-loads harder problems (3-dimension filter, ratings) |

## Architecture

### Shared Foundation

Both features reuse these patterns established by Community:

**Shared Components to Create/Extract:**

- **Place Card** — extract from Home's Popular Places to `shared/widgets/place_card.dart`. Enhanced with optional rating display. Used by Catalog list and Home dashboard. Home card shows subset of fields (no rating); Catalog card shows full fields including rating.
- **Filter Popup Widget** — new `shared/widgets/filter_popup.dart`. Accepts list of filter groups (each = label + list of checkbox options from DB). Shows badge count on trigger button. Returns selected filter IDs. Used by both Catalog (3 groups) and Promotions (1 group).
- **Saved Tab Pattern** — same `FTabs` two-tab layout as Community. Saved tab shows items grouped by category with category icon + name header + count badge.
- **Shared Author Model** — `shared/domain/author.dart`. Single `Author` class with `id`, `name`, `image` (nullable), `userType`. Replaces `PostAuthor`, used by Community, Catalog, and Promotions. `PostAuthor` becomes a typedef or is replaced entirely.
- **Shared PaginatedResult** — extract `PaginatedResult<T>` from `community_repository.dart` to `shared/domain/paginated_result.dart`. Used by all feature repositories.

**Shared Backend Model:**

```prisma
model SavedItem {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  itemType  String   // "catalog" | "promotion"
  itemId    String
  createdAt DateTime @default(now())

  @@unique([userId, itemType, itemId])
  @@index([userId, itemType])
}
```

Soft behavior: if linked item is deleted, saved entry is ignored (not shown, no error thrown).

### Catalog Feature

#### Frontend Structure

```
frontend/lib/features/catalog/
├── domain/
│   ├── place.dart              # Place model
│   ├── place_category.dart     # Category/AgeGroup/SpecialNeed filter models
│   └── place_rating.dart       # Rating model
├── data/
│   └── catalog_repository.dart
└── presentation/
    ├── providers/
    │   └── catalog_provider.dart
    ├── screens/
    │   ├── catalog_screen.dart        # Two tabs: Browse + Saved
    │   └── place_detail_screen.dart   # Full place details
    └── widgets/
        └── place_card.dart            # Thin wrapper or direct use of shared card
```

#### Place Model

Note: The backend Prisma model is called `Organization`. The frontend uses `Place` as the domain model name for UI clarity. The `CatalogRepository.fromJson()` maps `Organization` JSON keys to `Place` fields (e.g., `ownerId` → `ownerId`, `owner` → `Author`).

```dart
class Place {
  final String id;
  final String name;
  final String? description;
  final String category;        // Category name
  final String? address;
  final String? imageUrl;
  final double? rating;         // Average rating (denormalized)
  final int ratingCount;        // Number of ratings
  final List<String> tags;
  final List<String> ageGroups;    // Names from DB filter options
  final List<String> specialNeeds; // Names from DB filter options
  final double? latitude;
  final double? longitude;
  final String ownerId;
  final Author owner;           // Shared Author type from shared/domain/author.dart
  final bool saved;             // Current user's saved state (requires auth, false if anonymous)
  final int? userRating;        // Current user's rating 1-5 (requires auth, null if anonymous)
  final DateTime createdAt;
}
```

#### Browse Tab

- Search bar (same pattern as Community) + filter button with badge count
- Filter popup: 3 groups of checkboxes (Categories, Age Groups, Special Needs) — all options fetched from DB via `/api/filters/*` endpoints
- Cursor-based paginated list of Place cards
- Pull-to-refresh + infinite scroll (same as Community feed)
- Filtering logic: search (text match on name/description/tags) AND category AND age group AND special needs — all must pass if active

#### Saved Tab

- Places grouped by category with category icon + name header + count badge (from backup pattern)
- Each card shows remove/unsave action
- Empty state: "No saved places yet" with bookmark icon

#### Place Card (List View)

Reused from Home Popular Places — simple, clean:
- Icon/image placeholder
- Name
- Short description (2 lines max, ellipsis)
- Rating stars (display only, average)
- Address line
- Category tag

#### Place Detail Screen

- Header: image/icon area, name, category tag
- Full description
- Tags as chips
- Address with "Get Directions" button (opens external maps app)
- Star rating: display average + count, user can rate 1-5
- Save/unsave button
- Future: map preview, linked promotions section

### Promotions Feature

#### Frontend Structure

```
frontend/lib/features/promotions/
├── domain/
│   ├── promotion.dart           # Promotion model
│   └── promotion_category.dart  # Category filter model
├── data/
│   └── promotions_repository.dart
└── presentation/
    ├── providers/
    │   └── promotions_provider.dart
    ├── screens/
    │   ├── promotions_screen.dart        # Two tabs: Browse + Saved
    │   └── promotion_detail_screen.dart  # Full promotion details
    └── widgets/
        └── promotion_card.dart           # List card with discount badge + countdown
```

#### Promotion Model

Aligned with existing `DashboardPromotion` from home carousel:

```dart
class Promotion {
  final String id;
  final String title;
  final String? description;
  final String category;         // Category name
  final String? discount;        // "20% OFF", "FREE", etc.
  final String store;            // Business/brand name
  final String? brandLogoUrl;
  final String? imageUrl;
  final DateTime? expiresAt;     // null = permanent promo (no countdown)
  final DateTime validFrom;
  final String? organizationId;  // Links to Catalog place
  final String createdById;
  final Author createdBy;        // Shared Author type from shared/domain/author.dart
  final int likesCount;
  final bool liked;              // Current user's like state
  final bool saved;              // Current user's saved state (requires auth, false if anonymous)
  final bool claimed;            // Current user's claim state (requires auth, false if anonymous)
  final DateTime createdAt;
}
```

#### Browse Tab

- Search bar + filter button with badge count
- Filter popup: 1 group of checkboxes (Promotion Categories — from DB)
- Cursor-based paginated list of Promotion cards
- Pull-to-refresh + infinite scroll
- Expired promos hidden automatically (backend filters by `expiresAt > now() OR expiresAt IS NULL`)
- Permanent promos (null `expiresAt`) always show, no countdown displayed

#### Promotion Card (List View)

- Discount badge (top-left, pill-shaped, primary color) — visible if `discount` is set
- Brand logo (small avatar) + store name
- Title (2 lines max)
- Countdown timer: days/hours for normal promos, live seconds for time-sensitive (< 24h), hidden for permanent
- Like + Save + Claim buttons row (same layout pattern as Community's like/comment row)

#### Saved Tab

- Promotions grouped by category with icon + name header + count badge
- Remove/unsave action on each card
- Empty state: "No saved offers yet"

#### Promotion Detail Screen

- Header: image area with discount badge overlay
- Brand logo + store name
- Title, full description
- Countdown timer (prominent display)
- Validity info ("Valid from X" / "No expiration")
- Like, Save, Claim action buttons
- Link to organization detail if `organizationId` is set (navigates to Catalog place detail)

#### Home Carousel Integration

- Existing `DashboardPromotion` model gains any missing fields to align with `Promotion`
- Carousel slide tap → navigates to `PromotionDetailScreen`
- Same data source, different visual presentation

## Backend Design

### New Prisma Models

```prisma
// Shared saved items
model SavedItem {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  itemType  String   // "catalog" | "promotion"
  itemId    String
  createdAt DateTime @default(now())

  @@unique([userId, itemType, itemId])
  @@index([userId, itemType])
}

// Catalog star ratings
model Rating {
  id             String       @id @default(cuid())
  userId         String
  user           User         @relation(fields: [userId], references: [id], onDelete: Cascade)
  organizationId String
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  score          Int          // 1-5
  createdAt      DateTime     @default(now())
  updatedAt      DateTime     @updatedAt

  @@unique([userId, organizationId])
}

// Promotion likes
model PromotionReaction {
  id          String    @id @default(cuid())
  authorId    String
  author      User      @relation(fields: [authorId], references: [id], onDelete: Cascade)
  promotionId String
  promotion   Promotion @relation(fields: [promotionId], references: [id], onDelete: Cascade)
  createdAt   DateTime  @default(now())

  @@unique([authorId, promotionId])
}

// Promotion claims (record only, no logic for MVP)
model PromotionClaim {
  id          String    @id @default(cuid())
  userId      String
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  promotionId String
  promotion   Promotion @relation(fields: [promotionId], references: [id], onDelete: Cascade)
  createdAt   DateTime  @default(now())

  @@unique([userId, promotionId])
}

// Admin-managed filter option tables
model CatalogCategory {
  id        String   @id @default(cuid())
  name      String   @unique
  icon      String?
  sortOrder Int      @default(0)
  updatedAt DateTime @updatedAt
}

model AgeGroup {
  id        String   @id @default(cuid())
  name      String   @unique
  sortOrder Int      @default(0)
  updatedAt DateTime @updatedAt
}

model SpecialNeed {
  id        String   @id @default(cuid())
  name      String   @unique
  sortOrder Int      @default(0)
  updatedAt DateTime @updatedAt
}

model PromotionCategory {
  id        String   @id @default(cuid())
  name      String   @unique
  icon      String?
  sortOrder Int      @default(0)
  updatedAt DateTime @updatedAt
}
```

### Organization Model Additions

Beyond what the existing spec defines, add:

```prisma
// Add to existing Organization model:
averageRating Float  @default(0)
ratingCount   Int    @default(0)
ageGroups     String @default("[]")    // JSON array of AgeGroup names
specialNeeds  String @default("[]")    // JSON array of SpecialNeed names
tags          String @default("[]")    // JSON array of strings
ratings       Rating[]

@@index([createdAt])             // For cursor-based pagination
```

**JSON filter query strategy:** Filter matching for `ageGroups` and `specialNeeds` JSON arrays uses SQLite `json_each()` via `prisma.$queryRaw`. Example: `SELECT * FROM Organization WHERE EXISTS (SELECT 1 FROM json_each(Organization.ageGroups) WHERE value = ?)`. This is consistent with the existing `tags` JSON pattern on `Post`.


### Promotion Model Additions

Beyond what the existing spec defines, add:

```prisma
// Add to existing Promotion model:
// Rename validUntil → expiresAt (align with frontend DashboardPromotion model)
expiresAt    DateTime?                 // was validUntil in MVP spec
// validFrom DateTime already exists in base Promotion model from MVP spec
store        String                    // Business/brand name (required — carousel accesses .store[0])
brandLogoUrl String?
likesCount   Int       @default(0)     // Denormalized count
reactions    PromotionReaction[]
claims       PromotionClaim[]

@@index([createdAt])                   // For cursor-based pagination
```

### API Endpoints

#### Catalog

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/api/catalog` | Optional | List places (paginated, `?q=`, `?category=`, `?ageGroup=`, `?specialNeed=`, `?cursor=`, `?limit=`) |
| GET | `/api/catalog/:id` | Optional | Place detail (includes user's rating + saved state if authed) |
| POST | `/api/catalog` | Required | Create place (professional/educator userType only) |
| PUT | `/api/catalog/:id` | Required | Update place (owner only) |
| DELETE | `/api/catalog/:id` | Required | Delete place (owner only) |
| PUT | `/api/catalog/:id/rating` | Required | Rate 1-5 (upsert, updates denormalized averageRating + ratingCount) |

#### Promotions

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/api/promotions` | Optional | List (paginated, `?q=`, `?category=`, hides expired) |
| GET | `/api/promotions/:id` | Optional | Detail (includes user's like/saved/claimed state if authed) |
| POST | `/api/promotions` | Required | Create promotion |
| PUT | `/api/promotions/:id` | Required | Update (owner only) |
| DELETE | `/api/promotions/:id` | Required | Delete (owner only) |
| PUT | `/api/promotions/:id/reactions` | Required | Like |
| DELETE | `/api/promotions/:id/reactions` | Required | Unlike |
| POST | `/api/promotions/:id/claim` | Required | Claim offer (record in DB) |

#### Shared

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| PUT | `/api/saved` | Required | Save item (body: `{itemType, itemId}`) |
| DELETE | `/api/saved/:itemType/:itemId` | Required | Unsave item |
| GET | `/api/saved/:itemType` | Required | List saved items (grouped by category) |

#### Filter Options

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/api/filters/catalog-categories` | None | List catalog categories (sorted by sortOrder) |
| GET | `/api/filters/age-groups` | None | List age groups (sorted by sortOrder) |
| GET | `/api/filters/special-needs` | None | List special needs (sorted by sortOrder) |
| GET | `/api/filters/promotion-categories` | None | List promotion categories (sorted by sortOrder) |

### Authorization Model

Same as existing: no admin role. Write/update/delete use `userType` + ownership checks.
- Catalog: `professional` and `educator` userTypes can create entries
- Promotions: any authenticated user can create (businesses post their own)
- Edit/delete: owner only

### Pagination

Same cursor-based pattern as Community: `?cursor=<id>&limit=<1-50>`, response includes `nextCursor`.

### Promotion Expiry Filtering

Backend query filters: `WHERE (expiresAt > NOW() OR expiresAt IS NULL) AND validFrom <= NOW()`. Permanent promos (null expiresAt) always included. Future-dated promos (validFrom in the future) are hidden until their start date.

### Rating Denormalization Strategy

Rating upserts use a `prisma.$transaction` to ensure consistency:
1. Upsert the `Rating` record (create or update score)
2. Recalculate `averageRating` from `Rating` table using `AVG(score)` (not incremental math)
3. Update `ratingCount` using `COUNT(*)` from `Rating` table
4. Write both values to `Organization`

This avoids race conditions at the cost of one extra aggregate query per rating action.

### Saved Items Response Schema

`GET /api/saved/:itemType` response joins with the source table (Organization or Promotion) to return full item data grouped by category:

```json
{
  "groups": [
    {
      "category": "Therapy",
      "icon": "psychology",
      "count": 3,
      "items": [{ /* full Organization or Promotion object */ }]
    }
  ]
}
```

Items whose source record has been deleted are silently excluded from the response.

### Authenticated vs Anonymous Response

List and detail endpoints use optional auth (same pattern as Community). When authenticated:
- Catalog: response includes `saved` (boolean) and `userRating` (int or null) per item
- Promotions: response includes `saved`, `liked`, `claimed` (all booleans) per item

When anonymous: these fields default to `false` / `null`. Backend conditionally includes the JOIN queries for user-specific state only when a session exists.

## Execution Phases

### Phase 5 — Catalog

**5a: Frontend UI (mock data)**
- Extract shared Author model to `shared/domain/author.dart`, update Community to use it
- Extract PaginatedResult to `shared/domain/paginated_result.dart`, update Community to use it
- Extract Place card to `shared/widgets/place_card.dart` (enhanced with optional rating)
- Create filter popup widget `shared/widgets/filter_popup.dart`
- Place model + mock filter option models
- Catalog provider with mock data
- Catalog screen: Browse tab (search + filter popup + paginated list) + Saved tab (grouped by category)
- Place detail screen (full info + star rating + save + directions)

**5b: Backend**
- OpenAPI contract: `contracts/catalog.yaml`
- Prisma models: Organization additions (averageRating, ratingCount, ageGroups, specialNeeds, tags), Rating, SavedItem, CatalogCategory, AgeGroup, SpecialNeed
- Seed filter option tables with data from backup (9 categories, 6 age groups, 4 special needs)
- Hono routes: catalog CRUD + rating + saved + filter options
- Zod validation schemas
- Vitest tests

**5c: Wire up**
- Catalog repository: replace mock with real API calls
- Connect filter options to DB
- Connect saved/rating actions to backend
- Update router for catalog routes

### Phase 7 — Promotions

**7a: Frontend UI (mock data)**
- Promotion model (aligned with DashboardPromotion)
- Reuse/enhance countdown timer from existing `_formatTimeRemaining` pattern (add package only if needed)
- Promotion card with discount badge + countdown + like/save/claim buttons
- Promotions provider with mock data
- Promotions screen: Browse tab (search + filter popup reuse + paginated list) + Saved tab (grouped by category)
- Promotion detail screen (full info + countdown + like/save/claim + org link)
- Reuse filter popup and saved tab patterns from Phase 5

**7b: Backend**
- OpenAPI contract: `contracts/promotions.yaml`
- Prisma models: PromotionReaction, PromotionClaim, PromotionCategory, Promotion additions (store, brandLogoUrl, likesCount)
- Seed promotion categories from backup (5 categories)
- Hono routes: promotions CRUD + reactions + claims
- Update home dashboard endpoint to support navigation to detail
- Zod validation schemas
- Vitest tests

**7c: Wire up**
- Promotions repository: replace mock with real API calls
- Connect like/save/claim actions to backend
- Link home carousel tap → promotion detail screen
- Hide expired promos (backend filter)
- Update router for promotion routes

### Shared Work (Lands in Phase 5)

- `shared/widgets/filter_popup.dart`
- `shared/widgets/place_card.dart` (extracted from Home, enhanced with optional rating)
- `shared/domain/author.dart` (shared Author model, replaces PostAuthor)
- `shared/domain/paginated_result.dart` (extracted from community_repository.dart)
- SavedItem Prisma model + saved endpoints
- Saved tab grouping pattern
- Filter options endpoints
- Add `@@index([createdAt])` to Organization and Promotion models
