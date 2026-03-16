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

/** Convenience: create an organization via the API and return parsed JSON body. */
async function createOrganization(
  token: string,
  data?: Partial<{
    name: string;
    description: string;
    category: string;
    address: string;
    phone: string;
    email: string;
    website: string;
    imageUrl: string;
    tags: string[];
    ageGroups: string[];
    specialNeeds: string[];
    latitude: number;
    longitude: number;
  }>
) {
  const res = await app.request("/api/catalog", {
    method: "POST",
    headers: authHeaders(token),
    body: JSON.stringify({
      name: data?.name ?? "Test Organization",
      category: data?.category ?? "therapy",
      ...(data?.description !== undefined ? { description: data.description } : {}),
      ...(data?.address !== undefined ? { address: data.address } : {}),
      ...(data?.phone !== undefined ? { phone: data.phone } : {}),
      ...(data?.email !== undefined ? { email: data.email } : {}),
      ...(data?.website !== undefined ? { website: data.website } : {}),
      ...(data?.imageUrl !== undefined ? { imageUrl: data.imageUrl } : {}),
      ...(data?.tags !== undefined ? { tags: data.tags } : {}),
      ...(data?.ageGroups !== undefined ? { ageGroups: data.ageGroups } : {}),
      ...(data?.specialNeeds !== undefined ? { specialNeeds: data.specialNeeds } : {}),
      ...(data?.latitude !== undefined ? { latitude: data.latitude } : {}),
      ...(data?.longitude !== undefined ? { longitude: data.longitude } : {}),
    }),
  });
  return { res, body: (await res.json()) as any };
}

// ---------------------------------------------------------------------------
// Catalog API tests
// ---------------------------------------------------------------------------

describe("Catalog API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  // -------------------------------------------------------------------------
  // POST /api/catalog (create)
  // -------------------------------------------------------------------------

  describe("POST /api/catalog", () => {
    it.skipIf(!dbAvailable)(
      "should create organization with valid data, returns 201",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });
        const { res, body } = await createOrganization(token, {
          name: "Autism Therapy Center",
          description: "Providing ABA therapy services",
          category: "therapy",
          address: "123 Main St",
          phone: "555-1234",
          email: "info@atc.com",
          website: "https://atc.com",
          tags: ["ABA", "speech"],
          ageGroups: ["children", "teens"],
          specialNeeds: ["autism", "ADHD"],
          latitude: 40.7128,
          longitude: -74.006,
        });

        expect(res.status).toBe(201);
        expect(body.place).toBeDefined();
        expect(body.place.name).toBe("Autism Therapy Center");
        expect(body.place.description).toBe("Providing ABA therapy services");
        expect(body.place.category).toBe("therapy");
        expect(body.place.address).toBe("123 Main St");
        expect(body.place.tags).toEqual(["ABA", "speech"]);
        expect(body.place.ageGroups).toEqual(["children", "teens"]);
        expect(body.place.specialNeeds).toEqual(["autism", "ADHD"]);
        expect(body.place.latitude).toBe(40.7128);
        expect(body.place.longitude).toBe(-74.006);
        expect(body.place.averageRating).toBe(0);
        expect(body.place.ratingCount).toBe(0);
        expect(body.place.saved).toBe(false);
        expect(body.place.userRating).toBeNull();
        expect(body.place.owner).toBeDefined();
        expect(body.place.id).toBeDefined();
        expect(body.place.createdAt).toBeDefined();
      }
    );

    it.skipIf(!dbAvailable)(
      "should allow educators to create organizations",
      async () => {
        const { token } = await createTestUser({ userType: "educator" });
        const { res, body } = await createOrganization(token, {
          name: "Learning Academy",
          category: "education",
        });

        expect(res.status).toBe(201);
        expect(body.place).toBeDefined();
        expect(body.place.name).toBe("Learning Academy");
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject non-professional/educator with 403",
      async () => {
        const { token } = await createTestUser({ userType: "parent" });
        const { res, body } = await createOrganization(token, {
          name: "Should Not Work",
          category: "therapy",
        });

        expect(res.status).toBe(403);
        expect(body.error).toBe(
          "Only professionals and educators can create organizations"
        );
        expect(body.code).toBe("FORBIDDEN");
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/catalog", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: "No Auth Org",
            category: "therapy",
          }),
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject invalid data (missing name) with 400/500",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });
        const res = await app.request("/api/catalog", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            // name is missing
            category: "therapy",
          }),
        });

        // Zod validation failure — may be 400 or 500 depending on error handler
        expect(res.status).toBeGreaterThanOrEqual(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject invalid data (missing category) with 400/500",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });
        const res = await app.request("/api/catalog", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            name: "Missing Category Org",
            // category is missing
          }),
        });

        expect(res.status).toBeGreaterThanOrEqual(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should default tags, ageGroups, specialNeeds to empty arrays",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });
        const { res, body } = await createOrganization(token, {
          name: "Minimal Org",
          category: "therapy",
        });

        expect(res.status).toBe(201);
        expect(body.place.tags).toEqual([]);
        expect(body.place.ageGroups).toEqual([]);
        expect(body.place.specialNeeds).toEqual([]);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/catalog (list)
  // -------------------------------------------------------------------------

  describe("GET /api/catalog", () => {
    it.skipIf(!dbAvailable)(
      "should return paginated organizations",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        // Create 3 organizations
        for (let i = 0; i < 3; i++) {
          await createOrganization(token, {
            name: `Org ${i + 1}`,
            category: "therapy",
          });
        }

        const res = await app.request("/api/catalog?limit=2", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.places).toBeDefined();
        expect(body.places.length).toBe(2);
        expect(body.nextCursor).toBeDefined();
        expect(body.nextCursor).not.toBeNull();

        // Second page using cursor
        const res2 = await app.request(
          `/api/catalog?limit=2&cursor=${body.nextCursor}`,
          { method: "GET" }
        );
        expect(res2.status).toBe(200);
        const page2 = (await res2.json()) as any;
        expect(page2.places.length).toBe(1);
        expect(page2.nextCursor).toBeNull();

        // No overlap between pages
        const allIds = [
          ...body.places.map((p: any) => p.id),
          ...page2.places.map((p: any) => p.id),
        ];
        expect(new Set(allIds).size).toBe(3);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty array when no organizations exist",
      async () => {
        const res = await app.request("/api/catalog", { method: "GET" });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.places).toEqual([]);
        expect(body.nextCursor).toBeNull();
      }
    );

    it.skipIf(!dbAvailable)(
      "should filter by category",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        await createOrganization(token, {
          name: "Therapy Place",
          category: "therapy",
        });
        await createOrganization(token, {
          name: "Education Place",
          category: "education",
        });

        const res = await app.request("/api/catalog?category=therapy", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.places.length).toBe(1);
        expect(body.places[0].name).toBe("Therapy Place");
        expect(body.places[0].category).toBe("therapy");
      }
    );

    it.skipIf(!dbAvailable)(
      "should filter by search query ?q=",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        await createOrganization(token, {
          name: "Sensory Gym",
          description: "A sensory-friendly gym for kids",
          category: "therapy",
        });
        await createOrganization(token, {
          name: "Speech Therapy",
          description: "Speech and language services",
          category: "therapy",
        });

        const res = await app.request("/api/catalog?q=Sensory", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.places.length).toBe(1);
        expect(body.places[0].name).toBe("Sensory Gym");
      }
    );

    it.skipIf(!dbAvailable)(
      "should filter by ageGroup",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        await createOrganization(token, {
          name: "Kids Center",
          category: "therapy",
          ageGroups: ["children"],
        });
        await createOrganization(token, {
          name: "Adult Center",
          category: "therapy",
          ageGroups: ["adults"],
        });

        const res = await app.request("/api/catalog?ageGroup=children", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.places.length).toBe(1);
        expect(body.places[0].name).toBe("Kids Center");
        expect(body.places[0].ageGroups).toContain("children");
      }
    );

    it.skipIf(!dbAvailable)(
      "should filter by specialNeed",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        await createOrganization(token, {
          name: "Autism Focused",
          category: "therapy",
          specialNeeds: ["autism"],
        });
        await createOrganization(token, {
          name: "ADHD Focused",
          category: "therapy",
          specialNeeds: ["ADHD"],
        });

        const res = await app.request("/api/catalog?specialNeed=autism", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.places.length).toBe(1);
        expect(body.places[0].name).toBe("Autism Focused");
        expect(body.places[0].specialNeeds).toContain("autism");
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/catalog/:id (single organization)
  // -------------------------------------------------------------------------

  describe("GET /api/catalog/:id", () => {
    it.skipIf(!dbAvailable)(
      "should return single organization with owner info",
      async () => {
        const { token } = await createTestUser({
          firstName: "Jane",
          lastName: "Doe",
          userType: "professional",
        });
        const { body: created } = await createOrganization(token, {
          name: "Detailed Org",
          description: "Full description here",
          category: "therapy",
          address: "456 Oak Ave",
          tags: ["ABA"],
          ageGroups: ["children"],
          specialNeeds: ["autism"],
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}`, {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.place).toBeDefined();
        expect(body.place.id).toBe(orgId);
        expect(body.place.name).toBe("Detailed Org");
        expect(body.place.description).toBe("Full description here");
        expect(body.place.category).toBe("therapy");
        expect(body.place.address).toBe("456 Oak Ave");
        expect(body.place.tags).toEqual(["ABA"]);
        expect(body.place.ageGroups).toEqual(["children"]);
        expect(body.place.specialNeeds).toEqual(["autism"]);
        expect(body.place.owner).toBeDefined();
        expect(body.place.owner.name).toBe("Jane Doe");
        expect(body.place.averageRating).toBe(0);
        expect(body.place.ratingCount).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent organization",
      async () => {
        const res = await app.request("/api/catalog/non-existent-id-12345", {
          method: "GET",
        });
        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Organization not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // -------------------------------------------------------------------------
  // PUT /api/catalog/:id (update)
  // -------------------------------------------------------------------------

  describe("PUT /api/catalog/:id", () => {
    it.skipIf(!dbAvailable)(
      "should allow owner to update their organization",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });
        const { body: created } = await createOrganization(token, {
          name: "Original Name",
          category: "therapy",
          address: "Old Address",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}`, {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            name: "Updated Name",
            address: "New Address",
          }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.place.name).toBe("Updated Name");
        expect(body.place.address).toBe("New Address");
        // Category should remain unchanged
        expect(body.place.category).toBe("therapy");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 for non-owner",
      async () => {
        const owner = await createTestUser({
          firstName: "Owner",
          userType: "professional",
        });
        const other = await createTestUser({
          firstName: "Other",
          userType: "professional",
        });

        const { body: created } = await createOrganization(owner.token, {
          name: "Owner's Org",
          category: "therapy",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}`, {
          method: "PUT",
          headers: authHeaders(other.token),
          body: JSON.stringify({ name: "Hacked Name" }),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent organization",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        const res = await app.request("/api/catalog/non-existent-id-12345", {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({ name: "Nope" }),
        });

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Organization not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );

    it.skipIf(!dbAvailable)(
      "should update tags, ageGroups, specialNeeds arrays",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });
        const { body: created } = await createOrganization(token, {
          name: "Array Update Org",
          category: "therapy",
          tags: ["old-tag"],
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}`, {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            tags: ["new-tag-1", "new-tag-2"],
            ageGroups: ["teens"],
            specialNeeds: ["autism", "sensory"],
          }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.place.tags).toEqual(["new-tag-1", "new-tag-2"]);
        expect(body.place.ageGroups).toEqual(["teens"]);
        expect(body.place.specialNeeds).toEqual(["autism", "sensory"]);
      }
    );
  });

  // -------------------------------------------------------------------------
  // DELETE /api/catalog/:id
  // -------------------------------------------------------------------------

  describe("DELETE /api/catalog/:id", () => {
    it.skipIf(!dbAvailable)(
      "should allow owner to delete their organization",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });
        const { body: created } = await createOrganization(token, {
          name: "Deletable Org",
          category: "therapy",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}`, {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.success).toBe(true);

        // Verify it's actually gone
        const check = await app.request(`/api/catalog/${orgId}`, {
          method: "GET",
        });
        expect(check.status).toBe(404);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 for non-owner",
      async () => {
        const owner = await createTestUser({
          firstName: "Owner",
          userType: "professional",
        });
        const other = await createTestUser({
          firstName: "Other",
          userType: "professional",
        });

        const { body: created } = await createOrganization(owner.token, {
          name: "Not Yours",
          category: "therapy",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}`, {
          method: "DELETE",
          headers: authHeaders(other.token),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent organization",
      async () => {
        const { token } = await createTestUser({ userType: "professional" });

        const res = await app.request("/api/catalog/non-existent-id-12345", {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Organization not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // -------------------------------------------------------------------------
  // PUT /api/catalog/:id/rating (ratings)
  // -------------------------------------------------------------------------

  describe("PUT /api/catalog/:id/rating", () => {
    it.skipIf(!dbAvailable)(
      "should create a rating and return averageRating, ratingCount, userRating",
      async () => {
        const owner = await createTestUser({ userType: "professional" });
        const rater = await createTestUser({ firstName: "Rater" });

        const { body: created } = await createOrganization(owner.token, {
          name: "Ratable Org",
          category: "therapy",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater.token),
          body: JSON.stringify({ score: 4 }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.averageRating).toBe(4);
        expect(body.ratingCount).toBe(1);
        expect(body.userRating).toBe(4);
      }
    );

    it.skipIf(!dbAvailable)(
      "should update an existing rating (upsert)",
      async () => {
        const owner = await createTestUser({ userType: "professional" });
        const rater = await createTestUser({ firstName: "Rater" });

        const { body: created } = await createOrganization(owner.token, {
          name: "Updatable Rating Org",
          category: "therapy",
        });
        const orgId = created.place.id;

        // Rate first time
        await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater.token),
          body: JSON.stringify({ score: 3 }),
        });

        // Update rating
        const res = await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater.token),
          body: JSON.stringify({ score: 5 }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.averageRating).toBe(5);
        expect(body.ratingCount).toBe(1);
        expect(body.userRating).toBe(5);
      }
    );

    it.skipIf(!dbAvailable)(
      "should recalculate averageRating and ratingCount with multiple raters",
      async () => {
        const owner = await createTestUser({ userType: "professional" });
        const rater1 = await createTestUser({ firstName: "Rater1" });
        const rater2 = await createTestUser({ firstName: "Rater2" });
        const rater3 = await createTestUser({ firstName: "Rater3" });

        const { body: created } = await createOrganization(owner.token, {
          name: "Multi Rating Org",
          category: "therapy",
        });
        const orgId = created.place.id;

        // Three users rate: 4, 3, 5 => average = 4, count = 3
        await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater1.token),
          body: JSON.stringify({ score: 4 }),
        });
        await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater2.token),
          body: JSON.stringify({ score: 3 }),
        });
        const res = await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater3.token),
          body: JSON.stringify({ score: 5 }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.ratingCount).toBe(3);
        expect(body.averageRating).toBe(4); // (4+3+5)/3 = 4
        expect(body.userRating).toBe(5); // rater3's score
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject rating score below 1",
      async () => {
        const owner = await createTestUser({ userType: "professional" });
        const rater = await createTestUser({ firstName: "Rater" });

        const { body: created } = await createOrganization(owner.token, {
          name: "Invalid Rating Org",
          category: "therapy",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater.token),
          body: JSON.stringify({ score: 0 }),
        });

        // Zod validation should reject score: 0
        expect(res.status).toBeGreaterThanOrEqual(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject rating score above 5",
      async () => {
        const owner = await createTestUser({ userType: "professional" });
        const rater = await createTestUser({ firstName: "Rater" });

        const { body: created } = await createOrganization(owner.token, {
          name: "Invalid Rating Org 2",
          category: "therapy",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: authHeaders(rater.token),
          body: JSON.stringify({ score: 6 }),
        });

        // Zod validation should reject score: 6
        expect(res.status).toBeGreaterThanOrEqual(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 when rating non-existent organization",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request(
          "/api/catalog/non-existent-id-12345/rating",
          {
            method: "PUT",
            headers: authHeaders(token),
            body: JSON.stringify({ score: 3 }),
          }
        );

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Organization not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated rating with 401",
      async () => {
        const owner = await createTestUser({ userType: "professional" });
        const { body: created } = await createOrganization(owner.token, {
          name: "No Auth Rating Org",
          category: "therapy",
        });
        const orgId = created.place.id;

        const res = await app.request(`/api/catalog/${orgId}/rating`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ score: 4 }),
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );
  });
});
