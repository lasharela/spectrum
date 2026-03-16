import { describe, it, expect, beforeEach } from "vitest";
import app from "../../src/index.js";
import { cleanDatabase, prisma } from "../setup.js";

const dbAvailable = !!prisma;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Create a user + session directly in the DB for test auth. */
async function createTestUser(
  overrides: Partial<{
    firstName: string;
    lastName: string;
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
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

/** Convenience: create a promotion via the API and return parsed JSON body. */
async function createPromotion(
  token: string,
  data?: Partial<{
    title: string;
    description: string;
    category: string;
    discount: string;
    store: string;
    brandLogoUrl: string;
    imageUrl: string;
    expiresAt: string;
    validFrom: string;
    organizationId: string;
  }>
) {
  const res = await app.request("/api/promotions", {
    method: "POST",
    headers: authHeaders(token),
    body: JSON.stringify({
      title: data?.title ?? "Test Promotion",
      category: data?.category ?? "Discounts",
      store: data?.store ?? "Test Store",
      ...(data?.description !== undefined ? { description: data.description } : {}),
      ...(data?.discount !== undefined ? { discount: data.discount } : {}),
      ...(data?.brandLogoUrl !== undefined ? { brandLogoUrl: data.brandLogoUrl } : {}),
      ...(data?.imageUrl !== undefined ? { imageUrl: data.imageUrl } : {}),
      ...(data?.expiresAt !== undefined ? { expiresAt: data.expiresAt } : {}),
      ...(data?.validFrom !== undefined ? { validFrom: data.validFrom } : {}),
      ...(data?.organizationId !== undefined
        ? { organizationId: data.organizationId }
        : {}),
    }),
  });
  return { res, body: (await res.json()) as any };
}

/** Like a promotion via the API. */
async function likePromotion(token: string, promotionId: string) {
  const res = await app.request(`/api/promotions/${promotionId}/reactions`, {
    method: "PUT",
    headers: authHeaders(token),
  });
  return { res, body: (await res.json()) as any };
}

/** Unlike a promotion via the API. */
async function unlikePromotion(token: string, promotionId: string) {
  const res = await app.request(`/api/promotions/${promotionId}/reactions`, {
    method: "DELETE",
    headers: authHeaders(token),
  });
  return { res, body: (await res.json()) as any };
}

// ---------------------------------------------------------------------------
// Promotions API — POST /api/promotions (create)
// ---------------------------------------------------------------------------

describe("Promotions API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  describe("POST /api/promotions", () => {
    it.skipIf(!dbAvailable)(
      "should create promotion with valid data, returns 201",
      async () => {
        const { token } = await createTestUser();
        const { res, body } = await createPromotion(token, {
          title: "20% Off Sensory Toys",
          description: "Great deal on sensory items",
          category: "Discounts",
          discount: "20%",
          store: "Sensory Shop",
        });

        expect(res.status).toBe(201);
        expect(body.promotion).toBeDefined();
        expect(body.promotion.title).toBe("20% Off Sensory Toys");
        expect(body.promotion.description).toBe("Great deal on sensory items");
        expect(body.promotion.category).toBe("Discounts");
        expect(body.promotion.discount).toBe("20%");
        expect(body.promotion.store).toBe("Sensory Shop");
        expect(body.promotion.likesCount).toBe(0);
        expect(body.promotion.liked).toBe(false);
        expect(body.promotion.claimed).toBe(false);
        expect(body.promotion.saved).toBe(false);
        expect(body.promotion.createdBy).toBeDefined();
        expect(body.promotion.createdBy.name).toBe("Test User");
        expect(body.promotion.id).toBeDefined();
        expect(body.promotion.createdAt).toBeDefined();
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/promotions", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            title: "No Auth Promo",
            category: "Discounts",
            store: "Some Store",
          }),
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject invalid data (missing title) with 400",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/promotions", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            // title is missing
            category: "Discounts",
            store: "Some Store",
          }),
        });

        expect(res.status).toBe(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject invalid data (missing store) with 400",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/promotions", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "Missing Store Promo",
            category: "Discounts",
            // store is missing
          }),
        });

        expect(res.status).toBe(400);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/promotions (list)
  // -------------------------------------------------------------------------

  describe("GET /api/promotions", () => {
    it.skipIf(!dbAvailable)(
      "should return promotions that are not expired (validFrom <= now, expiresAt null or > now)",
      async () => {
        const { token } = await createTestUser();

        // Create a promotion with validFrom in the past (visible)
        const pastDate = new Date(Date.now() - 86_400_000).toISOString();
        await createPromotion(token, {
          title: "Active Promo",
          validFrom: pastDate,
        });

        // Create a promotion with validFrom in the future (hidden)
        const futureDate = new Date(Date.now() + 7 * 86_400_000).toISOString();
        await createPromotion(token, {
          title: "Future Promo",
          validFrom: futureDate,
        });

        // Create a promotion that is already expired (hidden)
        const expiredDate = new Date(Date.now() - 3_600_000).toISOString();
        await createPromotion(token, {
          title: "Expired Promo",
          validFrom: pastDate,
          expiresAt: expiredDate,
        });

        const res = await app.request("/api/promotions", { method: "GET" });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.promotions).toBeDefined();
        // Only the active promo should be returned
        expect(body.promotions.length).toBe(1);
        expect(body.promotions[0].title).toBe("Active Promo");
      }
    );

    it.skipIf(!dbAvailable)(
      "should filter by category",
      async () => {
        const { token } = await createTestUser();

        const pastDate = new Date(Date.now() - 86_400_000).toISOString();
        await createPromotion(token, {
          title: "Discount Promo",
          category: "Discounts",
          validFrom: pastDate,
        });
        await createPromotion(token, {
          title: "Free Promo",
          category: "Freebies",
          validFrom: pastDate,
        });

        const res = await app.request("/api/promotions?category=Discounts", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.promotions.length).toBe(1);
        expect(body.promotions[0].title).toBe("Discount Promo");
        expect(body.promotions[0].category).toBe("Discounts");
      }
    );

    it.skipIf(!dbAvailable)(
      "should support search query ?q=",
      async () => {
        const { token } = await createTestUser();

        const pastDate = new Date(Date.now() - 86_400_000).toISOString();
        await createPromotion(token, {
          title: "Sensory Toy Sale",
          description: "Great toys",
          store: "Toy World",
          validFrom: pastDate,
        });
        await createPromotion(token, {
          title: "Book Discount",
          description: "Educational books",
          store: "Book Haven",
          validFrom: pastDate,
        });

        const res = await app.request("/api/promotions?q=Sensory", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.promotions.length).toBe(1);
        expect(body.promotions[0].title).toBe("Sensory Toy Sale");
      }
    );

    it.skipIf(!dbAvailable)(
      "should paginate with cursor",
      async () => {
        const { token } = await createTestUser();

        const pastDate = new Date(Date.now() - 86_400_000).toISOString();
        // Create 3 promotions
        for (let i = 0; i < 3; i++) {
          await createPromotion(token, {
            title: `Promo ${i + 1}`,
            validFrom: pastDate,
          });
        }

        // First page with limit=2
        const res1 = await app.request("/api/promotions?limit=2", {
          method: "GET",
        });
        expect(res1.status).toBe(200);
        const page1 = (await res1.json()) as any;
        expect(page1.promotions.length).toBe(2);
        expect(page1.nextCursor).toBeDefined();
        expect(page1.nextCursor).not.toBeNull();

        // Second page using cursor
        const res2 = await app.request(
          `/api/promotions?limit=2&cursor=${page1.nextCursor}`,
          { method: "GET" }
        );
        expect(res2.status).toBe(200);
        const page2 = (await res2.json()) as any;
        expect(page2.promotions.length).toBe(1);
        expect(page2.nextCursor).toBeNull();

        // No overlap between pages
        const allIds = [
          ...page1.promotions.map((p: any) => p.id),
          ...page2.promotions.map((p: any) => p.id),
        ];
        expect(new Set(allIds).size).toBe(3);
      }
    );

    it.skipIf(!dbAvailable)(
      "should include liked/claimed/saved status for authenticated users",
      async () => {
        const { token, user } = await createTestUser();

        const pastDate = new Date(Date.now() - 86_400_000).toISOString();
        const { body: created } = await createPromotion(token, {
          title: "Status Promo",
          validFrom: pastDate,
        });
        const promoId = created.promotion.id;

        // Like the promotion
        await likePromotion(token, promoId);

        // Claim the promotion
        await app.request(`/api/promotions/${promoId}/claim`, {
          method: "POST",
          headers: authHeaders(token),
        });

        // Fetch promotions list with auth header
        const res = await app.request("/api/promotions", {
          method: "GET",
          headers: { Authorization: `Bearer ${token}` },
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        const promo = body.promotions.find((p: any) => p.id === promoId);
        expect(promo).toBeDefined();
        expect(promo.liked).toBe(true);
        expect(promo.claimed).toBe(true);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/promotions/:id (single promotion)
  // -------------------------------------------------------------------------

  describe("GET /api/promotions/:id", () => {
    it.skipIf(!dbAvailable)(
      "should return single promotion with createdBy info",
      async () => {
        const { token } = await createTestUser({
          firstName: "Jane",
          lastName: "Doe",
        });
        const { body: created } = await createPromotion(token, {
          title: "Detailed Promo",
          description: "Full description here",
          category: "Discounts",
          discount: "15%",
          store: "Best Store",
        });
        const promoId = created.promotion.id;

        const res = await app.request(`/api/promotions/${promoId}`, {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.promotion).toBeDefined();
        expect(body.promotion.id).toBe(promoId);
        expect(body.promotion.title).toBe("Detailed Promo");
        expect(body.promotion.description).toBe("Full description here");
        expect(body.promotion.category).toBe("Discounts");
        expect(body.promotion.discount).toBe("15%");
        expect(body.promotion.store).toBe("Best Store");
        expect(body.promotion.createdBy).toBeDefined();
        expect(body.promotion.createdBy.name).toBe("Jane Doe");
        expect(body.promotion.likesCount).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent promotion",
      async () => {
        const res = await app.request(
          "/api/promotions/non-existent-id-12345",
          { method: "GET" }
        );
        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Promotion not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // -------------------------------------------------------------------------
  // PUT /api/promotions/:id (update)
  // -------------------------------------------------------------------------

  describe("PUT /api/promotions/:id", () => {
    it.skipIf(!dbAvailable)(
      "should allow owner to update promotion",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Original Title",
          category: "Discounts",
          store: "Old Store",
        });
        const promoId = created.promotion.id;

        const res = await app.request(`/api/promotions/${promoId}`, {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "Updated Title",
            store: "New Store",
          }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.promotion.title).toBe("Updated Title");
        expect(body.promotion.store).toBe("New Store");
        // Category should remain unchanged
        expect(body.promotion.category).toBe("Discounts");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 for non-owner",
      async () => {
        const owner = await createTestUser({ firstName: "Owner" });
        const other = await createTestUser({ firstName: "Other" });

        const { body: created } = await createPromotion(owner.token, {
          title: "Owner's Promo",
        });
        const promoId = created.promotion.id;

        const res = await app.request(`/api/promotions/${promoId}`, {
          method: "PUT",
          headers: authHeaders(other.token),
          body: JSON.stringify({ title: "Hacked Title" }),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );
  });

  // -------------------------------------------------------------------------
  // DELETE /api/promotions/:id
  // -------------------------------------------------------------------------

  describe("DELETE /api/promotions/:id", () => {
    it.skipIf(!dbAvailable)(
      "should allow owner to delete promotion",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Deletable Promo",
        });
        const promoId = created.promotion.id;

        const res = await app.request(`/api/promotions/${promoId}`, {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.success).toBe(true);

        // Verify it's actually gone
        const check = await app.request(`/api/promotions/${promoId}`, {
          method: "GET",
        });
        expect(check.status).toBe(404);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 for non-owner",
      async () => {
        const owner = await createTestUser({ firstName: "Owner" });
        const other = await createTestUser({ firstName: "Other" });

        const { body: created } = await createPromotion(owner.token, {
          title: "Not Yours",
        });
        const promoId = created.promotion.id;

        const res = await app.request(`/api/promotions/${promoId}`, {
          method: "DELETE",
          headers: authHeaders(other.token),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );
  });

  // -------------------------------------------------------------------------
  // Reactions (like/unlike)
  // -------------------------------------------------------------------------

  describe("PUT /api/promotions/:id/reactions", () => {
    it.skipIf(!dbAvailable)(
      "should like promotion and increment likesCount",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Likeable Promo",
        });
        const promoId = created.promotion.id;
        expect(created.promotion.likesCount).toBe(0);

        const { res, body } = await likePromotion(token, promoId);

        expect(res.status).toBe(200);
        expect(body.liked).toBe(true);
        expect(body.likesCount).toBe(1);
      }
    );

    it.skipIf(!dbAvailable)(
      "should be idempotent (liking twice returns same count)",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Double Like Promo",
        });
        const promoId = created.promotion.id;

        // Like once
        const first = await likePromotion(token, promoId);
        expect(first.body.liked).toBe(true);
        expect(first.body.likesCount).toBe(1);

        // Like again — should be idempotent
        const second = await likePromotion(token, promoId);
        expect(second.body.liked).toBe(true);
        expect(second.body.likesCount).toBe(1);
      }
    );
  });

  describe("DELETE /api/promotions/:id/reactions", () => {
    it.skipIf(!dbAvailable)(
      "should unlike promotion and decrement likesCount",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Unlikeable Promo",
        });
        const promoId = created.promotion.id;

        // Like first
        await likePromotion(token, promoId);

        // Then unlike
        const { res, body } = await unlikePromotion(token, promoId);

        expect(res.status).toBe(200);
        expect(body.liked).toBe(false);
        expect(body.likesCount).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should be idempotent when not liked",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Never Liked Promo",
        });
        const promoId = created.promotion.id;

        // Unlike without having liked — should be idempotent
        const { res, body } = await unlikePromotion(token, promoId);

        expect(res.status).toBe(200);
        expect(body.liked).toBe(false);
        expect(body.likesCount).toBe(0);
      }
    );
  });

  // -------------------------------------------------------------------------
  // POST /:id/claim
  // -------------------------------------------------------------------------

  describe("POST /api/promotions/:id/claim", () => {
    it.skipIf(!dbAvailable)(
      "should claim promotion, returns claimed: true",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Claimable Promo",
        });
        const promoId = created.promotion.id;

        const res = await app.request(`/api/promotions/${promoId}/claim`, {
          method: "POST",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.claimed).toBe(true);
      }
    );

    it.skipIf(!dbAvailable)(
      "should be idempotent (claiming again returns claimed: true)",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPromotion(token, {
          title: "Idempotent Claim Promo",
        });
        const promoId = created.promotion.id;

        // Claim once
        const first = await app.request(`/api/promotions/${promoId}/claim`, {
          method: "POST",
          headers: authHeaders(token),
        });
        const firstBody = (await first.json()) as any;
        expect(firstBody.claimed).toBe(true);

        // Claim again — should be idempotent
        const second = await app.request(`/api/promotions/${promoId}/claim`, {
          method: "POST",
          headers: authHeaders(token),
        });
        const secondBody = (await second.json()) as any;
        expect(secondBody.claimed).toBe(true);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent promotion",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request(
          "/api/promotions/non-existent-id-12345/claim",
          {
            method: "POST",
            headers: authHeaders(token),
          }
        );

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Promotion not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });
});
