import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import {
  sessionMiddleware,
  optionalSessionMiddleware,
} from "../middleware/session.js";
import type { AppBindings, AppVariables } from "../types/context.js";

const createPromotionSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  category: z.string().min(1),
  discount: z.string().optional(),
  store: z.string().min(1).max(200),
  brandLogoUrl: z.string().url().optional(),
  imageUrl: z.string().url().optional(),
  expiresAt: z.string().datetime().optional(),
  validFrom: z.string().datetime().optional(),
  organizationId: z.string().optional(),
});

const updatePromotionSchema = createPromotionSchema.partial();

const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(50).default(20),
  q: z.string().optional(),
  category: z.string().optional(),
});

function mapPromotion(
  promotion: any,
  userId: string | null,
  saved: boolean
) {
  const liked = userId
    ? (promotion.reactions ?? []).some((r: any) => r.authorId === userId)
    : false;
  const claimed = userId
    ? (promotion.claims ?? []).some((c: any) => c.userId === userId)
    : false;

  return {
    id: promotion.id,
    title: promotion.title,
    description: promotion.description,
    category: promotion.category,
    discount: promotion.discount,
    store: promotion.store,
    brandLogoUrl: promotion.brandLogoUrl,
    imageUrl: promotion.imageUrl,
    expiresAt: promotion.expiresAt ? promotion.expiresAt.toISOString() : null,
    validFrom: promotion.validFrom.toISOString(),
    organizationId: promotion.organizationId,
    createdById: promotion.createdById,
    createdBy: promotion.createdBy,
    likesCount: promotion.likesCount,
    liked,
    claimed,
    saved,
    createdAt: promotion.createdAt.toISOString(),
    updatedAt: promotion.updatedAt.toISOString(),
  };
}

export function promotionRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // GET / — list promotions (paginated, hides expired)
  app.get("/", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user") as any;

    const query = paginationSchema.parse({
      cursor: c.req.query("cursor"),
      limit: c.req.query("limit"),
      q: c.req.query("q"),
      category: c.req.query("category"),
    });

    const now = new Date();

    const where: Record<string, unknown> = {
      validFrom: { lte: now },
      OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
    };

    if (query.q) {
      where.AND = [
        {
          OR: [
            { title: { contains: query.q } },
            { description: { contains: query.q } },
            { store: { contains: query.q } },
          ],
        },
      ];
    }

    if (query.category) {
      where.category = query.category;
    }

    const promotions = await prisma.promotion.findMany({
      where,
      take: query.limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      orderBy: { createdAt: "desc" },
      include: {
        createdBy: {
          select: { id: true, name: true, image: true, userType: true },
        },
        ...(user
          ? {
              reactions: {
                where: { authorId: user.id },
                select: { authorId: true },
              },
              claims: {
                where: { userId: user.id },
                select: { userId: true },
              },
            }
          : {}),
      },
    });

    const hasMore = promotions.length > query.limit;
    const results = hasMore ? promotions.slice(0, query.limit) : promotions;

    // Check saved status for authenticated users
    let savedIds = new Set<string>();
    if (user && results.length > 0) {
      const promotionIds = results.map((p: any) => p.id);
      const savedItems = await prisma.savedItem.findMany({
        where: {
          userId: user.id,
          itemType: "promotion",
          itemId: { in: promotionIds },
        },
        select: { itemId: true },
      });
      savedIds = new Set(savedItems.map((s: any) => s.itemId));
    }

    const nextCursor = hasMore ? results[results.length - 1]?.id ?? null : null;

    return c.json({
      promotions: results.map((p: any) =>
        mapPromotion(p, user?.id ?? null, savedIds.has(p.id))
      ),
      nextCursor,
    });
  });

  // GET /:id — single promotion detail
  app.get("/:id", optionalSessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const prisma = c.get("prisma");
    const user = c.get("user") as any;

    const promotion = await prisma.promotion.findUnique({
      where: { id },
      include: {
        createdBy: {
          select: { id: true, name: true, image: true, userType: true },
        },
        ...(user
          ? {
              reactions: {
                where: { authorId: user.id },
                select: { authorId: true },
              },
              claims: {
                where: { userId: user.id },
                select: { userId: true },
              },
            }
          : {}),
      },
    });

    if (!promotion) {
      return c.json({ error: "Promotion not found", code: "NOT_FOUND" }, 404);
    }

    let saved = false;
    if (user) {
      const savedItem = await prisma.savedItem.findUnique({
        where: {
          userId_itemType_itemId: {
            userId: user.id,
            itemType: "promotion",
            itemId: id,
          },
        },
      });
      saved = !!savedItem;
    }

    return c.json({ promotion: mapPromotion(promotion, user?.id ?? null, saved) });
  });

  // POST / — create promotion (authenticated)
  app.post("/", sessionMiddleware, zValidator("json", createPromotionSchema), async (c) => {
    const user = c.get("user");
    const prisma = c.get("prisma");

    const body = c.req.valid("json");

    const promotion = await prisma.promotion.create({
      data: {
        title: body.title,
        description: body.description,
        category: body.category,
        discount: body.discount,
        store: body.store,
        brandLogoUrl: body.brandLogoUrl,
        imageUrl: body.imageUrl,
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
        validFrom: body.validFrom ? new Date(body.validFrom) : undefined,
        organizationId: body.organizationId,
        createdById: user.id,
      },
      include: {
        createdBy: {
          select: { id: true, name: true, image: true, userType: true },
        },
      },
    });

    return c.json(
      { promotion: mapPromotion(promotion, user.id, false) },
      201
    );
  });

  // PUT /:id — update promotion (owner only)
  app.put("/:id", sessionMiddleware, zValidator("json", updatePromotionSchema), async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const existing = await prisma.promotion.findUnique({ where: { id } });

    if (!existing) {
      return c.json({ error: "Promotion not found", code: "NOT_FOUND" }, 404);
    }

    if (existing.createdById !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    const body = c.req.valid("json");

    const updated = await prisma.promotion.update({
      where: { id },
      data: {
        ...(body.title !== undefined ? { title: body.title } : {}),
        ...(body.description !== undefined ? { description: body.description } : {}),
        ...(body.category !== undefined ? { category: body.category } : {}),
        ...(body.discount !== undefined ? { discount: body.discount } : {}),
        ...(body.store !== undefined ? { store: body.store } : {}),
        ...(body.brandLogoUrl !== undefined ? { brandLogoUrl: body.brandLogoUrl } : {}),
        ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
        ...(body.expiresAt !== undefined ? { expiresAt: new Date(body.expiresAt) } : {}),
        ...(body.validFrom !== undefined ? { validFrom: new Date(body.validFrom) } : {}),
        ...(body.organizationId !== undefined ? { organizationId: body.organizationId } : {}),
      },
      include: {
        createdBy: {
          select: { id: true, name: true, image: true, userType: true },
        },
        reactions: {
          where: { authorId: user.id },
          select: { authorId: true },
        },
        claims: {
          where: { userId: user.id },
          select: { userId: true },
        },
      },
    });

    const savedItem = await prisma.savedItem.findUnique({
      where: {
        userId_itemType_itemId: {
          userId: user.id,
          itemType: "promotion",
          itemId: id,
        },
      },
    });

    return c.json({ promotion: mapPromotion(updated, user.id, !!savedItem) });
  });

  // DELETE /:id — delete promotion (owner only)
  app.delete("/:id", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const existing = await prisma.promotion.findUnique({ where: { id } });

    if (!existing) {
      return c.json({ error: "Promotion not found", code: "NOT_FOUND" }, 404);
    }

    if (existing.createdById !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    await prisma.promotion.delete({ where: { id } });

    return c.json({ success: true });
  });

  // PUT /:id/reactions — like promotion (atomic transaction)
  app.put("/:id/reactions", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const existing = await prisma.promotion.findUnique({ where: { id } });
    if (!existing) {
      return c.json({ error: "Promotion not found", code: "NOT_FOUND" }, 404);
    }

    // Check if already liked
    const existingReaction = await prisma.promotionReaction.findUnique({
      where: {
        authorId_promotionId: {
          authorId: user.id,
          promotionId: id,
        },
      },
    });

    if (existingReaction) {
      return c.json({ liked: true, likesCount: existing.likesCount });
    }

    const [, updated] = await prisma.$transaction([
      prisma.promotionReaction.create({
        data: {
          authorId: user.id,
          promotionId: id,
        },
      }),
      prisma.promotion.update({
        where: { id },
        data: { likesCount: { increment: 1 } },
        select: { likesCount: true },
      }),
    ]);

    return c.json({ liked: true, likesCount: updated.likesCount });
  });

  // DELETE /:id/reactions — unlike promotion (atomic transaction)
  app.delete("/:id/reactions", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const existing = await prisma.promotion.findUnique({ where: { id } });
    if (!existing) {
      return c.json({ error: "Promotion not found", code: "NOT_FOUND" }, 404);
    }

    const existingReaction = await prisma.promotionReaction.findUnique({
      where: {
        authorId_promotionId: {
          authorId: user.id,
          promotionId: id,
        },
      },
    });

    if (!existingReaction) {
      return c.json({ liked: false, likesCount: existing.likesCount });
    }

    const [, updated] = await prisma.$transaction([
      prisma.promotionReaction.delete({
        where: {
          authorId_promotionId: {
            authorId: user.id,
            promotionId: id,
          },
        },
      }),
      prisma.promotion.update({
        where: { id },
        data: { likesCount: { decrement: 1 } },
        select: { likesCount: true },
      }),
    ]);

    return c.json({ liked: false, likesCount: updated.likesCount });
  });

  // POST /:id/claim — claim promotion (idempotent)
  app.post("/:id/claim", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const existing = await prisma.promotion.findUnique({ where: { id } });
    if (!existing) {
      return c.json({ error: "Promotion not found", code: "NOT_FOUND" }, 404);
    }

    await prisma.promotionClaim.upsert({
      where: {
        userId_promotionId: {
          userId: user.id,
          promotionId: id,
        },
      },
      update: {},
      create: {
        userId: user.id,
        promotionId: id,
      },
    });

    return c.json({ claimed: true });
  });

  return app;
}
