import { Hono } from "hono";
import { z } from "zod";
import { sessionMiddleware } from "../middleware/session.js";
import type { AppBindings, AppVariables } from "../types/context.js";

const saveItemSchema = z.object({
  itemType: z.enum(["catalog", "promotion"]),
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

    // For other types (promotion, etc.) return empty groups for now
    return c.json({ groups: [] });
  });

  return app;
}
