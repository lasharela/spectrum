import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import type { AppBindings, AppVariables } from "../types/context.js";
import { sessionMiddleware } from "../middleware/session.js";
import { adminMiddleware } from "../middleware/admin.js";

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------

const approveEventSchema = z.object({
  status: z.enum(["approved", "rejected"]),
});

// ---------------------------------------------------------------------------
// Main admin routes
// ---------------------------------------------------------------------------

export function adminRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // All admin routes require authentication + admin role
  app.use("*", sessionMiddleware, adminMiddleware);

  // =========================================================================
  // Event management
  // =========================================================================

  // GET /events/pending — list pending events
  app.get("/events/pending", async (c) => {
    const prisma = c.get("prisma");

    const events = await prisma.event.findMany({
      where: { status: "pending" },
      orderBy: { createdAt: "desc" },
      include: {
        organizer: {
          select: { id: true, name: true, image: true, userType: true },
        },
        _count: {
          select: { attendees: true },
        },
      },
    });

    return c.json({
      events: events.map((event: any) => ({
        id: event.id,
        title: event.title,
        description: event.description,
        category: event.category,
        location: event.location,
        startDate: event.startDate.toISOString(),
        endDate: event.endDate ? event.endDate.toISOString() : null,
        imageUrl: event.imageUrl,
        isOnline: event.isOnline,
        isFree: event.isFree,
        price: event.price,
        status: event.status,
        organizerId: event.organizerId,
        organizer: event.organizer,
        attendeeCount: event._count?.attendees ?? 0,
        createdAt: event.createdAt.toISOString(),
      })),
    });
  });

  // PUT /events/:id/approve — approve or reject an event
  app.put(
    "/events/:id/approve",
    zValidator("json", approveEventSchema),
    async (c) => {
      const id = c.req.param("id");
      const prisma = c.get("prisma");
      const { status } = c.req.valid("json");

      const event = await prisma.event.findUnique({ where: { id } });
      if (!event) {
        return c.json({ error: "Event not found", code: "NOT_FOUND" }, 404);
      }

      const updated = await prisma.event.update({
        where: { id },
        data: { status },
        include: {
          organizer: {
            select: { id: true, name: true, image: true, userType: true },
          },
          _count: {
            select: { attendees: true },
          },
        },
      });

      return c.json({
        event: {
          id: updated.id,
          title: updated.title,
          description: updated.description,
          category: updated.category,
          location: updated.location,
          startDate: updated.startDate.toISOString(),
          endDate: updated.endDate ? updated.endDate.toISOString() : null,
          imageUrl: updated.imageUrl,
          isOnline: updated.isOnline,
          isFree: updated.isFree,
          price: updated.price,
          status: updated.status,
          organizerId: updated.organizerId,
          organizer: updated.organizer,
          attendeeCount: updated._count?.attendees ?? 0,
          createdAt: updated.createdAt.toISOString(),
        },
      });
    }
  );

  return app;
}
