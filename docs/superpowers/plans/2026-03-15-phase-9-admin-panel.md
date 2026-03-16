# Phase 9: Admin Panel Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking. **This phase is TDD-driven: write tests FIRST, then implement.**

**Goal:** Build a hidden `/admin` page with a responsive, web-optimized layout that lets admins manage content — approve/reject events, soft-delete community posts/comments, and CRUD all category/filter types used across the app.

**Architecture:** The admin panel lives entirely within the Flutter app as a new feature module (`features/admin/`). It uses ForUI's `FScaffold` + `FSidebar` for desktop layout and `FBreakpoints` for responsive adaptation. Backend adds new admin-only routes behind an `adminMiddleware`. Posts and comments gain a `deletedAt` field for soft delete — existing queries filter out soft-deleted records. The `UserRole` model already exists (`@@unique([userId, role])`) with `role: "ADMIN"` pattern used in events approval.

**Tech Stack:** Flutter + ForUI (FScaffold, FSidebar, FBreakpoints, FResizable), Riverpod, Hono + Prisma (backend), Vitest (backend tests), flutter_test (frontend tests)

---

## Current State Summary

**Roles:** `UserRole` model exists with `@@unique([userId, role])`. Events route already checks `role: "ADMIN"`. Users can have multiple roles.

**Soft delete:** Does NOT exist yet. Posts and Comments have hard delete only. Need to add `deletedAt DateTime?` field.

**Category models in DB (all manageable):**
- `CatalogCategory` (name, icon, sortOrder)
- `EventCategory` (name, icon, sortOrder)
- `PromotionCategory` (name, icon, sortOrder)
- `AgeGroup` (name, sortOrder)
- `SpecialNeed` (name, sortOrder)

**Events:** Already have `status` field ("pending", "approved", "rejected") and an admin approve endpoint at `PUT /api/events/:id/approve`.

---

## Chunk 1: Backend — Soft Delete & Admin Middleware

### Task 1: Add soft delete to Post and Comment models

**Files:**
- Modify: `backend/src/db/schema.prisma`
- Create migration after schema change

- [ ] **Step 1: Add deletedAt field to Post and Comment models**

In `schema.prisma`, add to the Post model:
```prisma
deletedAt     DateTime?
```

Add to the Comment model:
```prisma
deletedAt     DateTime?
```

- [ ] **Step 2: Generate Prisma client and create migration**

Run: `pnpm --filter backend db:generate`
Run: `pnpm --filter backend db:migrate` (migration name: "add-soft-delete")

- [ ] **Step 3: Verify existing tests still pass**

Run: `pnpm test:backend`
Expected: All pass (no behavior change yet).

- [ ] **Step 4: Commit**

```bash
git add backend/src/db/schema.prisma backend/prisma/
git commit -m "feat(db): add deletedAt field to Post and Comment for soft delete"
```

### Task 2: Update community routes to filter out soft-deleted records

**Files:**
- Modify: `backend/src/routes/community.ts`

- [ ] **Step 1: Write failing test — soft-deleted posts should not appear in list**

Add to `backend/test/routes/community.test.ts`:

```typescript
it.skipIf(!dbAvailable)(
  "should not return soft-deleted posts in list",
  async () => {
    const { token } = await createTestUser();
    const { body: created } = await createPost(token, {
      title: "Will be soft-deleted",
      content: "Hidden post",
    });
    const postId = created.post.id;

    // Soft-delete directly in DB
    await prisma!.post.update({
      where: { id: postId },
      data: { deletedAt: new Date() },
    });

    const res = await app.request("/api/posts", { method: "GET" });
    const body = (await res.json()) as any;
    const ids = body.posts.map((p: any) => p.id);
    expect(ids).not.toContain(postId);
  }
);

it.skipIf(!dbAvailable)(
  "should return 404 for soft-deleted post by ID",
  async () => {
    const { token } = await createTestUser();
    const { body: created } = await createPost(token, {
      title: "Soft-deleted detail",
      content: "Should 404",
    });
    const postId = created.post.id;

    await prisma!.post.update({
      where: { id: postId },
      data: { deletedAt: new Date() },
    });

    const res = await app.request(`/api/posts/${postId}`, { method: "GET" });
    expect(res.status).toBe(404);
  }
);
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `pnpm test:backend`
Expected: The two new tests FAIL (soft-deleted posts still appear).

- [ ] **Step 3: Add `deletedAt: null` filter to all GET queries in community.ts**

In the GET `/` handler, add to `where`:
```typescript
const where: Record<string, unknown> = { deletedAt: null };
```

In the GET `/:id` handler, change findUnique to findFirst with:
```typescript
const post = await prisma.post.findFirst({
  where: { id, deletedAt: null },
  ...
});
```

Also filter comments listing (GET `/:id/comments`):
```typescript
const comments = await prisma.comment.findMany({
  where: { postId, deletedAt: null },
  ...
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pnpm test:backend`
Expected: All tests pass, including the two new soft-delete tests.

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/community.ts backend/test/routes/community.test.ts
git commit -m "feat(community): filter out soft-deleted posts and comments"
```

### Task 3: Create admin middleware

**Files:**
- Create: `backend/src/middleware/admin.ts`

- [ ] **Step 1: Write failing test — admin middleware blocks non-admin**

Create `backend/test/routes/admin.test.ts`:

```typescript
import { describe, it, expect, beforeEach } from "vitest";
import app from "../../src/index.js";
import { cleanDatabase, prisma } from "../setup.js";

const dbAvailable = !!prisma;

// Reuse createTestUser helper pattern from community.test.ts
async function createTestUser(overrides: Partial<{ firstName: string; userType: string }> = {}) {
  const uid = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const user = await prisma!.user.create({
    data: {
      email: `test-${uid}@test.com`,
      name: `${overrides.firstName ?? "Test"} User`,
      firstName: overrides.firstName ?? "Test",
      lastName: "User",
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
  await prisma!.userRole.create({ data: { userId, role: "ADMIN" } });
}

describe("Admin API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  describe("Authorization", () => {
    it.skipIf(!dbAvailable)(
      "should return 403 for non-admin user",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/admin/events/pending", {
          method: "GET",
          headers: authHeaders(token),
        });
        expect(res.status).toBe(403);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 401 for unauthenticated user",
      async () => {
        const res = await app.request("/api/admin/events/pending", {
          method: "GET",
          headers: { "Content-Type": "application/json" },
        });
        expect(res.status).toBe(401);
      }
    );

    it.skipIf(!dbAvailable)(
      "should allow admin user access",
      async () => {
        const { user, token } = await createTestUser();
        await grantAdmin(user.id);
        const res = await app.request("/api/admin/events/pending", {
          method: "GET",
          headers: authHeaders(token),
        });
        expect(res.status).toBe(200);
      }
    );
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `pnpm test:backend`
Expected: Tests fail (no admin routes exist yet).

- [ ] **Step 3: Create admin middleware**

`backend/src/middleware/admin.ts`:

```typescript
import { createMiddleware } from "hono/factory";
import type { AppBindings, AppVariables } from "../types/context.js";

export const adminMiddleware = createMiddleware<{
  Bindings: AppBindings;
  Variables: AppVariables;
}>(async (c, next) => {
  const user = c.get("user");
  if (!user) {
    return c.json({ error: "Not authenticated", code: "UNAUTHORIZED" }, 401);
  }

  const prisma = c.get("prisma");
  const adminRole = await prisma.userRole.findUnique({
    where: {
      userId_role: {
        userId: user.id,
        role: "ADMIN",
      },
    },
  });

  if (!adminRole) {
    return c.json({ error: "Admin access required", code: "FORBIDDEN" }, 403);
  }

  await next();
});
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/middleware/admin.ts backend/test/routes/admin.test.ts
git commit -m "feat(admin): add admin middleware with role check"
```

### Task 4: Admin routes — event management

**Files:**
- Create: `backend/src/routes/admin.ts`
- Modify: `backend/src/index.ts`

- [ ] **Step 1: Write failing tests for admin event endpoints**

Add to `backend/test/routes/admin.test.ts`:

```typescript
describe("Admin Events", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  it.skipIf(!dbAvailable)(
    "GET /api/admin/events/pending returns pending events",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      // Create a pending event directly
      await prisma!.event.create({
        data: {
          title: "Pending Event",
          category: "Workshop",
          startDate: new Date(Date.now() + 86_400_000),
          status: "pending",
          organizerId: user.id,
        },
      });
      // Create an approved event (should not appear)
      await prisma!.event.create({
        data: {
          title: "Approved Event",
          category: "Workshop",
          startDate: new Date(Date.now() + 86_400_000),
          status: "approved",
          organizerId: user.id,
        },
      });

      const res = await app.request("/api/admin/events/pending", {
        method: "GET",
        headers: authHeaders(token),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.events.length).toBe(1);
      expect(body.events[0].title).toBe("Pending Event");
      expect(body.events[0].status).toBe("pending");
    }
  );

  it.skipIf(!dbAvailable)(
    "PUT /api/admin/events/:id/approve approves an event",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const event = await prisma!.event.create({
        data: {
          title: "To Approve",
          category: "Workshop",
          startDate: new Date(Date.now() + 86_400_000),
          status: "pending",
          organizerId: user.id,
        },
      });

      const res = await app.request(`/api/admin/events/${event.id}/approve`, {
        method: "PUT",
        headers: authHeaders(token),
        body: JSON.stringify({ status: "approved" }),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.event.status).toBe("approved");
    }
  );

  it.skipIf(!dbAvailable)(
    "PUT /api/admin/events/:id/approve rejects an event",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const event = await prisma!.event.create({
        data: {
          title: "To Reject",
          category: "Workshop",
          startDate: new Date(Date.now() + 86_400_000),
          status: "pending",
          organizerId: user.id,
        },
      });

      const res = await app.request(`/api/admin/events/${event.id}/approve`, {
        method: "PUT",
        headers: authHeaders(token),
        body: JSON.stringify({ status: "rejected" }),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.event.status).toBe("rejected");
    }
  );
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `pnpm test:backend`

- [ ] **Step 3: Implement admin routes for events**

Create `backend/src/routes/admin.ts`:

```typescript
import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { sessionMiddleware } from "../middleware/session.js";
import { adminMiddleware } from "../middleware/admin.js";
import type { AppBindings, AppVariables } from "../types/context.js";

const approveSchema = z.object({
  status: z.enum(["approved", "rejected"]),
});

export function adminRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // All admin routes require auth + admin role
  app.use("*", sessionMiddleware, adminMiddleware);

  // GET /events/pending — list pending events
  app.get("/events/pending", async (c) => {
    const prisma = c.get("prisma");
    const events = await prisma.event.findMany({
      where: { status: "pending" },
      orderBy: { createdAt: "desc" },
      include: {
        organizer: {
          select: { id: true, name: true, image: true, userType: true },
        },
        _count: { select: { attendees: true } },
      },
    });

    return c.json({
      events: events.map((e: any) => ({
        id: e.id,
        title: e.title,
        description: e.description,
        category: e.category,
        location: e.location,
        startDate: e.startDate.toISOString(),
        endDate: e.endDate?.toISOString() ?? null,
        imageUrl: e.imageUrl,
        isOnline: e.isOnline,
        isFree: e.isFree,
        price: e.price,
        status: e.status,
        organizer: e.organizer,
        attendeeCount: e._count.attendees,
        createdAt: e.createdAt.toISOString(),
      })),
    });
  });

  // PUT /events/:id/approve — approve or reject event
  app.put("/events/:id/approve", zValidator("json", approveSchema), async (c) => {
    const id = c.req.param("id");
    const prisma = c.get("prisma");
    const { status } = c.req.valid("json");

    const event = await prisma.event.findUnique({ where: { id } });
    if (!event) {
      return c.json({ error: "Event not found", code: "NOT_FOUND" }, 404);
    }

    const updated = await prisma.event.update({
      where: { id },
      data: { status },
      include: {
        organizer: {
          select: { id: true, name: true, image: true, userType: true },
        },
        _count: { select: { attendees: true } },
      },
    });

    return c.json({
      event: {
        id: updated.id,
        title: (updated as any).title,
        status: (updated as any).status,
        organizer: (updated as any).organizer,
        createdAt: (updated as any).createdAt.toISOString(),
      },
    });
  });

  return app;
}
```

Register in `backend/src/index.ts`:
```typescript
import { adminRoutes } from "./routes/admin.js";
// ...
app.route("/api/admin", adminRoutes());
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pnpm test:backend`
Expected: All admin event tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/admin.ts backend/src/index.ts backend/test/routes/admin.test.ts
git commit -m "feat(admin): add admin event management routes"
```

### Task 5: Admin routes — soft-delete community content

**Files:**
- Modify: `backend/src/routes/admin.ts`
- Modify: `backend/test/routes/admin.test.ts`

- [ ] **Step 1: Write failing tests for admin soft-delete**

```typescript
describe("Admin Community Moderation", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  it.skipIf(!dbAvailable)(
    "DELETE /api/admin/posts/:id soft-deletes a post",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const post = await prisma!.post.create({
        data: {
          title: "Bad Post",
          content: "Inappropriate content",
          authorId: user.id,
          category: "General",
        },
      });

      const res = await app.request(`/api/admin/posts/${post.id}`, {
        method: "DELETE",
        headers: authHeaders(token),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.success).toBe(true);

      // Post still exists in DB but has deletedAt set
      const dbPost = await prisma!.post.findUnique({ where: { id: post.id } });
      expect(dbPost).not.toBeNull();
      expect(dbPost!.deletedAt).not.toBeNull();

      // Post no longer appears in public API
      const listRes = await app.request("/api/posts", { method: "GET" });
      const listBody = (await listRes.json()) as any;
      expect(listBody.posts.map((p: any) => p.id)).not.toContain(post.id);
    }
  );

  it.skipIf(!dbAvailable)(
    "DELETE /api/admin/comments/:id soft-deletes a comment",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const post = await prisma!.post.create({
        data: {
          title: "Post",
          content: "Content",
          authorId: user.id,
          category: "General",
          commentsCount: 1,
        },
      });

      const comment = await prisma!.comment.create({
        data: {
          content: "Bad comment",
          authorId: user.id,
          postId: post.id,
        },
      });

      const res = await app.request(`/api/admin/comments/${comment.id}`, {
        method: "DELETE",
        headers: authHeaders(token),
      });
      expect(res.status).toBe(200);

      // Comment still exists but soft-deleted
      const dbComment = await prisma!.comment.findUnique({ where: { id: comment.id } });
      expect(dbComment!.deletedAt).not.toBeNull();

      // commentsCount decremented
      const dbPost = await prisma!.post.findUnique({ where: { id: post.id } });
      expect(dbPost!.commentsCount).toBe(0);
    }
  );

  it.skipIf(!dbAvailable)(
    "GET /api/admin/posts returns all posts including soft-deleted",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      await prisma!.post.create({
        data: { title: "Active", content: "Visible", authorId: user.id, category: "General" },
      });
      await prisma!.post.create({
        data: {
          title: "Deleted",
          content: "Hidden",
          authorId: user.id,
          category: "General",
          deletedAt: new Date(),
        },
      });

      const res = await app.request("/api/admin/posts", {
        method: "GET",
        headers: authHeaders(token),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.posts.length).toBe(2);
      // Should include deletedAt in response
      const deleted = body.posts.find((p: any) => p.title === "Deleted");
      expect(deleted.deletedAt).not.toBeNull();
    }
  );

  it.skipIf(!dbAvailable)(
    "PUT /api/admin/posts/:id/restore restores a soft-deleted post",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const post = await prisma!.post.create({
        data: {
          title: "Restore Me",
          content: "Was deleted",
          authorId: user.id,
          category: "General",
          deletedAt: new Date(),
        },
      });

      const res = await app.request(`/api/admin/posts/${post.id}/restore`, {
        method: "PUT",
        headers: authHeaders(token),
      });
      expect(res.status).toBe(200);

      const dbPost = await prisma!.post.findUnique({ where: { id: post.id } });
      expect(dbPost!.deletedAt).toBeNull();
    }
  );
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `pnpm test:backend`

- [ ] **Step 3: Implement admin community moderation routes**

Add to `backend/src/routes/admin.ts`:

```typescript
// GET /posts — list all posts (including soft-deleted) for moderation
app.get("/posts", async (c) => { ... });

// DELETE /posts/:id — soft-delete a post
app.delete("/posts/:id", async (c) => {
  const id = c.req.param("id");
  const prisma = c.get("prisma");
  const post = await prisma.post.findUnique({ where: { id } });
  if (!post) return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
  await prisma.post.update({ where: { id }, data: { deletedAt: new Date() } });
  return c.json({ success: true });
});

// PUT /posts/:id/restore — restore soft-deleted post
app.put("/posts/:id/restore", async (c) => {
  const id = c.req.param("id");
  const prisma = c.get("prisma");
  await prisma.post.update({ where: { id }, data: { deletedAt: null } });
  return c.json({ success: true });
});

// DELETE /comments/:id — soft-delete a comment (decrement parent post commentsCount)
app.delete("/comments/:id", async (c) => {
  const id = c.req.param("id");
  const prisma = c.get("prisma");
  const comment = await prisma.comment.findUnique({ where: { id } });
  if (!comment) return c.json({ error: "Comment not found", code: "NOT_FOUND" }, 404);
  await prisma.$transaction([
    prisma.comment.update({ where: { id }, data: { deletedAt: new Date() } }),
    prisma.post.update({
      where: { id: comment.postId },
      data: { commentsCount: { decrement: 1 } },
    }),
  ]);
  return c.json({ success: true });
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pnpm test:backend`

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/admin.ts backend/test/routes/admin.test.ts
git commit -m "feat(admin): add community moderation with soft delete and restore"
```

### Task 6: Admin routes — category CRUD

**Files:**
- Modify: `backend/src/routes/admin.ts`
- Modify: `backend/test/routes/admin.test.ts`

All 5 category-like models follow the same schema pattern: `{ id, name (unique), icon?, sortOrder, updatedAt }`. Build a generic handler factory.

- [ ] **Step 1: Write failing tests for category CRUD**

```typescript
describe("Admin Categories", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  // Test one category type thoroughly, others follow same pattern
  it.skipIf(!dbAvailable)(
    "GET /api/admin/categories/catalog returns all catalog categories",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      await prisma!.catalogCategory.create({ data: { name: "Therapy", sortOrder: 1 } });
      await prisma!.catalogCategory.create({ data: { name: "Education", sortOrder: 2 } });

      const res = await app.request("/api/admin/categories/catalog", {
        method: "GET",
        headers: authHeaders(token),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.categories.length).toBe(2);
      expect(body.categories[0].name).toBe("Therapy"); // sorted by sortOrder
    }
  );

  it.skipIf(!dbAvailable)(
    "POST /api/admin/categories/catalog creates a category",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const res = await app.request("/api/admin/categories/catalog", {
        method: "POST",
        headers: authHeaders(token),
        body: JSON.stringify({ name: "New Category", icon: "🏥", sortOrder: 5 }),
      });
      expect(res.status).toBe(201);
      const body = (await res.json()) as any;
      expect(body.category.name).toBe("New Category");
      expect(body.category.icon).toBe("🏥");
    }
  );

  it.skipIf(!dbAvailable)(
    "PUT /api/admin/categories/catalog/:id updates a category",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const cat = await prisma!.catalogCategory.create({
        data: { name: "Old Name", sortOrder: 1 },
      });

      const res = await app.request(`/api/admin/categories/catalog/${cat.id}`, {
        method: "PUT",
        headers: authHeaders(token),
        body: JSON.stringify({ name: "New Name", sortOrder: 3 }),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.category.name).toBe("New Name");
      expect(body.category.sortOrder).toBe(3);
    }
  );

  it.skipIf(!dbAvailable)(
    "DELETE /api/admin/categories/catalog/:id deletes a category",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const cat = await prisma!.catalogCategory.create({
        data: { name: "To Delete", sortOrder: 1 },
      });

      const res = await app.request(`/api/admin/categories/catalog/${cat.id}`, {
        method: "DELETE",
        headers: authHeaders(token),
      });
      expect(res.status).toBe(200);

      const check = await prisma!.catalogCategory.findUnique({ where: { id: cat.id } });
      expect(check).toBeNull();
    }
  );

  // Verify all 5 category types work
  for (const type of ["catalog", "event", "promotion", "age-group", "special-need"]) {
    it.skipIf(!dbAvailable)(
      `GET /api/admin/categories/${type} returns 200 for admin`,
      async () => {
        const { user, token } = await createTestUser();
        await grantAdmin(user.id);

        const res = await app.request(`/api/admin/categories/${type}`, {
          method: "GET",
          headers: authHeaders(token),
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.categories).toBeDefined();
        expect(Array.isArray(body.categories)).toBe(true);
      }
    );
  }
});
```

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement category CRUD routes**

In `backend/src/routes/admin.ts`, create a helper that returns a Hono sub-app for a given Prisma model:

```typescript
const categorySchema = z.object({
  name: z.string().min(1).max(100),
  icon: z.string().max(10).optional(),
  sortOrder: z.number().int().default(0),
});

function categoryRoutes(
  modelName: "catalogCategory" | "eventCategory" | "promotionCategory" | "ageGroup" | "specialNeed"
) {
  const sub = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  sub.get("/", async (c) => {
    const prisma = c.get("prisma");
    const categories = await (prisma[modelName] as any).findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ categories });
  });

  sub.post("/", zValidator("json", categorySchema), async (c) => {
    const prisma = c.get("prisma");
    const body = c.req.valid("json");
    const category = await (prisma[modelName] as any).create({ data: body });
    return c.json({ category }, 201);
  });

  sub.put("/:id", zValidator("json", categorySchema.partial()), async (c) => {
    const id = c.req.param("id");
    const prisma = c.get("prisma");
    const body = c.req.valid("json");
    const category = await (prisma[modelName] as any).update({
      where: { id },
      data: body,
    });
    return c.json({ category });
  });

  sub.delete("/:id", async (c) => {
    const id = c.req.param("id");
    const prisma = c.get("prisma");
    await (prisma[modelName] as any).delete({ where: { id } });
    return c.json({ success: true });
  });

  return sub;
}

// Register all category types
app.route("/categories/catalog", categoryRoutes("catalogCategory"));
app.route("/categories/event", categoryRoutes("eventCategory"));
app.route("/categories/promotion", categoryRoutes("promotionCategory"));
app.route("/categories/age-group", categoryRoutes("ageGroup"));
app.route("/categories/special-need", categoryRoutes("specialNeed"));
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pnpm test:backend`

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/admin.ts backend/test/routes/admin.test.ts
git commit -m "feat(admin): add CRUD routes for all category/filter types"
```

---

## Chunk 2: Frontend — Admin Panel UI

### Task 7: Admin repository and provider

**Files:**
- Create: `frontend/lib/features/admin/data/admin_repository.dart`
- Create: `frontend/lib/features/admin/presentation/providers/admin_provider.dart`

- [ ] **Step 1: Write unit tests for admin repository**

Create `frontend/test/features/admin/data/admin_repository_test.dart`:

Test that the repository correctly constructs API calls:
- `getPendingEvents()` calls GET `/api/admin/events/pending`
- `approveEvent(id, status)` calls PUT `/api/admin/events/:id/approve`
- `getPosts()` calls GET `/api/admin/posts`
- `softDeletePost(id)` calls DELETE `/api/admin/posts/:id`
- `restorePost(id)` calls PUT `/api/admin/posts/:id/restore`
- `softDeleteComment(id)` calls DELETE `/api/admin/comments/:id`
- `getCategories(type)` calls GET `/api/admin/categories/:type`
- `createCategory(type, data)` calls POST `/api/admin/categories/:type`
- `updateCategory(type, id, data)` calls PUT `/api/admin/categories/:type/:id`
- `deleteCategory(type, id)` calls DELETE `/api/admin/categories/:type/:id`

- [ ] **Step 2: Create admin repository**

```dart
import 'package:spectrum_app/shared/services/api_client.dart';

class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  // Events
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final res = await _api.get('/api/admin/events/pending');
    return List<Map<String, dynamic>>.from(res['events']);
  }

  Future<void> approveEvent(String id, String status) async {
    await _api.put('/api/admin/events/$id/approve', data: {'status': status});
  }

  // Posts (moderation)
  Future<List<Map<String, dynamic>>> getPosts({String? cursor, int limit = 20}) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null) params['cursor'] = cursor;
    final res = await _api.get('/api/admin/posts', queryParameters: params);
    return List<Map<String, dynamic>>.from(res['posts']);
  }

  Future<void> softDeletePost(String id) async {
    await _api.delete('/api/admin/posts/$id');
  }

  Future<void> restorePost(String id) async {
    await _api.put('/api/admin/posts/$id/restore');
  }

  Future<void> softDeleteComment(String id) async {
    await _api.delete('/api/admin/comments/$id');
  }

  // Categories (generic)
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final res = await _api.get('/api/admin/categories/$type');
    return List<Map<String, dynamic>>.from(res['categories']);
  }

  Future<Map<String, dynamic>> createCategory(String type, Map<String, dynamic> data) async {
    final res = await _api.post('/api/admin/categories/$type', data: data);
    return Map<String, dynamic>.from(res['category']);
  }

  Future<Map<String, dynamic>> updateCategory(String type, String id, Map<String, dynamic> data) async {
    final res = await _api.put('/api/admin/categories/$type/$id', data: data);
    return Map<String, dynamic>.from(res['category']);
  }

  Future<void> deleteCategory(String type, String id) async {
    await _api.delete('/api/admin/categories/$type/$id');
  }
}
```

- [ ] **Step 3: Create admin providers**

Simple Riverpod providers for each admin section (pending events, posts, categories). Each section is an independent `AsyncNotifier`.

- [ ] **Step 4: Run tests**

Run: `cd frontend && flutter test test/features/admin/`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/admin/ frontend/test/features/admin/
git commit -m "feat(admin): add admin repository and providers"
```

### Task 8: Admin shell — responsive layout with FScaffold + FSidebar

**Files:**
- Create: `frontend/lib/features/admin/presentation/screens/admin_screen.dart`

This is the main admin layout. Uses ForUI's `FScaffold` with `FSidebar` on desktop/tablet, collapses to a bottom tab bar or drawer on mobile.

- [ ] **Step 1: Write widget test for admin screen layout**

Create `frontend/test/features/admin/presentation/screens/admin_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/admin/presentation/screens/admin_screen.dart';

void main() {
  group('AdminScreen', () {
    testWidgets('renders sidebar navigation items', (tester) async {
      // Set a desktop-size window
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FTheme(
              data: AppForuiTheme.light,
              child: const AdminScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify sidebar navigation items exist
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement AdminScreen with responsive layout**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';

enum AdminSection { events, community, categories }

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  AdminSection _selectedSection = AdminSection.events;

  @override
  Widget build(BuildContext context) {
    final breakpoints = context.theme.breakpoints;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= breakpoints.md;

    if (isDesktop) {
      return FScaffold(
        sidebar: FSidebar(
          header: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Admin Panel',
              style: context.theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
                color: context.theme.colors.foreground,
              ),
            ),
          ),
          children: [
            FSidebarGroup(
              label: const Text('Management'),
              children: [
                FSidebarItem(
                  icon: const Icon(Icons.event),
                  label: const Text('Events'),
                  selected: _selectedSection == AdminSection.events,
                  onPress: () => setState(() => _selectedSection = AdminSection.events),
                ),
                FSidebarItem(
                  icon: const Icon(Icons.forum),
                  label: const Text('Community'),
                  selected: _selectedSection == AdminSection.community,
                  onPress: () => setState(() => _selectedSection = AdminSection.community),
                ),
                FSidebarItem(
                  icon: const Icon(Icons.category),
                  label: const Text('Categories'),
                  selected: _selectedSection == AdminSection.categories,
                  onPress: () => setState(() => _selectedSection = AdminSection.categories),
                ),
              ],
            ),
          ],
        ),
        child: _buildContent(),
      );
    }

    // Mobile: use simple tab-based navigation
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: _buildContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedSection.index,
        onDestinationSelected: (i) => setState(() => _selectedSection = AdminSection.values[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.forum), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Categories'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return switch (_selectedSection) {
      AdminSection.events => const AdminEventsView(),
      AdminSection.community => const AdminCommunityView(),
      AdminSection.categories => const AdminCategoriesView(),
    };
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd frontend && flutter test test/features/admin/`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/admin/presentation/screens/admin_screen.dart
git add frontend/test/features/admin/
git commit -m "feat(admin): add responsive admin shell with FSidebar layout"
```

### Task 9: Admin Events view — approve/reject pending events

**Files:**
- Create: `frontend/lib/features/admin/presentation/widgets/admin_events_view.dart`

- [ ] **Step 1: Write widget test**

Test:
- Shows "No pending events" when empty
- Renders event cards with Approve/Reject buttons
- Approve button calls approveEvent
- Reject button calls rejectEvent

- [ ] **Step 2: Implement AdminEventsView**

A list of pending events with Approve/Reject action buttons. Uses `FCard` for each event item with `FButton` for actions.

- [ ] **Step 3: Run tests**

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/admin/presentation/widgets/admin_events_view.dart
git add frontend/test/features/admin/
git commit -m "feat(admin): add admin events approval view"
```

### Task 10: Admin Community view — post/comment moderation

**Files:**
- Create: `frontend/lib/features/admin/presentation/widgets/admin_community_view.dart`

- [ ] **Step 1: Write widget test**

Test:
- Renders posts list with delete/restore indicators
- Shows deletedAt for soft-deleted posts
- Delete button appears for active posts
- Restore button appears for soft-deleted posts

- [ ] **Step 2: Implement AdminCommunityView**

A list of all posts (including soft-deleted). Each post shows title, author, deletedAt status. Actions: Delete (soft), Restore. For desktop, use a data table layout with `FTable` or a card list.

- [ ] **Step 3: Run tests**

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/admin/presentation/widgets/admin_community_view.dart
git add frontend/test/features/admin/
git commit -m "feat(admin): add community moderation view"
```

### Task 11: Admin Categories view — CRUD for all filter types

**Files:**
- Create: `frontend/lib/features/admin/presentation/widgets/admin_categories_view.dart`

- [ ] **Step 1: Write widget test**

Test:
- Shows category type selector (Catalog, Event, Promotion, Age Group, Special Need)
- Lists categories with name, icon, sortOrder
- Add button opens create form
- Edit button opens edit form
- Delete button removes category

- [ ] **Step 2: Implement AdminCategoriesView**

A dropdown or tab selector for category type (catalog, event, promotion, age-group, special-need). Below: a list/table of categories. Each row: name, icon, sortOrder, edit/delete buttons. A "+" FAB or button opens a form dialog (`FDialog`) to create a new category.

Use ForUI's `FTextField` for name input, `FButton` for actions.

- [ ] **Step 3: Run tests**

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/admin/presentation/widgets/admin_categories_view.dart
git add frontend/test/features/admin/
git commit -m "feat(admin): add category management view"
```

### Task 12: Wire admin route into the app router

**Files:**
- Modify: `frontend/lib/core/router/app_router.dart`

- [ ] **Step 1: Write router test**

Add to `frontend/test/core/router/app_router_auth_routes_test.dart` (or create new):

Test that `/admin` route exists and resolves to AdminScreen.

- [ ] **Step 2: Add admin route**

The admin route is NOT in the ShellRoute (no bottom nav bar). It's a standalone route:

```dart
import '../../features/admin/presentation/screens/admin_screen.dart';
// ...
GoRoute(
  path: '/admin',
  name: 'admin',
  builder: (context, state) => const AdminScreen(),
),
```

This route is hidden — no navigation link points to it from the main app. Admin users navigate to it directly via URL or a hidden gesture/button.

- [ ] **Step 3: Run all tests**

Run: `cd frontend && flutter test`
Run: `cd frontend && flutter analyze`

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/core/router/app_router.dart frontend/test/
git commit -m "feat(admin): add /admin route (hidden, no nav link)"
```

### Task 13: Run full test suite — frontend and backend

- [ ] **Step 1: Run all backend tests**

Run: `pnpm test:backend`
Expected: All pass.

- [ ] **Step 2: Run all frontend tests**

Run: `cd frontend && flutter test`
Expected: All pass.

- [ ] **Step 3: Run dart analyze**

Run: `cd frontend && flutter analyze`
Expected: No issues found.

- [ ] **Step 4: Final commit if any fixes needed**
