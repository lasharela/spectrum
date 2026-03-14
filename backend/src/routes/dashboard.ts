import { Hono } from "hono";
import type { AppBindings, AppVariables } from "../types/context.js";
import { sessionMiddleware } from "../middleware/session.js";

export function dashboardRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  app.use("*", sessionMiddleware);

  // GET / - dashboard data for authenticated user
  app.get("/", async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");

    const [recentPosts, postsCount] = await Promise.all([
      prisma.post.findMany({
        take: 3,
        orderBy: { createdAt: "desc" },
        include: {
          author: { select: { id: true, name: true, image: true } },
        },
      }),
      prisma.post.count(),
    ]);

    return c.json({
      user: {
        name: user.name,
        userType: user.userType,
      },
      recentPosts: recentPosts.map((p) => ({
        id: p.id,
        content: p.content,
        authorName: p.author.name,
        authorImage: p.author.image,
        likesCount: p.likesCount,
        commentsCount: p.commentsCount,
        createdAt: p.createdAt.toISOString(),
      })),
      promotions: [],
      places: [],
      upcomingEvents: [],
      stats: {
        postsCount,
      },
    });
  });

  return app;
}
