import { describe, it, expect, beforeEach } from "vitest";
import app from "../../src/index.js";
import { cleanDatabase, prisma } from "../setup.js";

const dbAvailable = !!prisma;

// ---------------------------------------------------------------------------
// Filters API tests
// ---------------------------------------------------------------------------

describe("Filters API", () => {
  beforeEach(async () => {
    await cleanDatabase();
    // cleanDatabase does NOT clean filter/category tables, so we do it manually
    if (prisma) {
      await prisma.catalogCategory.deleteMany();
      await prisma.ageGroup.deleteMany();
      await prisma.specialNeed.deleteMany();
      await prisma.eventCategory.deleteMany();
      await prisma.promotionCategory.deleteMany();
    }
  });

  // -------------------------------------------------------------------------
  // GET /api/filters/catalog-categories
  // -------------------------------------------------------------------------

  describe("GET /api/filters/catalog-categories", () => {
    it.skipIf(!dbAvailable)(
      "should return categories ordered by sortOrder",
      async () => {
        // Seed catalog categories in non-sorted order
        await prisma!.catalogCategory.create({
          data: { name: "Education", icon: "school", sortOrder: 2 },
        });
        await prisma!.catalogCategory.create({
          data: { name: "Therapy", icon: "medical_services", sortOrder: 1 },
        });
        await prisma!.catalogCategory.create({
          data: { name: "Recreation", icon: "sports", sortOrder: 3 },
        });

        const res = await app.request("/api/filters/catalog-categories", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.categories).toBeDefined();
        expect(body.categories.length).toBe(3);

        // Verify sorted by sortOrder ascending
        expect(body.categories[0].name).toBe("Therapy");
        expect(body.categories[0].sortOrder).toBe(1);
        expect(body.categories[1].name).toBe("Education");
        expect(body.categories[1].sortOrder).toBe(2);
        expect(body.categories[2].name).toBe("Recreation");
        expect(body.categories[2].sortOrder).toBe(3);

        // Verify icon field is present
        expect(body.categories[0].icon).toBe("medical_services");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty array when no categories exist",
      async () => {
        const res = await app.request("/api/filters/catalog-categories", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.categories).toEqual([]);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/filters/age-groups
  // -------------------------------------------------------------------------

  describe("GET /api/filters/age-groups", () => {
    it.skipIf(!dbAvailable)(
      "should return age groups ordered by sortOrder",
      async () => {
        await prisma!.ageGroup.create({
          data: { name: "Teens", sortOrder: 2 },
        });
        await prisma!.ageGroup.create({
          data: { name: "Children", sortOrder: 1 },
        });
        await prisma!.ageGroup.create({
          data: { name: "Adults", sortOrder: 3 },
        });

        const res = await app.request("/api/filters/age-groups", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.ageGroups).toBeDefined();
        expect(body.ageGroups.length).toBe(3);

        // Verify sorted by sortOrder ascending
        expect(body.ageGroups[0].name).toBe("Children");
        expect(body.ageGroups[0].sortOrder).toBe(1);
        expect(body.ageGroups[1].name).toBe("Teens");
        expect(body.ageGroups[1].sortOrder).toBe(2);
        expect(body.ageGroups[2].name).toBe("Adults");
        expect(body.ageGroups[2].sortOrder).toBe(3);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty array when no age groups exist",
      async () => {
        const res = await app.request("/api/filters/age-groups", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.ageGroups).toEqual([]);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/filters/special-needs
  // -------------------------------------------------------------------------

  describe("GET /api/filters/special-needs", () => {
    it.skipIf(!dbAvailable)(
      "should return special needs ordered by sortOrder",
      async () => {
        await prisma!.specialNeed.create({
          data: { name: "ADHD", sortOrder: 2 },
        });
        await prisma!.specialNeed.create({
          data: { name: "Autism", sortOrder: 1 },
        });
        await prisma!.specialNeed.create({
          data: { name: "Sensory Processing", sortOrder: 3 },
        });

        const res = await app.request("/api/filters/special-needs", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.specialNeeds).toBeDefined();
        expect(body.specialNeeds.length).toBe(3);

        // Verify sorted by sortOrder ascending
        expect(body.specialNeeds[0].name).toBe("Autism");
        expect(body.specialNeeds[0].sortOrder).toBe(1);
        expect(body.specialNeeds[1].name).toBe("ADHD");
        expect(body.specialNeeds[1].sortOrder).toBe(2);
        expect(body.specialNeeds[2].name).toBe("Sensory Processing");
        expect(body.specialNeeds[2].sortOrder).toBe(3);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty array when no special needs exist",
      async () => {
        const res = await app.request("/api/filters/special-needs", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.specialNeeds).toEqual([]);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/filters/event-categories
  // -------------------------------------------------------------------------

  describe("GET /api/filters/event-categories", () => {
    it.skipIf(!dbAvailable)(
      "should return event categories ordered by sortOrder",
      async () => {
        await prisma!.eventCategory.create({
          data: { name: "Social", icon: "people", sortOrder: 2 },
        });
        await prisma!.eventCategory.create({
          data: { name: "Workshop", icon: "build", sortOrder: 1 },
        });
        await prisma!.eventCategory.create({
          data: { name: "Conference", icon: "event", sortOrder: 3 },
        });

        const res = await app.request("/api/filters/event-categories", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.categories).toBeDefined();
        expect(body.categories.length).toBe(3);

        // Verify sorted by sortOrder ascending
        expect(body.categories[0].name).toBe("Workshop");
        expect(body.categories[0].sortOrder).toBe(1);
        expect(body.categories[1].name).toBe("Social");
        expect(body.categories[1].sortOrder).toBe(2);
        expect(body.categories[2].name).toBe("Conference");
        expect(body.categories[2].sortOrder).toBe(3);

        // Verify icon field is present
        expect(body.categories[0].icon).toBe("build");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty array when no event categories exist",
      async () => {
        const res = await app.request("/api/filters/event-categories", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.categories).toEqual([]);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/filters/promotion-categories
  // -------------------------------------------------------------------------

  describe("GET /api/filters/promotion-categories", () => {
    it.skipIf(!dbAvailable)(
      "should return promotion categories ordered by sortOrder",
      async () => {
        await prisma!.promotionCategory.create({
          data: { name: "Freebies", icon: "card_giftcard", sortOrder: 2 },
        });
        await prisma!.promotionCategory.create({
          data: { name: "Discounts", icon: "percent", sortOrder: 1 },
        });
        await prisma!.promotionCategory.create({
          data: { name: "Events", icon: "celebration", sortOrder: 3 },
        });

        const res = await app.request("/api/filters/promotion-categories", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.categories).toBeDefined();
        expect(body.categories.length).toBe(3);

        // Verify sorted by sortOrder ascending
        expect(body.categories[0].name).toBe("Discounts");
        expect(body.categories[0].sortOrder).toBe(1);
        expect(body.categories[1].name).toBe("Freebies");
        expect(body.categories[1].sortOrder).toBe(2);
        expect(body.categories[2].name).toBe("Events");
        expect(body.categories[2].sortOrder).toBe(3);

        // Verify icon field is present
        expect(body.categories[0].icon).toBe("percent");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return empty array when no promotion categories exist",
      async () => {
        const res = await app.request("/api/filters/promotion-categories", {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.categories).toEqual([]);
      }
    );
  });
});
