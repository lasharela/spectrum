import { Hono } from "hono";
import { z } from "zod";
import {
  sessionMiddleware,
  optionalSessionMiddleware,
} from "../middleware/session.js";
import type { AppBindings, AppVariables } from "../types/context.js";

const createOrganizationSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  category: z.string().min(1),
  address: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  website: z.string().url().optional(),
  imageUrl: z.string().url().optional(),
  tags: z.array(z.string()).max(10).default([]),
  ageGroups: z.array(z.string()).default([]),
  specialNeeds: z.array(z.string()).default([]),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
});

const updateOrganizationSchema = createOrganizationSchema.partial();

const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(50).default(20),
  q: z.string().optional(),
  category: z.string().optional(),
  ageGroup: z.string().optional(),
  specialNeed: z.string().optional(),
});

const ratingSchema = z.object({
  score: z.number().int().min(1).max(5),
});

function mapOrganization(
  org: any,
  saved: boolean,
  userRating: number | null
) {
  return {
    id: org.id,
    name: org.name,
    description: org.description,
    category: org.category,
    address: org.address,
    imageUrl: org.imageUrl,
    averageRating: org.averageRating,
    ratingCount: org.ratingCount,
    tags: JSON.parse(org.tags),
    ageGroups: JSON.parse(org.ageGroups),
    specialNeeds: JSON.parse(org.specialNeeds),
    latitude: org.latitude,
    longitude: org.longitude,
    ownerId: org.ownerId,
    owner: org.owner,
    saved,
    userRating,
    createdAt: org.createdAt.toISOString(),
  };
}

export function catalogRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // GET / - list organizations (paginated, filterable)
  app.get("/", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const query = paginationSchema.parse({
      cursor: c.req.query("cursor"),
      limit: c.req.query("limit"),
      q: c.req.query("q"),
      category: c.req.query("category"),
      ageGroup: c.req.query("ageGroup"),
      specialNeed: c.req.query("specialNeed"),
    });

    const user = c.get("user") as any;

    const where: Record<string, unknown> = {};
    if (query.q) {
      where.OR = [
        { name: { contains: query.q } },
        { description: { contains: query.q } },
      ];
    }
    if (query.category) {
      where.category = query.category;
    }

    const orgs = await prisma.organization.findMany({
      where,
      take: query.limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      orderBy: { createdAt: "desc" },
      include: {
        owner: {
          select: { id: true, name: true, image: true, userType: true },
        },
        ...(user
          ? {
              ratings: {
                where: { userId: user.id },
                select: { score: true },
              },
            }
          : {}),
      },
    });

    const hasMore = orgs.length > query.limit;
    let results = hasMore ? orgs.slice(0, query.limit) : orgs;

    // Post-query filtering for ageGroup and specialNeed (JSON fields)
    if (query.ageGroup) {
      results = results.filter((org: any) => {
        const ageGroups: string[] = JSON.parse(org.ageGroups);
        return ageGroups.includes(query.ageGroup!);
      });
    }
    if (query.specialNeed) {
      results = results.filter((org: any) => {
        const specialNeeds: string[] = JSON.parse(org.specialNeeds);
        return specialNeeds.includes(query.specialNeed!);
      });
    }

    // Check saved status for authenticated users
    let savedIds = new Set<string>();
    if (user && results.length > 0) {
      const savedItems = await prisma.savedItem.findMany({
        where: {
          userId: user.id,
          itemType: "organization",
          itemId: { in: results.map((o: any) => o.id) },
        },
        select: { itemId: true },
      });
      savedIds = new Set(savedItems.map((s: any) => s.itemId));
    }

    const nextCursor = hasMore ? results[results.length - 1]?.id ?? null : null;

    return c.json({
      places: results.map((org: any) =>
        mapOrganization(
          org,
          savedIds.has(org.id),
          (org as any).ratings?.[0]?.score ?? null
        )
      ),
      nextCursor,
    });
  });

  // GET /:id - get single organization
  app.get("/:id", optionalSessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const prisma = c.get("prisma");
    const user = c.get("user") as any;

    const org = await prisma.organization.findUnique({
      where: { id },
      include: {
        owner: {
          select: { id: true, name: true, image: true, userType: true },
        },
        ...(user
          ? {
              ratings: {
                where: { userId: user.id },
                select: { score: true },
              },
            }
          : {}),
      },
    });

    if (!org) {
      return c.json(
        { error: "Organization not found", code: "NOT_FOUND" },
        404
      );
    }

    // Check saved status
    let saved = false;
    if (user) {
      const savedItem = await prisma.savedItem.findUnique({
        where: {
          userId_itemType_itemId: {
            userId: user.id,
            itemType: "organization",
            itemId: id,
          },
        },
      });
      saved = !!savedItem;
    }

    const userRating = (org as any).ratings?.[0]?.score ?? null;

    return c.json({
      place: mapOrganization(org, saved, userRating),
    });
  });

  // POST / - create organization
  app.post("/", sessionMiddleware, async (c) => {
    const user = c.get("user");
    const prisma = c.get("prisma");

    // Only professionals and educators can create organizations
    if (user.userType !== "professional" && user.userType !== "educator") {
      return c.json(
        {
          error: "Only professionals and educators can create organizations",
          code: "FORBIDDEN",
        },
        403
      );
    }

    const body = createOrganizationSchema.parse(await c.req.json());

    const org = await prisma.organization.create({
      data: {
        name: body.name,
        description: body.description,
        category: body.category,
        address: body.address,
        phone: body.phone,
        email: body.email,
        website: body.website,
        imageUrl: body.imageUrl,
        tags: JSON.stringify(body.tags),
        ageGroups: JSON.stringify(body.ageGroups),
        specialNeeds: JSON.stringify(body.specialNeeds),
        latitude: body.latitude,
        longitude: body.longitude,
        ownerId: user.id,
      },
      include: {
        owner: {
          select: { id: true, name: true, image: true, userType: true },
        },
      },
    });

    return c.json(
      { place: mapOrganization(org, false, null) },
      201
    );
  });

  // PUT /:id - update organization (owner only)
  app.put("/:id", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const org = await prisma.organization.findUnique({ where: { id } });

    if (!org) {
      return c.json(
        { error: "Organization not found", code: "NOT_FOUND" },
        404
      );
    }

    if (org.ownerId !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    const body = updateOrganizationSchema.parse(await c.req.json());

    const updated = await prisma.organization.update({
      where: { id },
      data: {
        ...(body.name !== undefined ? { name: body.name } : {}),
        ...(body.description !== undefined
          ? { description: body.description }
          : {}),
        ...(body.category !== undefined ? { category: body.category } : {}),
        ...(body.address !== undefined ? { address: body.address } : {}),
        ...(body.phone !== undefined ? { phone: body.phone } : {}),
        ...(body.email !== undefined ? { email: body.email } : {}),
        ...(body.website !== undefined ? { website: body.website } : {}),
        ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
        ...(body.tags !== undefined
          ? { tags: JSON.stringify(body.tags) }
          : {}),
        ...(body.ageGroups !== undefined
          ? { ageGroups: JSON.stringify(body.ageGroups) }
          : {}),
        ...(body.specialNeeds !== undefined
          ? { specialNeeds: JSON.stringify(body.specialNeeds) }
          : {}),
        ...(body.latitude !== undefined ? { latitude: body.latitude } : {}),
        ...(body.longitude !== undefined ? { longitude: body.longitude } : {}),
      },
      include: {
        owner: {
          select: { id: true, name: true, image: true, userType: true },
        },
        ratings: {
          where: { userId: user.id },
          select: { score: true },
        },
      },
    });

    // Check saved status
    const savedItem = await prisma.savedItem.findUnique({
      where: {
        userId_itemType_itemId: {
          userId: user.id,
          itemType: "organization",
          itemId: id,
        },
      },
    });

    return c.json({
      place: mapOrganization(
        updated,
        !!savedItem,
        updated.ratings?.[0]?.score ?? null
      ),
    });
  });

  // DELETE /:id - delete organization (owner only)
  app.delete("/:id", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const org = await prisma.organization.findUnique({ where: { id } });

    if (!org) {
      return c.json(
        { error: "Organization not found", code: "NOT_FOUND" },
        404
      );
    }

    if (org.ownerId !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    await prisma.organization.delete({ where: { id } });

    return c.json({ success: true });
  });

  // PUT /:id/rating - rate organization (upsert)
  app.put("/:id/rating", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const org = await prisma.organization.findUnique({ where: { id } });
    if (!org) {
      return c.json(
        { error: "Organization not found", code: "NOT_FOUND" },
        404
      );
    }

    const { score } = ratingSchema.parse(await c.req.json());

    const updatedOrg = await prisma.$transaction(async (tx: any) => {
      // Upsert the rating
      await tx.rating.upsert({
        where: {
          userId_organizationId: {
            userId: user.id,
            organizationId: id,
          },
        },
        update: { score },
        create: {
          userId: user.id,
          organizationId: id,
          score,
        },
      });

      // Recalculate average rating and count
      const aggregate = await tx.rating.aggregate({
        where: { organizationId: id },
        _avg: { score: true },
        _count: { score: true },
      });

      // Update organization with new averages
      return tx.organization.update({
        where: { id },
        data: {
          averageRating: aggregate._avg.score ?? 0,
          ratingCount: aggregate._count.score ?? 0,
        },
      });
    });

    return c.json({
      averageRating: updatedOrg.averageRating,
      ratingCount: updatedOrg.ratingCount,
      userRating: score,
    });
  });

  return app;
}
