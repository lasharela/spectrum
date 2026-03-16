import { describe, it, expect, beforeEach } from "vitest";
import app from "../../src/index.js";
import { cleanDatabase, prisma } from "../setup.js";

const dbAvailable = !!prisma;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function createTestUser(
  overrides: Partial<{
    firstName: string;
    lastName: string;
    state: string;
    city: string;
    userType: string;
  }> = {}
) {
  const uid = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const user = await prisma!.user.create({
    data: {
      email: `test-${uid}@test.com`,
      name: `${overrides.firstName ?? "Test"} ${overrides.lastName ?? "User"}`,
      firstName: overrides.firstName ?? "Test",
      lastName: overrides.lastName ?? "User",
      userType: overrides.userType ?? "parent",
      state: overrides.state,
      city: overrides.city,
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

async function grantAdmin(userId: string) {
  await prisma!.userRole.create({ data: { userId, role: "ADMIN" } });
}

function authHeaders(token: string): Record<string, string> {
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

// ---------------------------------------------------------------------------
// Task 3: Admin middleware authorization
// ---------------------------------------------------------------------------

describe("Admin Middleware", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  it.skipIf(!dbAvailable)(
    "should return 401 for unauthenticated user",
    async () => {
      const res = await app.request("/api/admin/events/pending", {
        method: "GET",
        headers: { "Content-Type": "application/json" },
      });

      expect(res.status).toBe(401);
      const body = (await res.json()) as any;
      expect(body.error).toBe("Not authenticated");
      expect(body.code).toBe("UNAUTHORIZED");
    }
  );

  it.skipIf(!dbAvailable)(
    "should return 403 for non-admin user",
    async () => {
      const { token } = await createTestUser();

      const res = await app.request("/api/admin/events/pending", {
        method: "GET",
        headers: authHeaders(token),
      });

      expect(res.status).toBe(403);
      const body = (await res.json()) as any;
      expect(body.error).toBe("Admin access required");
      expect(body.code).toBe("FORBIDDEN");
    }
  );

  it.skipIf(!dbAvailable)(
    "should return 200 for admin user",
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

// ---------------------------------------------------------------------------
// Task 4: Admin event management
// ---------------------------------------------------------------------------

describe("Admin Event Management", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  it.skipIf(!dbAvailable)(
    "GET /api/admin/events/pending returns only pending events",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      // Create pending and approved events
      await prisma!.event.create({
        data: {
          title: "Pending Event",
          category: "Workshop",
          startDate: new Date("2026-06-01"),
          status: "pending",
          organizerId: user.id,
        },
      });
      await prisma!.event.create({
        data: {
          title: "Approved Event",
          category: "Workshop",
          startDate: new Date("2026-06-02"),
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
      expect(body.events).toHaveLength(1);
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
          title: "Needs Approval",
          category: "Meetup",
          startDate: new Date("2026-07-01"),
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
      expect(body.event.title).toBe("Needs Approval");
    }
  );

  it.skipIf(!dbAvailable)(
    "PUT /api/admin/events/:id/approve rejects an event",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const event = await prisma!.event.create({
        data: {
          title: "Will Be Rejected",
          category: "Meetup",
          startDate: new Date("2026-07-01"),
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

// ---------------------------------------------------------------------------
// Task 5: Community moderation
// ---------------------------------------------------------------------------

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
          content: "Should be removed",
          authorId: user.id,
        },
      });

      const res = await app.request(`/api/admin/posts/${post.id}`, {
        method: "DELETE",
        headers: authHeaders(token),
      });

      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.success).toBe(true);

      // Verify soft-deleted in DB
      const updated = await prisma!.post.findUnique({
        where: { id: post.id },
      });
      expect(updated).not.toBeNull();
      expect(updated!.deletedAt).not.toBeNull();
    }
  );

  it.skipIf(!dbAvailable)(
    "DELETE /api/admin/comments/:id soft-deletes a comment and decrements commentsCount",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const post = await prisma!.post.create({
        data: {
          title: "Post with comment",
          content: "Content",
          authorId: user.id,
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
      const body = (await res.json()) as any;
      expect(body.success).toBe(true);

      // Verify comment is soft-deleted
      const updatedComment = await prisma!.comment.findUnique({
        where: { id: comment.id },
      });
      expect(updatedComment).not.toBeNull();
      expect(updatedComment!.deletedAt).not.toBeNull();

      // Verify commentsCount decremented
      const updatedPost = await prisma!.post.findUnique({
        where: { id: post.id },
      });
      expect(updatedPost!.commentsCount).toBe(0);
    }
  );

  it.skipIf(!dbAvailable)(
    "GET /api/admin/posts returns all posts including soft-deleted",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      await prisma!.post.create({
        data: {
          title: "Active Post",
          content: "Visible",
          authorId: user.id,
        },
      });

      await prisma!.post.create({
        data: {
          title: "Deleted Post",
          content: "Hidden",
          authorId: user.id,
          deletedAt: new Date(),
        },
      });

      const res = await app.request("/api/admin/posts", {
        method: "GET",
        headers: authHeaders(token),
      });

      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.posts).toHaveLength(2);

      const activePost = body.posts.find(
        (p: any) => p.title === "Active Post"
      );
      const deletedPost = body.posts.find(
        (p: any) => p.title === "Deleted Post"
      );

      expect(activePost.deletedAt).toBeNull();
      expect(deletedPost.deletedAt).not.toBeNull();
    }
  );

  it.skipIf(!dbAvailable)(
    "PUT /api/admin/posts/:id/restore restores a soft-deleted post",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const post = await prisma!.post.create({
        data: {
          title: "Restoring Post",
          content: "Was deleted",
          authorId: user.id,
          deletedAt: new Date(),
        },
      });

      const res = await app.request(`/api/admin/posts/${post.id}/restore`, {
        method: "PUT",
        headers: authHeaders(token),
      });

      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.success).toBe(true);

      // Verify restored in DB
      const updated = await prisma!.post.findUnique({
        where: { id: post.id },
      });
      expect(updated!.deletedAt).toBeNull();
    }
  );
});

// ---------------------------------------------------------------------------
// Task 6: Category CRUD
// ---------------------------------------------------------------------------

describe("Admin Category CRUD", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  it.skipIf(!dbAvailable)(
    "GET /api/admin/categories/catalog returns categories",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      await prisma!.catalogCategory.create({
        data: { name: "Therapy", sortOrder: 1 },
      });
      await prisma!.catalogCategory.create({
        data: { name: "Education", sortOrder: 0 },
      });

      const res = await app.request("/api/admin/categories/catalog", {
        method: "GET",
        headers: authHeaders(token),
      });

      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.categories).toHaveLength(2);
      // Should be ordered by sortOrder
      expect(body.categories[0].name).toBe("Education");
      expect(body.categories[1].name).toBe("Therapy");
    }
  );

  it.skipIf(!dbAvailable)(
    "POST /api/admin/categories/catalog creates a category (201)",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const res = await app.request("/api/admin/categories/catalog", {
        method: "POST",
        headers: authHeaders(token),
        body: JSON.stringify({
          name: "Healthcare",
          icon: "🏥",
          sortOrder: 5,
        }),
      });

      expect(res.status).toBe(201);
      const body = (await res.json()) as any;
      expect(body.category.name).toBe("Healthcare");
      expect(body.category.icon).toBe("🏥");
      expect(body.category.sortOrder).toBe(5);
      expect(body.category.id).toBeDefined();
    }
  );

  it.skipIf(!dbAvailable)(
    "PUT /api/admin/categories/catalog/:id updates a category",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const category = await prisma!.catalogCategory.create({
        data: { name: "Old Name", sortOrder: 0 },
      });

      const res = await app.request(
        `/api/admin/categories/catalog/${category.id}`,
        {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({ name: "New Name", sortOrder: 10 }),
        }
      );

      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.category.name).toBe("New Name");
      expect(body.category.sortOrder).toBe(10);
    }
  );

  it.skipIf(!dbAvailable)(
    "DELETE /api/admin/categories/catalog/:id deletes a category",
    async () => {
      const { user, token } = await createTestUser();
      await grantAdmin(user.id);

      const category = await prisma!.catalogCategory.create({
        data: { name: "To Delete", sortOrder: 0 },
      });

      const res = await app.request(
        `/api/admin/categories/catalog/${category.id}`,
        {
          method: "DELETE",
          headers: authHeaders(token),
        }
      );

      expect(res.status).toBe(200);
      const body = (await res.json()) as any;
      expect(body.success).toBe(true);

      // Verify hard-deleted
      const check = await prisma!.catalogCategory.findUnique({
        where: { id: category.id },
      });
      expect(check).toBeNull();
    }
  );

  // Test all 5 category types return 200
  const categoryTypes = [
    { path: "catalog", model: "catalogCategory" },
    { path: "event", model: "eventCategory" },
    { path: "promotion", model: "promotionCategory" },
    { path: "age-group", model: "ageGroup" },
    { path: "special-need", model: "specialNeed" },
  ];

  for (const { path, model } of categoryTypes) {
    it.skipIf(!dbAvailable)(
      `GET /api/admin/categories/${path} returns 200 for admin`,
      async () => {
        const { user, token } = await createTestUser();
        await grantAdmin(user.id);

        const res = await app.request(`/api/admin/categories/${path}`, {
          method: "GET",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(Array.isArray(body.categories)).toBe(true);
      }
    );
  }
});
