# Phase 8: Missing Tests Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add comprehensive backend and frontend tests for features that currently lack test coverage — events, promotions, catalog, saved items, and filters.

**Architecture:** Backend tests follow the existing `community.test.ts` pattern: Vitest + direct `app.request()` against the Hono app with DB helpers. Frontend tests follow the existing pattern: `flutter_test` + `ProviderScope` overrides with `FTheme(data: AppForuiTheme.light)` wrapping.

**Tech Stack:** Vitest (backend), flutter_test + flutter_riverpod (frontend), Prisma (test DB)

---

## Chunk 1: Backend Test Infrastructure & Events Tests

### Task 1: Update test setup for new models

**Files:**
- Modify: `backend/test/setup.ts`

- [ ] **Step 1: Read current setup.ts and understand cleanup order**

The current `cleanDatabase()` only cleans Post-related models. We need to add cleanup for all new models (events, promotions, catalog, saved items, roles).

- [ ] **Step 2: Update cleanDatabase to handle all models**

```typescript
export async function cleanDatabase() {
  if (!prisma) return;
  // Delete in dependency order (children before parents)
  await prisma.promotionClaim.deleteMany();
  await prisma.promotionReaction.deleteMany();
  await prisma.promotion.deleteMany();
  await prisma.eventAttendee.deleteMany();
  await prisma.event.deleteMany();
  await prisma.savedItem.deleteMany();
  await prisma.rating.deleteMany();
  await prisma.organization.deleteMany();
  await prisma.reaction.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.post.deleteMany();
  await prisma.userRole.deleteMany();
  await prisma.session.deleteMany();
  await prisma.account.deleteMany();
  await prisma.verification.deleteMany();
  await prisma.user.deleteMany();
}
```

- [ ] **Step 3: Run existing tests to verify nothing breaks**

Run: `pnpm test:backend`
Expected: All existing tests pass.

- [ ] **Step 4: Commit**

```bash
git add backend/test/setup.ts
git commit -m "test: update cleanDatabase to handle all models"
```

### Task 2: Events API tests

**Files:**
- Create: `backend/test/routes/events.test.ts`

This test file covers: list events, get single event, create event, update event, delete event, RSVP/un-RSVP, and admin approve/reject.

**Test helper pattern** (reuse from `community.test.ts`):

```typescript
import { describe, it, expect, beforeEach } from "vitest";
import app from "../../src/index.js";
import { cleanDatabase, prisma } from "../setup.js";

const dbAvailable = !!prisma;

async function createTestUser(
  overrides: Partial<{ firstName: string; lastName: string; userType: string }> = {}
) {
  const uid = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const user = await prisma!.user.create({
    data: {
      email: `test-${uid}@test.com`,
      name: `${overrides.firstName ?? "Test"} ${overrides.lastName ?? "User"}`,
      firstName: overrides.firstName ?? "Test",
      lastName: overrides.lastName ?? "User",
      userType: overrides.userType ?? "parent",
      emailVerified: false,
    },
  });
  const session = await prisma!.session.create({
    data: {
      userId: user.id,
      token: `test-token-${uid}`,
      expiresAt: new Date(Date.now() + 86_400_000),
    },
  });
  return { user, token: session.token };
}

function authHeaders(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}`, "Content-Type": "application/json" };
}

async function grantAdmin(userId: string) {
  await prisma!.userRole.create({
    data: { userId, role: "ADMIN" },
  });
}
```

- [ ] **Step 1: Write tests for POST /api/events (create)**

Tests:
- Creates event with valid data, returns 201 with status "pending"
- Rejects unauthenticated with 401
- Rejects invalid data (missing title) with 400

- [ ] **Step 2: Run tests to verify they fail (no setup issues)**

Run: `pnpm test:backend -- --grep "Events API"`
Expected: Tests fail because of test structure, not DB issues.

- [ ] **Step 3: Write tests for GET /api/events (list)**

Tests:
- Returns only approved events by default
- Supports `?mine=true` to return user's events regardless of status
- Filters by category
- Supports search query `?q=`
- Paginates with cursor

- [ ] **Step 4: Write tests for GET /api/events/:id**

Tests:
- Returns single event with organizer info
- Returns 404 for non-existent event

- [ ] **Step 5: Write tests for PUT /api/events/:id (update)**

Tests:
- Owner can update their event
- Returns 403 for non-owner
- Returns 404 for non-existent event

- [ ] **Step 6: Write tests for DELETE /api/events/:id**

Tests:
- Owner can delete their event
- Returns 403 for non-owner

- [ ] **Step 7: Write tests for RSVP endpoints**

Tests:
- POST /:id/rsvp creates attendance, returns rsvped: true + count
- POST /:id/rsvp is idempotent
- DELETE /:id/rsvp removes attendance, returns rsvped: false + count
- DELETE /:id/rsvp is idempotent when not attending

- [ ] **Step 8: Write tests for PUT /:id/approve (admin)**

Tests:
- Admin can approve event (status changes to "approved")
- Admin can reject event (status changes to "rejected")
- Non-admin gets 403
- Returns 404 for non-existent event

- [ ] **Step 9: Run all events tests**

Run: `pnpm test:backend`
Expected: All events tests pass.

- [ ] **Step 10: Commit**

```bash
git add backend/test/routes/events.test.ts
git commit -m "test: add Events API test suite"
```

### Task 3: Promotions API tests

**Files:**
- Create: `backend/test/routes/promotions.test.ts`

- [ ] **Step 1: Write tests for POST /api/promotions (create)**

Tests:
- Creates promotion with valid data, returns 201
- Rejects unauthenticated with 401
- Rejects invalid data (missing title, missing store) with 400

- [ ] **Step 2: Write tests for GET /api/promotions (list)**

Tests:
- Returns promotions that are not expired (validFrom <= now, expiresAt null or > now)
- Filters by category
- Supports search query `?q=`
- Paginates with cursor
- Includes liked/claimed/saved status for authenticated users

- [ ] **Step 3: Write tests for GET /api/promotions/:id**

Tests:
- Returns single promotion with createdBy info
- Returns 404 for non-existent promotion

- [ ] **Step 4: Write tests for PUT/DELETE /api/promotions/:id**

Tests:
- Owner can update promotion
- Owner can delete promotion
- Non-owner gets 403 on both

- [ ] **Step 5: Write tests for reactions (like/unlike)**

Tests:
- PUT /:id/reactions likes and increments likesCount
- PUT /:id/reactions is idempotent
- DELETE /:id/reactions unlikes and decrements likesCount
- DELETE /:id/reactions is idempotent when not liked

- [ ] **Step 6: Write tests for POST /:id/claim**

Tests:
- Claims promotion, returns claimed: true
- Claiming again is idempotent
- Returns 404 for non-existent promotion

- [ ] **Step 7: Run all promotions tests**

Run: `pnpm test:backend`
Expected: All promotions tests pass.

- [ ] **Step 8: Commit**

```bash
git add backend/test/routes/promotions.test.ts
git commit -m "test: add Promotions API test suite"
```

### Task 4: Catalog API tests

**Files:**
- Create: `backend/test/routes/catalog.test.ts`

- [ ] **Step 1: Write tests for catalog CRUD**

Tests:
- POST /api/catalog creates organization with valid data (201)
- GET /api/catalog returns paginated organizations
- GET /api/catalog/:id returns single organization
- GET /api/catalog filters by category, ageGroup, specialNeed, search query
- PUT /api/catalog/:id updates organization (owner only, 403 for non-owner)
- DELETE /api/catalog/:id deletes organization (owner only)

- [ ] **Step 2: Write tests for ratings**

Tests:
- PUT /api/catalog/:id/rating creates/updates rating
- Rating recalculates averageRating and ratingCount
- Rating score must be 1-5

- [ ] **Step 3: Run catalog tests**

Run: `pnpm test:backend`
Expected: All catalog tests pass.

- [ ] **Step 4: Commit**

```bash
git add backend/test/routes/catalog.test.ts
git commit -m "test: add Catalog API test suite"
```

### Task 5: Saved items & Filters API tests

**Files:**
- Create: `backend/test/routes/saved.test.ts`
- Create: `backend/test/routes/filters.test.ts`

- [ ] **Step 1: Write saved items tests**

Tests:
- PUT /api/saved saves an item (upsert, idempotent)
- DELETE /api/saved/:itemType/:itemId removes a saved item
- GET /api/saved/catalog returns grouped saved catalog items
- GET /api/saved/event returns grouped saved events
- GET /api/saved/promotion returns grouped saved promotions
- Returns empty groups when nothing saved

- [ ] **Step 2: Write filters tests**

Tests:
- GET /api/filters/catalog-categories returns categories ordered by sortOrder
- GET /api/filters/age-groups returns age groups
- GET /api/filters/special-needs returns special needs
- GET /api/filters/event-categories returns event categories
- GET /api/filters/promotion-categories returns promotion categories

Note: Filter tests need seed data. Create filter records in beforeEach:
```typescript
await prisma!.catalogCategory.create({ data: { name: "Therapy", sortOrder: 1 } });
```

- [ ] **Step 3: Run all tests**

Run: `pnpm test:backend`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add backend/test/routes/saved.test.ts backend/test/routes/filters.test.ts
git commit -m "test: add Saved Items and Filters API test suites"
```

---

## Chunk 2: Frontend Tests

### Task 6: Promotions domain model tests

**Files:**
- Create: `frontend/test/features/promotions/domain/promotion_test.dart`

- [ ] **Step 1: Write Promotion model tests**

Tests:
- `fromJson` creates a valid Promotion from JSON map
- `fromJson` handles null optional fields (discount, expiresAt, description)
- `copyWith` correctly updates liked/likesCount/saved/claimed
- `isPermanent` returns true when expiresAt is null
- `isExpired` returns true when expiresAt is in the past
- `timeRemaining` returns correct strings ("2d left", "5h left", "30m left", "Expired")

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';

void main() {
  group('Promotion', () {
    final sampleJson = {
      'id': 'promo-1',
      'title': 'Test Promotion',
      'description': 'A test promo',
      'category': 'Health & Wellness',
      'discount': '20% OFF',
      'store': 'Test Store',
      'brandLogoUrl': null,
      'imageUrl': null,
      'expiresAt': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'validFrom': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'organizationId': null,
      'createdById': 'user-1',
      'createdBy': {'id': 'user-1', 'name': 'Test', 'image': null, 'userType': 'parent'},
      'likesCount': 10,
      'liked': false,
      'claimed': false,
      'saved': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    test('fromJson creates valid Promotion', () {
      final promo = Promotion.fromJson(sampleJson);
      expect(promo.id, 'promo-1');
      expect(promo.title, 'Test Promotion');
      expect(promo.discount, '20% OFF');
      expect(promo.store, 'Test Store');
      expect(promo.likesCount, 10);
      expect(promo.liked, false);
    });

    test('isPermanent returns true when expiresAt is null', () {
      final promo = Promotion.fromJson({...sampleJson, 'expiresAt': null});
      expect(promo.isPermanent, true);
    });

    test('isExpired returns true for past expiresAt', () {
      final promo = Promotion.fromJson({
        ...sampleJson,
        'expiresAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      });
      expect(promo.isExpired, true);
    });

    test('copyWith updates fields correctly', () {
      final promo = Promotion.fromJson(sampleJson);
      final updated = promo.copyWith(liked: true, likesCount: 11);
      expect(updated.liked, true);
      expect(updated.likesCount, 11);
      expect(updated.title, promo.title); // unchanged
    });
  });
}
```

- [ ] **Step 2: Run test**

Run: `cd frontend && flutter test test/features/promotions/domain/promotion_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add frontend/test/features/promotions/domain/promotion_test.dart
git commit -m "test: add Promotion domain model tests"
```

### Task 7: Events domain model tests

**Files:**
- Create: `frontend/test/features/events/domain/event_test.dart`

- [ ] **Step 1: Read the Event domain model**

Read: `frontend/lib/features/events/domain/event.dart`
Understand all fields, fromJson, computed properties.

- [ ] **Step 2: Write Event model tests**

Tests:
- `fromJson` parses valid JSON
- `fromJson` handles null optional fields
- `isPast` computed property
- `isHappeningNow` computed property (if exists)
- `formattedDate` / `formattedTime` outputs

- [ ] **Step 3: Run and verify**

Run: `cd frontend && flutter test test/features/events/domain/event_test.dart`

- [ ] **Step 4: Commit**

```bash
git add frontend/test/features/events/domain/event_test.dart
git commit -m "test: add Event domain model tests"
```

### Task 8: Catalog domain model tests

**Files:**
- Create: `frontend/test/features/catalog/domain/place_test.dart`

- [ ] **Step 1: Read the Place/Organization domain model**

Read: `frontend/lib/features/catalog/domain/place.dart` (or similar)

- [ ] **Step 2: Write Place model tests**

Tests:
- `fromJson` parses valid JSON
- `fromJson` handles null optional fields
- Computed properties (distance, rating display, etc.)

- [ ] **Step 3: Run and verify**

Run: `cd frontend && flutter test test/features/catalog/domain/place_test.dart`

- [ ] **Step 4: Commit**

```bash
git add frontend/test/features/catalog/domain/place_test.dart
git commit -m "test: add Place domain model tests"
```

### Task 9: Frontend widget tests for new features

**Files:**
- Create: `frontend/test/features/promotions/presentation/widgets/promotion_card_test.dart`
- Create: `frontend/test/features/events/presentation/widgets/event_card_test.dart`

- [ ] **Step 1: Write PromotionCard widget test**

Test that PromotionCard renders:
- Promotion title
- Store name
- Discount badge (when discount is not null)
- Timer badge (when not permanent)
- Category label
- Like count
- Claim button (when not claimed)
- Claimed badge (when claimed)

Use the `buildTestApp()` helper from `test/helpers/test_utils.dart`.

- [ ] **Step 2: Write EventCard widget test**

Read `event_card.dart` first, then test:
- Event title renders
- Category renders
- Date renders
- Location renders (when not null)
- RSVP button state

- [ ] **Step 3: Run widget tests**

Run: `cd frontend && flutter test test/features/promotions/ test/features/events/`
Expected: All pass.

- [ ] **Step 4: Commit**

```bash
git add frontend/test/features/promotions/ frontend/test/features/events/
git commit -m "test: add PromotionCard and EventCard widget tests"
```

### Task 10: Run full test suite

- [ ] **Step 1: Run all backend tests**

Run: `pnpm test:backend`
Expected: All pass.

- [ ] **Step 2: Run all frontend tests**

Run: `cd frontend && flutter test`
Expected: All pass.

- [ ] **Step 3: Commit any fixes if needed**
