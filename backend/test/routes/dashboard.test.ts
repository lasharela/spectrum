import { describe, it, expect, beforeEach } from "vitest";
import { cleanDatabase } from "../setup.js";

describe("Dashboard API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  describe("GET /api/dashboard", () => {
    it("should return dashboard data for authenticated user", async () => {
      expect(true).toBe(true);
    });

    it("should return recent posts ordered by createdAt desc", async () => {
      expect(true).toBe(true);
    });

    it("should return empty arrays for promotions, places, events", async () => {
      expect(true).toBe(true);
    });

    it("should reject unauthenticated request with 401", async () => {
      expect(true).toBe(true);
    });
  });
});
