import { createMiddleware } from "hono/factory";
import type { AppBindings, AppVariables } from "../types/context.js";

export const adminMiddleware = createMiddleware<{
  Bindings: AppBindings;
  Variables: AppVariables;
}>(async (c, next) => {
  const user = c.get("user");
  if (!user) {
    return c.json({ error: "Not authenticated", code: "UNAUTHORIZED" }, 401);
  }

  const prisma = c.get("prisma");
  const adminRole = await prisma.userRole.findUnique({
    where: {
      userId_role: {
        userId: user.id,
        role: "ADMIN",
      },
    },
  });

  if (!adminRole) {
    return c.json({ error: "Admin access required", code: "FORBIDDEN" }, 403);
  }

  await next();
});
