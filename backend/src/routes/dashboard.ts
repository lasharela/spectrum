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
        firstName: user.firstName,
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
      promotions: [
        { id: "p1", title: "50% Off Sensory Toys", store: "Learning Express", discount: "50%" },
        { id: "p2", title: "Free Therapy Session", store: "Wellness Center", discount: "FREE" },
        { id: "p3", title: "Buy 1 Get 1 Books", store: "Barnes & Noble", discount: "BOGO" },
      ],
      places: [
        { id: "pl1", name: "Sensory Garden Park", address: "123 Oak Street", distance: "0.5 miles", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Park" },
        { id: "pl2", name: "Quiet Library Zone", address: "456 Main Avenue", distance: "1.2 miles", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Library" },
        { id: "pl3", name: "Therapy Center", address: "789 Wellness Blvd", distance: "2.0 miles", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Therapy" },
      ],
      upcomingEvents: [
        { id: "e1", title: "Parent Support Group", time: "10:00 AM", location: "Community Center", category: "Support", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Support" },
        { id: "e2", title: "Art Therapy Session", time: "2:00 PM", location: "Creative Studio", category: "Therapy", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Art" },
      ],
      stats: {
        postsCount,
      },
    });
  });

  return app;
}
