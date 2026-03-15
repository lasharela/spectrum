import { Hono } from "hono";
import type { AppBindings, AppVariables } from "../types/context.js";

export function filterRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  app.get("/catalog-categories", async (c) => {
    const prisma = c.get("prisma");
    const categories = await prisma.catalogCategory.findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ categories });
  });

  app.get("/age-groups", async (c) => {
    const prisma = c.get("prisma");
    const ageGroups = await prisma.ageGroup.findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ ageGroups });
  });

  app.get("/special-needs", async (c) => {
    const prisma = c.get("prisma");
    const specialNeeds = await prisma.specialNeed.findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ specialNeeds });
  });

  return app;
}
