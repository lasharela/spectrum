import { describe, it, expect, beforeEach } from "vitest";
import app from "../../src/index.js";
import { cleanDatabase, prisma } from "../setup.js";

const dbAvailable = !!prisma;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Create a user + session directly in the DB for test auth. */
async function createTestUser(
  overrides: Partial<{
    firstName: string;
    lastName: string;
    userType: string;
  }> = {}
) {
  const uid = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const user = await prisma!.user.create({
    data: {
      email: `test-${uid}@test.com`,
      name: `${overrides.firstName ?? "Test"} ${overrides.lastName ?? "User"}`,
      firstName: overrides.firstName ?? "Test",
      lastName: overrides.lastName ?? "User",
      userType: overrides.userType ?? "parent",
      emailVerified: false,
    },
  });

  const session = await prisma!.session.create({
    data: {
      userId: user.id,
      token: `test-token-${uid}`,
      expiresAt: new Date(Date.now() + 86_400_000),
    },
  });

  return { user, token: session.token };
}

function authHeaders(token: string): Record<string, string> {
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

async function grantAdmin(userId: string) {
  await prisma!.userRole.create({
    data: { userId, role: "ADMIN" },
  });
}

/** Convenience: create an event via the API and return parsed JSON body. */
async function createEvent(
  token: string,
  data?: Partial<{
    title: string;
    description: string;
    category: string;
    location: string;
    startDate: string;
    endDate: string;
    imageUrl: string;
    isOnline: boolean;
    isFree: boolean;
    price: string;
  }>
) {
  const res = await app.request("/api/events", {
    method: "POST",
    headers: authHeaders(token),
    body: JSON.stringify({
      title: data?.title ?? "Test Event",
      category: data?.category ?? "Workshop",
      startDate: data?.startDate ?? new Date(Date.now() + 86_400_000).toISOString(),
      ...(data?.description !== undefined ? { description: data.description } : {}),
      ...(data?.location !== undefined ? { location: data.location } : {}),
      ...(data?.endDate !== undefined ? { endDate: data.endDate } : {}),
      ...(data?.imageUrl !== undefined ? { imageUrl: data.imageUrl } : {}),
      ...(data?.isOnline !== undefined ? { isOnline: data.isOnline } : {}),
      ...(data?.isFree !== undefined ? { isFree: data.isFree } : {}),
      ...(data?.price !== undefined ? { price: data.price } : {}),
    }),
  });
  return { res, body: (await res.json()) as any };
}

/** Approve an event directly in the DB so it shows in default listings. */
async function approveEvent(eventId: string) {
  await prisma!.event.update({
    where: { id: eventId },
    data: { status: "approved" },
  });
}

// ---------------------------------------------------------------------------
// Events API — POST /api/events (create)
// ---------------------------------------------------------------------------

describe("Events API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  describe("POST /api/events", () => {
    it.skipIf(!dbAvailable)(
      "should create event with valid data, returns 201 with status pending",
      async () => {
        const { token } = await createTestUser();
        const futureDate = new Date(Date.now() + 86_400_000).toISOString();
        const { res, body } = await createEvent(token, {
          title: "Autism Awareness Workshop",
          description: "A workshop for families",
          category: "Workshop",
          location: "Community Center",
          startDate: futureDate,
          isOnline: false,
          isFree: true,
        });

        expect(res.status).toBe(201);
        expect(body.event).toBeDefined();
        expect(body.event.title).toBe("Autism Awareness Workshop");
        expect(body.event.description).toBe("A workshop for families");
        expect(body.event.category).toBe("Workshop");
        expect(body.event.location).toBe("Community Center");
        expect(body.event.status).toBe("pending");
        expect(body.event.isOnline).toBe(false);
        expect(body.event.isFree).toBe(true);
        expect(body.event.attendeeCount).toBe(0);
        expect(body.event.saved).toBe(false);
        expect(body.event.rsvped).toBe(false);
        expect(body.event.organizer).toBeDefined();
        expect(body.event.organizer.name).toBe("Test User");
        expect(body.event.id).toBeDefined();
        expect(body.event.createdAt).toBeDefined();
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/events", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            title: "No Auth Event",
            category: "Workshop",
            startDate: new Date(Date.now() + 86_400_000).toISOString(),
          }),
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject invalid data (missing title) with 400",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/events", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            // title is missing
            category: "Workshop",
            startDate: new Date(Date.now() + 86_400_000).toISOString(),
          }),
        });

        expect(res.status).toBe(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject invalid data (missing category) with 400",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/events", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "Missing Category",
            // category is missing
            startDate: new Date(Date.now() + 86_400_000).toISOString(),
          }),
        });

        expect(res.status).toBe(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject invalid data (missing startDate) with 400",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/events", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "Missing Start Date",
            category: "Workshop",
            // startDate is missing
          }),
        });

        expect(res.status).toBe(400);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/events (list)
  // -------------------------------------------------------------------------

  describe("GET /api/events", () => {
    it.skipIf(!dbAvailable)(
      "should return only approved events by default",
      async () => {
        const { token } = await createTestUser();

        // Create two events — both start as "pending"
        const { body: e1 } = await createEvent(token, {
          title: "Approved Event",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const { body: e2 } = await createEvent(token, {
          title: "Pending Event",
          startDate: new Date(Date.now() + 2 * 86_400_000).toISOString(),
        });

        // Approve only the first
        await approveEvent(e1.event.id);

        const res = await app.request("/api/events", { method: "GET" });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.events).toBeDefined();
        expect(body.events.length).toBe(1);
        expect(body.events[0].title).toBe("Approved Event");
        expect(body.events[0].status).toBe("approved");
      }
    );

    it.skipIf(!dbAvailable)(
      "should support ?mine=true to return user's events regardless of status",
      async () => {
        const { token } = await createTestUser();

        // Create two events — both pending
        await createEvent(token, {
          title: "My Pending Event",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        await createEvent(token, {
          title: "My Another Event",
          startDate: new Date(Date.now() + 2 * 86_400_000).toISOString(),
        });

        const res = await app.request("/api/events?mine=true", {
          method: "GET",
          headers: { Authorization: `Bearer ${token}` },
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.events.length).toBe(2);
        // Both pending events should be returned
        for (const event of body.events) {
          expect(event.status).toBe("pending");
        }
      }
    );

    it.skipIf(!dbAvailable)(
      "should filter by category",
      async () => {
        const { token } = await createTestUser();

        const { body: e1 } = await createEvent(token, {
          title: "Workshop Event",
          category: "Workshop",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const { body: e2 } = await createEvent(token, {
          title: "Social Event",
          category: "Social",
          startDate: new Date(Date.now() + 2 * 86_400_000).toISOString(),
        });

        // Approve both
        await approveEvent(e1.event.id);
        await approveEvent(e2.event.id);

        const res = await app.request("/api/events?category=Workshop", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.events.length).toBe(1);
        expect(body.events[0].title).toBe("Workshop Event");
        expect(body.events[0].category).toBe("Workshop");
      }
    );

    it.skipIf(!dbAvailable)(
      "should support search query ?q=",
      async () => {
        const { token } = await createTestUser();

        const { body: e1 } = await createEvent(token, {
          title: "Sensory Play Day",
          description: "Fun activities for kids",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const { body: e2 } = await createEvent(token, {
          title: "Parent Support Group",
          description: "Monthly meetup",
          startDate: new Date(Date.now() + 2 * 86_400_000).toISOString(),
        });

        await approveEvent(e1.event.id);
        await approveEvent(e2.event.id);

        const res = await app.request("/api/events?q=Sensory", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.events.length).toBe(1);
        expect(body.events[0].title).toBe("Sensory Play Day");
      }
    );

    it.skipIf(!dbAvailable)(
      "should paginate with cursor",
      async () => {
        const { token } = await createTestUser();

        // Create 3 approved events with ascending start dates
        const events = [];
        for (let i = 0; i < 3; i++) {
          const { body } = await createEvent(token, {
            title: `Event ${i + 1}`,
            startDate: new Date(Date.now() + (i + 1) * 86_400_000).toISOString(),
          });
          await approveEvent(body.event.id);
          events.push(body.event);
        }

        // First page with limit=2
        const res1 = await app.request("/api/events?limit=2", {
          method: "GET",
        });
        expect(res1.status).toBe(200);
        const page1 = (await res1.json()) as any;
        expect(page1.events.length).toBe(2);
        expect(page1.nextCursor).toBeDefined();
        expect(page1.nextCursor).not.toBeNull();

        // Second page using cursor
        const res2 = await app.request(
          `/api/events?limit=2&cursor=${page1.nextCursor}`,
          { method: "GET" }
        );
        expect(res2.status).toBe(200);
        const page2 = (await res2.json()) as any;
        expect(page2.events.length).toBe(1);
        expect(page2.nextCursor).toBeNull();

        // No overlap between pages
        const allIds = [
          ...page1.events.map((e: any) => e.id),
          ...page2.events.map((e: any) => e.id),
        ];
        expect(new Set(allIds).size).toBe(3);
      }
    );
  });

  // -------------------------------------------------------------------------
  // GET /api/events/:id (single event)
  // -------------------------------------------------------------------------

  describe("GET /api/events/:id", () => {
    it.skipIf(!dbAvailable)(
      "should return single event with organizer info",
      async () => {
        const { token } = await createTestUser({ firstName: "Jane", lastName: "Doe" });
        const { body: created } = await createEvent(token, {
          title: "Detailed Event",
          description: "Full description here",
          category: "Conference",
          location: "Main Hall",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}`, {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.event).toBeDefined();
        expect(body.event.id).toBe(eventId);
        expect(body.event.title).toBe("Detailed Event");
        expect(body.event.description).toBe("Full description here");
        expect(body.event.category).toBe("Conference");
        expect(body.event.location).toBe("Main Hall");
        expect(body.event.organizer).toBeDefined();
        expect(body.event.organizer.name).toBe("Jane Doe");
        expect(body.event.attendeeCount).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent event",
      async () => {
        const res = await app.request("/api/events/non-existent-id-12345", {
          method: "GET",
        });
        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Event not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // -------------------------------------------------------------------------
  // PUT /api/events/:id (update)
  // -------------------------------------------------------------------------

  describe("PUT /api/events/:id", () => {
    it.skipIf(!dbAvailable)(
      "should allow owner to update their event",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createEvent(token, {
          title: "Original Title",
          category: "Workshop",
          location: "Old Location",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}`, {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "Updated Title",
            location: "New Location",
          }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.event.title).toBe("Updated Title");
        expect(body.event.location).toBe("New Location");
        // Category should remain unchanged
        expect(body.event.category).toBe("Workshop");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 for non-owner",
      async () => {
        const owner = await createTestUser({ firstName: "Owner" });
        const other = await createTestUser({ firstName: "Other" });

        const { body: created } = await createEvent(owner.token, {
          title: "Owner's Event",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}`, {
          method: "PUT",
          headers: authHeaders(other.token),
          body: JSON.stringify({ title: "Hacked Title" }),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent event",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request("/api/events/non-existent-id-12345", {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({ title: "Nope" }),
        });

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Event not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // -------------------------------------------------------------------------
  // DELETE /api/events/:id
  // -------------------------------------------------------------------------

  describe("DELETE /api/events/:id", () => {
    it.skipIf(!dbAvailable)(
      "should allow owner to delete their event",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createEvent(token, {
          title: "Deletable Event",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}`, {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.success).toBe(true);

        // Verify it's actually gone
        const check = await app.request(`/api/events/${eventId}`, {
          method: "GET",
        });
        expect(check.status).toBe(404);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 for non-owner",
      async () => {
        const owner = await createTestUser({ firstName: "Owner" });
        const other = await createTestUser({ firstName: "Other" });

        const { body: created } = await createEvent(owner.token, {
          title: "Not Yours",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}`, {
          method: "DELETE",
          headers: authHeaders(other.token),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );
  });

  // -------------------------------------------------------------------------
  // RSVP endpoints
  // -------------------------------------------------------------------------

  describe("POST /api/events/:id/rsvp", () => {
    it.skipIf(!dbAvailable)(
      "should create attendance, returns rsvped: true + count",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createEvent(token, {
          title: "RSVP Event",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}/rsvp`, {
          method: "POST",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.rsvped).toBe(true);
        expect(body.attendeeCount).toBe(1);
      }
    );

    it.skipIf(!dbAvailable)(
      "should be idempotent (RSVP twice returns same count)",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createEvent(token, {
          title: "Idempotent RSVP",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        // RSVP once
        const first = await app.request(`/api/events/${eventId}/rsvp`, {
          method: "POST",
          headers: authHeaders(token),
        });
        const firstBody = (await first.json()) as any;
        expect(firstBody.rsvped).toBe(true);
        expect(firstBody.attendeeCount).toBe(1);

        // RSVP again — should be idempotent
        const second = await app.request(`/api/events/${eventId}/rsvp`, {
          method: "POST",
          headers: authHeaders(token),
        });
        const secondBody = (await second.json()) as any;
        expect(secondBody.rsvped).toBe(true);
        expect(secondBody.attendeeCount).toBe(1);
      }
    );
  });

  describe("DELETE /api/events/:id/rsvp", () => {
    it.skipIf(!dbAvailable)(
      "should remove attendance, returns rsvped: false + count",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createEvent(token, {
          title: "Un-RSVP Event",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        // RSVP first
        await app.request(`/api/events/${eventId}/rsvp`, {
          method: "POST",
          headers: authHeaders(token),
        });

        // Then cancel RSVP
        const res = await app.request(`/api/events/${eventId}/rsvp`, {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.rsvped).toBe(false);
        expect(body.attendeeCount).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should be idempotent when not attending",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createEvent(token, {
          title: "Never RSVP'd",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        // Delete RSVP without having RSVP'd — should be idempotent
        const res = await app.request(`/api/events/${eventId}/rsvp`, {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.rsvped).toBe(false);
        expect(body.attendeeCount).toBe(0);
      }
    );
  });

  // -------------------------------------------------------------------------
  // PUT /api/events/:id/approve (admin)
  // -------------------------------------------------------------------------

  describe("PUT /api/events/:id/approve", () => {
    it.skipIf(!dbAvailable)(
      "should allow admin to approve event",
      async () => {
        const organizer = await createTestUser({ firstName: "Organizer" });
        const admin = await createTestUser({ firstName: "Admin" });
        await grantAdmin(admin.user.id);

        const { body: created } = await createEvent(organizer.token, {
          title: "Needs Approval",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;
        expect(created.event.status).toBe("pending");

        const res = await app.request(`/api/events/${eventId}/approve`, {
          method: "PUT",
          headers: authHeaders(admin.token),
          body: JSON.stringify({ status: "approved" }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.event.status).toBe("approved");
        expect(body.event.id).toBe(eventId);
      }
    );

    it.skipIf(!dbAvailable)(
      "should allow admin to reject event",
      async () => {
        const organizer = await createTestUser({ firstName: "Organizer" });
        const admin = await createTestUser({ firstName: "Admin" });
        await grantAdmin(admin.user.id);

        const { body: created } = await createEvent(organizer.token, {
          title: "Will Be Rejected",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}/approve`, {
          method: "PUT",
          headers: authHeaders(admin.token),
          body: JSON.stringify({ status: "rejected" }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.event.status).toBe("rejected");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 for non-admin",
      async () => {
        const organizer = await createTestUser({ firstName: "Organizer" });
        const regularUser = await createTestUser({ firstName: "Regular" });

        const { body: created } = await createEvent(organizer.token, {
          title: "Cannot Approve",
          startDate: new Date(Date.now() + 86_400_000).toISOString(),
        });
        const eventId = created.event.id;

        const res = await app.request(`/api/events/${eventId}/approve`, {
          method: "PUT",
          headers: authHeaders(regularUser.token),
          body: JSON.stringify({ status: "approved" }),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent event",
      async () => {
        const admin = await createTestUser({ firstName: "Admin" });
        await grantAdmin(admin.user.id);

        const res = await app.request(
          "/api/events/non-existent-id-12345/approve",
          {
            method: "PUT",
            headers: authHeaders(admin.token),
            body: JSON.stringify({ status: "approved" }),
          }
        );

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Event not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });
});
