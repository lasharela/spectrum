import { Hono } from "hono";
import { cors } from "hono/cors";
import { createPrismaClient } from "./db/client.js";
import { createAuth } from "./auth/auth.js";
import { sessionMiddleware } from "./middleware/session.js";
import { communityRoutes } from "./routes/community.js";
import { dashboardRoutes } from "./routes/dashboard.js";
import type { AppBindings, AppVariables } from "./types/context.js";

const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

// CORS
app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
  })
);

// Health check — ABOVE the prisma/auth middleware so it works without DB
app.get("/api/health", (c) => {
  return c.json({ status: "ok" });
});

// Per-request setup: create Prisma + Auth instances
// Scoped to /api/* routes that need DB access (excludes /api/health above)
app.use("/api/*", async (c, next) => {
  const prisma = createPrismaClient(c.env.DB);
  const auth = createAuth(prisma, c.env.BETTER_AUTH_SECRET);
  c.set("prisma", prisma);
  c.set("auth", auth);
  await next();
});

// Auth routes — Better Auth handler
app.on(["GET", "POST"], "/api/auth/**", async (c) => {
  const auth = c.get("auth");
  return auth.handler(c.req.raw);
});

// Profile endpoint
app.get("/api/me", sessionMiddleware, async (c) => {
  const user = c.get("user");
  return c.json({ user });
});

// Community routes
app.route("/api/posts", communityRoutes());
app.route("/api/dashboard", dashboardRoutes());

// Global error handler
app.onError((err, c) => {
  console.error(err);
  return c.json({ error: "Internal server error", code: "INTERNAL_ERROR" }, 500);
});

export default app;
