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

// ---------------------------------------------------------------------------
// Saved Items API tests
// ---------------------------------------------------------------------------

describe("Saved Items API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  // -------------------------------------------------------------------------
  // PUT /api/saved (save item — upsert)
  // -------------------------------------------------------------------------

  describe("PUT /api/saved", () => {
    it.skipIf(!dbAvailable)(
      "should save an item (upsert, idempotent)",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        // Create an organization to save
        const org = await prisma!.organization.create({
          data: {
            name: "Saveable Org",
            category: "therapy",
            ownerId: (
              await prisma!.user.findFirst({ where: { email: { contains: "test-" } } })
            )!.id,
          },
        });

        // Save the item
        const res = await app.request("/api/saved", {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            itemType: "catalog",
            itemId: org.id,
          }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.saved).toBeDefined();
        expect(body.saved.itemType).toBe("catalog");
        expect(body.saved.itemId).toBe(org.id);
        expect(body.saved.id).toBeDefined();

        // Save the same item again — should be idempotent
        const res2 = await app.request("/api/saved", {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            itemType: "catalog",
            itemId: org.id,
          }),
        });

        expect(res2.status).toBe(200);
        const body2 = (await res2.json()) as any;
        expect(body2.saved).toBeDefined();
        expect(body2.saved.itemType).toBe("catalog");
        expect(body2.saved.itemId).toBe(org.id);

        // Should still only have one saved item in DB
        const count = await prisma!.savedItem.count({
          where: { itemType: "catalog", itemId: org.id },
        });
        expect(count).toBe(1);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/saved", {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            itemType: "catalog",
            itemId: "some-id",
          }),
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );
  });

  // -------------------------------------------------------------------------
  // DELETE /api/saved/:itemType/:itemId (unsave)
  // -------------------------------------------------------------------------

  describe("DELETE /api/saved/:itemType/:itemId", () => {
    it.skipIf(!dbAvailable)(
      "should remove a saved item",
      async () => {
        const { user, token } = await createTestUser({ userType: "professional" });

        const org = await prisma!.organization.create({
          data: {
            name: "Unsaveable Org",
            category: "therapy",
            ownerId: user.id,
          },
        });

        // Save first
        await app.request("/api/saved", {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            itemType: "catalog",
            itemId: org.id,
          }),
        });

        // Verify it's saved
        const countBefore = await prisma!.savedItem.count({
          where: { userId: user.id, itemType: "catalog", itemId: org.id },
        });
        expect(countBefore).toBe(1);

        // Delete the saved item
        const res = await app.request(`/api/saved/catalog/${org.id}`, {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.success).toBe(true);

        // Verify it's gone
        const countAfter = await prisma!.savedItem.count({
          where: { userId: user.id, itemType: "catalog", itemId: org.id },
        });
        expect(countAfter).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/saved/catalog/some-id", {
          method: "DELETE",
          headers: { "Content-Type": "application/json" },
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/saved/catalog (grouped saved catalog items)
  // -------------------------------------------------------------------------

  describe("GET /api/saved/catalog", () => {
    it.skipIf(!dbAvailable)(
      "should return grouped saved catalog items",
      async () => {
        const { user, token } = await createTestUser({ userType: "professional" });

        // Create a catalog category for icon mapping
        await prisma!.catalogCategory.deleteMany();
        await prisma!.catalogCategory.create({
          data: { name: "therapy", icon: "medical_services", sortOrder: 1 },
        });

        // Create organizations
        const org1 = await prisma!.organization.create({
          data: {
            name: "Therapy Center A",
            category: "therapy",
            ownerId: user.id,
          },
        });
        const org2 = await prisma!.organization.create({
          data: {
            name: "Therapy Center B",
            category: "therapy",
            ownerId: user.id,
          },
        });

        // Save both
        await prisma!.savedItem.create({
          data: { userId: user.id, itemType: "catalog", itemId: org1.id },
        });
        await prisma!.savedItem.create({
          data: { userId: user.id, itemType: "catalog", itemId: org2.id },
        });

        const res = await app.request("/api/saved/catalog", {
          method: "GET",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.groups).toBeDefined();
        expect(body.groups.length).toBe(1);
        expect(body.groups[0].category).toBe("therapy");
        expect(body.groups[0].icon).toBe("medical_services");
        expect(body.groups[0].count).toBe(2);
        expect(body.groups[0].items.length).toBe(2);

        // Each item should have saved: true
        for (const item of body.groups[0].items) {
          expect(item.saved).toBe(true);
          expect(item.id).toBeDefined();
          expect(item.name).toBeDefined();
          expect(item.owner).toBeDefined();
        }
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty groups when nothing saved",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request("/api/saved/catalog", {
          method: "GET",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.groups).toEqual([]);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/saved/catalog", {
          method: "GET",
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/saved/event (grouped saved events)
  // -------------------------------------------------------------------------

  describe("GET /api/saved/event", () => {
    it.skipIf(!dbAvailable)(
      "should return grouped saved events",
      async () => {
        const { user, token } = await createTestUser();

        // Create events directly via prisma
        const event1 = await prisma!.event.create({
          data: {
            title: "Autism Workshop",
            category: "Workshop",
            startDate: new Date(Date.now() + 86_400_000),
            organizerId: user.id,
            status: "approved",
          },
        });
        const event2 = await prisma!.event.create({
          data: {
            title: "Support Meetup",
            category: "Social",
            startDate: new Date(Date.now() + 2 * 86_400_000),
            organizerId: user.id,
            status: "approved",
          },
        });

        // Save both events
        await prisma!.savedItem.create({
          data: { userId: user.id, itemType: "event", itemId: event1.id },
        });
        await prisma!.savedItem.create({
          data: { userId: user.id, itemType: "event", itemId: event2.id },
        });

        const res = await app.request("/api/saved/event", {
          method: "GET",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.groups).toBeDefined();
        expect(body.groups.length).toBe(2); // Workshop + Social categories

        const allItems = body.groups.flatMap((g: any) => g.items);
        expect(allItems.length).toBe(2);

        // Each item should have saved: true
        for (const item of allItems) {
          expect(item.saved).toBe(true);
          expect(item.id).toBeDefined();
          expect(item.title).toBeDefined();
          expect(item.organizer).toBeDefined();
        }
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty groups when nothing saved",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request("/api/saved/event", {
          method: "GET",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.groups).toEqual([]);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/saved/event", {
          method: "GET",
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/saved/promotion (grouped saved promotions)
  // -------------------------------------------------------------------------

  describe("GET /api/saved/promotion", () => {
    it.skipIf(!dbAvailable)(
      "should return grouped saved promotions",
      async () => {
        const { user, token } = await createTestUser();

        // Create promotion category for icon mapping
        await prisma!.promotionCategory.deleteMany();
        await prisma!.promotionCategory.create({
          data: { name: "Discounts", icon: "percent", sortOrder: 1 },
        });

        // Create promotions directly via prisma
        const promo1 = await prisma!.promotion.create({
          data: {
            title: "20% Off Therapy",
            category: "Discounts",
            store: "Therapy Store",
            createdById: user.id,
            validFrom: new Date(Date.now() - 86_400_000),
          },
        });
        const promo2 = await prisma!.promotion.create({
          data: {
            title: "Free Consultation",
            category: "Discounts",
            store: "Wellness Center",
            createdById: user.id,
            validFrom: new Date(Date.now() - 86_400_000),
          },
        });

        // Save both promotions
        await prisma!.savedItem.create({
          data: { userId: user.id, itemType: "promotion", itemId: promo1.id },
        });
        await prisma!.savedItem.create({
          data: { userId: user.id, itemType: "promotion", itemId: promo2.id },
        });

        const res = await app.request("/api/saved/promotion", {
          method: "GET",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.groups).toBeDefined();
        expect(body.groups.length).toBe(1); // Both in "Discounts"
        expect(body.groups[0].category).toBe("Discounts");
        expect(body.groups[0].icon).toBe("percent");
        expect(body.groups[0].count).toBe(2);
        expect(body.groups[0].items.length).toBe(2);

        // Each item should have saved: true
        for (const item of body.groups[0].items) {
          expect(item.saved).toBe(true);
          expect(item.id).toBeDefined();
          expect(item.title).toBeDefined();
          expect(item.createdBy).toBeDefined();
        }
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty groups when nothing saved",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request("/api/saved/promotion", {
          method: "GET",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.groups).toEqual([]);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/saved/promotion", {
          method: "GET",
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );
  });
});
