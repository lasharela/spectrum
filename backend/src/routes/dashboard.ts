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
        { id: "p1", title: "50% Off Sensory Toys", store: "Learning Express", discount: "50%", imageUrl: "https://picsum.photos/seed/toys/400/200", brandLogoUrl: "https://picsum.photos/seed/learning/100/100", expiresAt: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString() },
        { id: "p2", title: "Free Initial Therapy Session for New Families — Limited Time Holiday Offer", store: "Wellness Center", discount: "FREE", imageUrl: "https://picsum.photos/seed/wellness/400/200", brandLogoUrl: "https://picsum.photos/seed/wellnesslogo/100/100", expiresAt: new Date(Date.now() + 5 * 60 * 60 * 1000).toISOString() },
        { id: "p3", title: "Buy 1 Get 1 Books", store: "Barnes & Noble", discount: "BOGO", imageUrl: "https://picsum.photos/seed/books/400/200", brandLogoUrl: "https://picsum.photos/seed/barnes/100/100", expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() },
      ],
      places: [
        { id: "pl1", name: "Sensory Garden Park", address: "123 Oak Street", distance: "0.5 miles", imageUrl: "https://picsum.photos/seed/park/200/300" },
        { id: "pl2", name: "Quiet Library Zone", address: "456 Main Avenue", distance: "1.2 miles", imageUrl: "https://picsum.photos/seed/library/200/300" },
        { id: "pl3", name: "Therapy Center", address: "789 Wellness Blvd", distance: "2.0 miles", imageUrl: "https://picsum.photos/seed/therapy/200/300" },
      ],
      upcomingEvents: [
        { id: "e1", title: "Parent Support Group", time: "10:00 AM", location: "Community Center", category: "Support", imageUrl: "https://picsum.photos/seed/support/200/300" },
        { id: "e2", title: "Art Therapy Session", time: "2:00 PM", location: "Creative Studio", category: "Therapy", imageUrl: "https://picsum.photos/seed/art/200/300" },
      ],
      stats: {
        postsCount,
      },
    });
  });

  return app;
}
