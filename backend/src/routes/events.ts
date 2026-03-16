import { Hono } from "hono";
import { z } from "zod";
import {
  sessionMiddleware,
  optionalSessionMiddleware,
} from "../middleware/session.js";
import type { AppBindings, AppVariables } from "../types/context.js";

const createEventSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  category: z.string().min(1),
  location: z.string().optional(),
  startDate: z.string().datetime(),
  endDate: z.string().datetime().optional(),
  imageUrl: z.string().url().optional(),
  isOnline: z.boolean().default(false),
  isFree: z.boolean().default(true),
  price: z.string().optional(),
});

const updateEventSchema = createEventSchema.partial();

const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(50).default(20),
  q: z.string().optional(),
  category: z.string().optional(),
  isOnline: z.string().optional(),
  isFree: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  mine: z.string().optional(),
});

const approveSchema = z.object({
  status: z.enum(["approved", "rejected"]),
});

function mapEvent(event: any, saved: boolean, rsvped: boolean) {
  return {
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
    saved,
    rsvped,
    createdAt: event.createdAt.toISOString(),
  };
}

export function eventsRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // GET / - list events (paginated, filterable)
  app.get("/", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const query = paginationSchema.parse({
      cursor: c.req.query("cursor"),
      limit: c.req.query("limit"),
      q: c.req.query("q"),
      category: c.req.query("category"),
      isOnline: c.req.query("isOnline"),
      isFree: c.req.query("isFree"),
      from: c.req.query("from"),
      to: c.req.query("to"),
      mine: c.req.query("mine"),
    });

    const user = c.get("user") as any;

    const where: Record<string, unknown> = {};

    // "mine" mode: show all events by the authenticated user regardless of status
    if (query.mine === "true") {
      if (!user) {
        return c.json({ error: "Authentication required", code: "UNAUTHORIZED" }, 401);
      }
      where.organizerId = user.id;
    } else {
      where.status = "approved";
    }

    if (query.q) {
      where.OR = [
        { title: { contains: query.q } },
        { description: { contains: query.q } },
      ];
    }
    if (query.category) {
      where.category = query.category;
    }
    if (query.isOnline === "true") {
      where.isOnline = true;
    } else if (query.isOnline === "false") {
      where.isOnline = false;
    }
    if (query.isFree === "true") {
      where.isFree = true;
    } else if (query.isFree === "false") {
      where.isFree = false;
    }
    if (query.from || query.to) {
      const startDateFilter: Record<string, unknown> = {};
      if (query.from) {
        startDateFilter.gte = new Date(query.from);
      }
      if (query.to) {
        startDateFilter.lte = new Date(query.to);
      }
      where.startDate = startDateFilter;
    }

    const events = await prisma.event.findMany({
      where,
      take: query.limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      orderBy: { startDate: "asc" },
      include: {
        organizer: {
          select: { id: true, name: true, image: true, userType: true },
        },
        _count: {
          select: { attendees: true },
        },
      },
    });

    const hasMore = events.length > query.limit;
    const results = hasMore ? events.slice(0, query.limit) : events;

    // Check saved and RSVP status for authenticated users
    let savedIds = new Set<string>();
    let rsvpedIds = new Set<string>();
    if (user && results.length > 0) {
      const eventIds = results.map((e: any) => e.id);

      const [savedItems, rsvpItems] = await Promise.all([
        prisma.savedItem.findMany({
          where: {
            userId: user.id,
            itemType: "event",
            itemId: { in: eventIds },
          },
          select: { itemId: true },
        }),
        prisma.eventAttendee.findMany({
          where: {
            userId: user.id,
            eventId: { in: eventIds },
          },
          select: { eventId: true },
        }),
      ]);

      savedIds = new Set(savedItems.map((s: any) => s.itemId));
      rsvpedIds = new Set(rsvpItems.map((r: any) => r.eventId));
    }

    const nextCursor = hasMore ? results[results.length - 1]?.id ?? null : null;

    return c.json({
      events: results.map((event: any) =>
        mapEvent(
          event,
          savedIds.has(event.id),
          rsvpedIds.has(event.id)
        )
      ),
      nextCursor,
    });
  });

  // GET /:id - get single event
  app.get("/:id", optionalSessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const prisma = c.get("prisma");
    const user = c.get("user") as any;

    const event = await prisma.event.findUnique({
      where: { id },
      include: {
        organizer: {
          select: { id: true, name: true, image: true, userType: true },
        },
        _count: {
          select: { attendees: true },
        },
      },
    });

    if (!event) {
      return c.json(
        { error: "Event not found", code: "NOT_FOUND" },
        404
      );
    }

    // Check saved and RSVP status
    let saved = false;
    let rsvped = false;
    if (user) {
      const [savedItem, rsvpItem] = await Promise.all([
        prisma.savedItem.findUnique({
          where: {
            userId_itemType_itemId: {
              userId: user.id,
              itemType: "event",
              itemId: id,
            },
          },
        }),
        prisma.eventAttendee.findUnique({
          where: {
            eventId_userId: {
              eventId: id,
              userId: user.id,
            },
          },
        }),
      ]);
      saved = !!savedItem;
      rsvped = !!rsvpItem;
    }

    return c.json({
      event: mapEvent(event, saved, rsvped),
    });
  });

  // POST / - create event
  app.post("/", sessionMiddleware, async (c) => {
    const user = c.get("user");
    const prisma = c.get("prisma");

    const body = createEventSchema.parse(await c.req.json());

    const event = await prisma.event.create({
      data: {
        title: body.title,
        description: body.description,
        category: body.category,
        location: body.location,
        startDate: new Date(body.startDate),
        endDate: body.endDate ? new Date(body.endDate) : undefined,
        imageUrl: body.imageUrl,
        isOnline: body.isOnline,
        isFree: body.isFree,
        price: body.price,
        status: "pending",
        organizerId: user.id,
      },
      include: {
        organizer: {
          select: { id: true, name: true, image: true, userType: true },
        },
        _count: {
          select: { attendees: true },
        },
      },
    });

    return c.json(
      { event: mapEvent(event, false, false) },
      201
    );
  });

  // PUT /:id - update event (owner only)
  app.put("/:id", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const event = await prisma.event.findUnique({ where: { id } });

    if (!event) {
      return c.json(
        { error: "Event not found", code: "NOT_FOUND" },
        404
      );
    }

    if (event.organizerId !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    const body = updateEventSchema.parse(await c.req.json());

    const updated = await prisma.event.update({
      where: { id },
      data: {
        ...(body.title !== undefined ? { title: body.title } : {}),
        ...(body.description !== undefined
          ? { description: body.description }
          : {}),
        ...(body.category !== undefined ? { category: body.category } : {}),
        ...(body.location !== undefined ? { location: body.location } : {}),
        ...(body.startDate !== undefined
          ? { startDate: new Date(body.startDate) }
          : {}),
        ...(body.endDate !== undefined
          ? { endDate: new Date(body.endDate) }
          : {}),
        ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
        ...(body.isOnline !== undefined ? { isOnline: body.isOnline } : {}),
        ...(body.isFree !== undefined ? { isFree: body.isFree } : {}),
        ...(body.price !== undefined ? { price: body.price } : {}),
      },
      include: {
        organizer: {
          select: { id: true, name: true, image: true, userType: true },
        },
        _count: {
          select: { attendees: true },
        },
      },
    });

    // Check saved and RSVP status
    const [savedItem, rsvpItem] = await Promise.all([
      prisma.savedItem.findUnique({
        where: {
          userId_itemType_itemId: {
            userId: user.id,
            itemType: "event",
            itemId: id,
          },
        },
      }),
      prisma.eventAttendee.findUnique({
        where: {
          eventId_userId: {
            eventId: id,
            userId: user.id,
          },
        },
      }),
    ]);

    return c.json({
      event: mapEvent(updated, !!savedItem, !!rsvpItem),
    });
  });

  // DELETE /:id - delete event (owner only)
  app.delete("/:id", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const event = await prisma.event.findUnique({ where: { id } });

    if (!event) {
      return c.json(
        { error: "Event not found", code: "NOT_FOUND" },
        404
      );
    }

    if (event.organizerId !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    await prisma.event.delete({ where: { id } });

    return c.json({ success: true });
  });

  // POST /:id/rsvp - RSVP to event
  app.post("/:id/rsvp", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const event = await prisma.event.findUnique({ where: { id } });
    if (!event) {
      return c.json(
        { error: "Event not found", code: "NOT_FOUND" },
        404
      );
    }

    await prisma.eventAttendee.upsert({
      where: {
        eventId_userId: {
          eventId: id,
          userId: user.id,
        },
      },
      update: {},
      create: {
        eventId: id,
        userId: user.id,
      },
    });

    const attendeeCount = await prisma.eventAttendee.count({
      where: { eventId: id },
    });

    return c.json({ rsvped: true, attendeeCount });
  });

  // DELETE /:id/rsvp - cancel RSVP
  app.delete("/:id/rsvp", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const event = await prisma.event.findUnique({ where: { id } });
    if (!event) {
      return c.json(
        { error: "Event not found", code: "NOT_FOUND" },
        404
      );
    }

    await prisma.eventAttendee.deleteMany({
      where: {
        eventId: id,
        userId: user.id,
      },
    });

    const attendeeCount = await prisma.eventAttendee.count({
      where: { eventId: id },
    });

    return c.json({ rsvped: false, attendeeCount });
  });

  // PUT /:id/approve - approve/reject event (ADMIN only)
  app.put("/:id/approve", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    // Check if user has ADMIN role
    const adminRole = await prisma.userRole.findUnique({
      where: {
        userId_role: {
          userId: user.id,
          role: "ADMIN",
        },
      },
    });

    if (!adminRole) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    const event = await prisma.event.findUnique({ where: { id } });
    if (!event) {
      return c.json(
        { error: "Event not found", code: "NOT_FOUND" },
        404
      );
    }

    const { status } = approveSchema.parse(await c.req.json());

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

    // Check saved and RSVP status for admin
    const [savedItem, rsvpItem] = await Promise.all([
      prisma.savedItem.findUnique({
        where: {
          userId_itemType_itemId: {
            userId: user.id,
            itemType: "event",
            itemId: id,
          },
        },
      }),
      prisma.eventAttendee.findUnique({
        where: {
          eventId_userId: {
            eventId: id,
            userId: user.id,
          },
        },
      }),
    ]);

    return c.json({
      event: mapEvent(updated, !!savedItem, !!rsvpItem),
    });
  });

  return app;
}
