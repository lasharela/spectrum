import { Hono } from "hono";
import { z } from "zod";
import { sessionMiddleware } from "../middleware/session.js";
import type { AppBindings, AppVariables } from "../types/context.js";

const saveItemSchema = z.object({
  itemType: z.enum(["catalog", "promotion", "event"]),
  itemId: z.string().min(1),
});

export function savedRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // PUT / - Save item (upsert)
  app.put("/", sessionMiddleware, async (c) => {
    const user = c.get("user");
    const prisma = c.get("prisma");
    const body = saveItemSchema.parse(await c.req.json());

    const saved = await prisma.savedItem.upsert({
      where: {
        userId_itemType_itemId: {
          userId: user.id,
          itemType: body.itemType,
          itemId: body.itemId,
        },
      },
      update: {},
      create: {
        userId: user.id,
        itemType: body.itemType,
        itemId: body.itemId,
      },
    });

    return c.json({ saved: { id: saved.id, itemType: saved.itemType, itemId: saved.itemId } });
  });

  // DELETE /:itemType/:itemId - Unsave item
  app.delete("/:itemType/:itemId", sessionMiddleware, async (c) => {
    const user = c.get("user");
    const prisma = c.get("prisma");
    const itemType = c.req.param("itemType");
    const itemId = c.req.param("itemId");

    await prisma.savedItem.deleteMany({
      where: {
        userId: user.id,
        itemType,
        itemId,
      },
    });

    return c.json({ success: true });
  });

  // GET /:itemType - List saved items by type, grouped by category
  app.get("/:itemType", sessionMiddleware, async (c) => {
    const user = c.get("user");
    const prisma = c.get("prisma");
    const itemType = c.req.param("itemType");

    if (itemType === "catalog") {
      // Fetch saved item IDs for this user and type
      const savedItems = await prisma.savedItem.findMany({
        where: {
          userId: user.id,
          itemType: "catalog",
        },
        select: { itemId: true },
      });

      const itemIds = savedItems.map((s: any) => s.itemId);

      if (itemIds.length === 0) {
        return c.json({ groups: [] });
      }

      // Fetch full Organization data for saved items
      const orgs = await prisma.organization.findMany({
        where: { id: { in: itemIds } },
        include: {
          owner: {
            select: { id: true, name: true, image: true, userType: true },
          },
          ratings: {
            where: { userId: user.id },
            select: { score: true },
          },
        },
        orderBy: { name: "asc" },
      });

      // Fetch category icons
      const categories = await prisma.catalogCategory.findMany({
        select: { name: true, icon: true },
      });
      const categoryIconMap = new Map(
        categories.map((cat: any) => [cat.name, cat.icon])
      );

      // Group by category
      const groupMap = new Map<
        string,
        { category: string; icon: string | null; items: any[] }
      >();

      for (const org of orgs) {
        const category = (org as any).category;
        if (!groupMap.has(category)) {
          groupMap.set(category, {
            category,
            icon: categoryIconMap.get(category) ?? null,
            items: [],
          });
        }

        const userRating = (org as any).ratings?.[0]?.score ?? null;

        groupMap.get(category)!.items.push({
          id: org.id,
          name: (org as any).name,
          description: (org as any).description,
          category,
          address: (org as any).address,
          imageUrl: (org as any).imageUrl,
          averageRating: (org as any).averageRating,
          ratingCount: (org as any).ratingCount,
          tags: JSON.parse((org as any).tags),
          ageGroups: JSON.parse((org as any).ageGroups),
          specialNeeds: JSON.parse((org as any).specialNeeds),
          latitude: (org as any).latitude,
          longitude: (org as any).longitude,
          ownerId: (org as any).ownerId,
          owner: (org as any).owner,
          saved: true,
          userRating,
          createdAt: (org as any).createdAt.toISOString(),
        });
      }

      const groups = Array.from(groupMap.values()).map((g) => ({
        category: g.category,
        icon: g.icon,
        count: g.items.length,
        items: g.items,
      }));

      return c.json({ groups });
    }

    if (itemType === "event") {
      const savedItems = await prisma.savedItem.findMany({
        where: {
          userId: user.id,
          itemType: "event",
        },
        select: { itemId: true },
      });

      const itemIds = savedItems.map((s: any) => s.itemId);

      if (itemIds.length === 0) {
        return c.json({ groups: [] });
      }

      const events = await prisma.event.findMany({
        where: { id: { in: itemIds } },
        include: {
          organizer: {
            select: { id: true, name: true, image: true, userType: true },
          },
          _count: { select: { attendees: true } },
          ...(user
            ? {
                attendees: {
                  where: { userId: user.id },
                  select: { id: true },
                },
              }
            : {}),
        },
        orderBy: { startDate: "asc" },
      });

      // Group by category
      const groupMap = new Map<
        string,
        { category: string; icon: string | null; items: any[] }
      >();

      for (const event of events) {
        const category = (event as any).category;
        if (!groupMap.has(category)) {
          groupMap.set(category, {
            category,
            icon: null,
            items: [],
          });
        }

        groupMap.get(category)!.items.push({
          id: event.id,
          title: (event as any).title,
          description: (event as any).description,
          category,
          location: (event as any).location,
          startDate: (event as any).startDate.toISOString(),
          endDate: (event as any).endDate?.toISOString() ?? null,
          imageUrl: (event as any).imageUrl,
          isOnline: (event as any).isOnline,
          isFree: (event as any).isFree,
          price: (event as any).price,
          status: (event as any).status,
          organizerId: (event as any).organizerId,
          organizer: (event as any).organizer,
          attendeeCount: (event as any)._count?.attendees ?? 0,
          saved: true,
          rsvped: ((event as any).attendees?.length ?? 0) > 0,
          createdAt: (event as any).createdAt.toISOString(),
        });
      }

      const groups = Array.from(groupMap.values()).map((g) => ({
        category: g.category,
        icon: g.icon,
        count: g.items.length,
        items: g.items,
      }));

      return c.json({ groups });
    }

    if (itemType === "promotion") {
      const savedItems = await prisma.savedItem.findMany({
        where: {
          userId: user.id,
          itemType: "promotion",
        },
        select: { itemId: true },
      });

      const itemIds = savedItems.map((s: any) => s.itemId);

      if (itemIds.length === 0) {
        return c.json({ groups: [] });
      }

      const promotions = await prisma.promotion.findMany({
        where: { id: { in: itemIds } },
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
        orderBy: { createdAt: "desc" },
      });

      // Fetch promotion category icons
      const categories = await prisma.promotionCategory.findMany({
        select: { name: true, icon: true },
      });
      const categoryIconMap = new Map(
        categories.map((cat: any) => [cat.name, cat.icon])
      );

      // Group by category
      const groupMap = new Map<
        string,
        { category: string; icon: string | null; items: any[] }
      >();

      for (const promotion of promotions) {
        const category = (promotion as any).category;
        if (!groupMap.has(category)) {
          groupMap.set(category, {
            category,
            icon: categoryIconMap.get(category) ?? null,
            items: [],
          });
        }

        const liked = (promotion as any).reactions?.length > 0;
        const claimed = (promotion as any).claims?.length > 0;

        groupMap.get(category)!.items.push({
          id: promotion.id,
          title: (promotion as any).title,
          description: (promotion as any).description,
          category,
          discount: (promotion as any).discount,
          store: (promotion as any).store,
          brandLogoUrl: (promotion as any).brandLogoUrl,
          imageUrl: (promotion as any).imageUrl,
          expiresAt: (promotion as any).expiresAt?.toISOString() ?? null,
          validFrom: (promotion as any).validFrom.toISOString(),
          organizationId: (promotion as any).organizationId,
          createdById: (promotion as any).createdById,
          createdBy: (promotion as any).createdBy,
          likesCount: (promotion as any).likesCount,
          liked,
          claimed,
          saved: true,
          createdAt: (promotion as any).createdAt.toISOString(),
          updatedAt: (promotion as any).updatedAt.toISOString(),
        });
      }

      const groups = Array.from(groupMap.values()).map((g) => ({
        category: g.category,
        icon: g.icon,
        count: g.items.length,
        items: g.items,
      }));

      return c.json({ groups });
    }

    // For other unknown item types return empty groups
    return c.json({ groups: [] });
  });

  return app;
}
