import { Hono } from "hono";
import { cors } from "hono/cors";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { createPrismaClient } from "./db/client.js";
import { createAuth } from "./auth/auth.js";
import { sessionMiddleware } from "./middleware/session.js";
import { communityRoutes } from "./routes/community.js";
import { dashboardRoutes } from "./routes/dashboard.js";
import { filterRoutes } from "./routes/filters.js";
import { catalogRoutes } from "./routes/catalog.js";
import { savedRoutes } from "./routes/saved.js";
import { eventsRoutes } from "./routes/events.js";
import { promotionRoutes } from "./routes/promotions.js";
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
  const baseURL = c.env.ENVIRONMENT === "production" ? "https://api.myspectrum.app" : undefined;
  const auth = createAuth(prisma, c.env.BETTER_AUTH_SECRET, baseURL);
  c.set("prisma", prisma);
  c.set("auth", auth);
  await next();
});

// Auth routes — Better Auth handler
app.on(["GET", "POST"], "/api/auth/**", async (c) => {
  const auth = c.get("auth");
  try {
    const response = await auth.handler(c.req.raw);
    // Better Auth may return 500 with empty body on internal errors — ensure a JSON body
    if (response.status >= 500 && response.headers.get("content-length") === "0") {
      console.error("Auth handler returned empty 500 response for:", c.req.url);
      return c.json(
        { message: "Authentication service error", code: "AUTH_ERROR" },
        500
      );
    }
    return response;
  } catch (err) {
    console.error("Auth handler error:", err);
    return c.json(
      { message: "Authentication error", code: "AUTH_ERROR" },
      500
    );
  }
});

// Profile endpoints
app.get("/api/me", sessionMiddleware, async (c) => {
  const user = c.get("user");
  return c.json({ user });
});

const updateProfileSchema = z.object({
  firstName: z.string().min(1).max(100).optional(),
  lastName: z.string().min(1).max(100).optional(),
  middleName: z.string().max(100).nullable().optional(),
  state: z.string().max(100).nullable().optional(),
  city: z.string().max(100).nullable().optional(),
});

app.put("/api/me", sessionMiddleware, zValidator("json", updateProfileSchema), async (c) => {
  const user = c.get("user");
  const prisma = c.get("prisma");
  const body = c.req.valid("json");

  const data: Record<string, unknown> = {};
  if (body.firstName !== undefined) data.firstName = body.firstName;
  if (body.lastName !== undefined) data.lastName = body.lastName;
  if (body.middleName !== undefined) data.middleName = body.middleName;
  if (body.state !== undefined) {
    data.state = body.state;
    // Clear city when state changes
    if (body.city === undefined) data.city = null;
  }
  if (body.city !== undefined) data.city = body.city;

  // Update name if first/last name changed
  if (body.firstName !== undefined || body.lastName !== undefined) {
    const currentUser = await prisma.user.findUnique({ where: { id: user.id } });
    const first = body.firstName ?? currentUser!.firstName;
    const middle = body.middleName !== undefined ? body.middleName : currentUser!.middleName;
    const last = body.lastName ?? currentUser!.lastName;
    data.name = [first, middle, last].filter(Boolean).join(" ");
  }

  const updated = await prisma.user.update({
    where: { id: user.id },
    data,
  });

  return c.json({
    user: {
      id: updated.id,
      email: updated.email,
      name: updated.name,
      firstName: updated.firstName,
      middleName: updated.middleName,
      lastName: updated.lastName,
      userType: updated.userType,
      state: updated.state,
      city: updated.city,
      image: updated.image,
      createdAt: updated.createdAt.toISOString(),
    },
  });
});

// Cities endpoint — returns distinct cities from user profiles for a given state
app.get("/api/cities", sessionMiddleware, async (c) => {
  const state = c.req.query("state");
  if (!state) return c.json({ cities: [] });

  const prisma = c.get("prisma");
  const users = await prisma.user.findMany({
    where: { state, city: { not: null } },
    select: { city: true },
  });

  const cities = [...new Set(users.map((u: { city: string | null }) => u.city).filter(Boolean))].sort();
  return c.json({ cities });
});

// Community routes
app.route("/api/posts", communityRoutes());
app.route("/api/dashboard", dashboardRoutes());
app.route("/api/filters", filterRoutes());
app.route("/api/catalog", catalogRoutes());
app.route("/api/saved", savedRoutes());
app.route("/api/events", eventsRoutes());
app.route("/api/promotions", promotionRoutes());

// Global error handler
app.onError((err, c) => {
  console.error(err);
  return c.json({ error: "Internal server error", code: "INTERNAL_ERROR" }, 500);
});

export default app;
