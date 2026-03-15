import { describe, it, expect, beforeAll, afterAll, beforeEach } from "vitest";
import { request, flushLogs, resetLog, testEmail, BASE_URL } from "./helpers.js";

describe("Auth E2E", () => {
  // ─── Verify server is reachable ───────────────────────────────
  beforeAll(async () => {
    try {
      const res = await fetch(`${BASE_URL}/api/health`);
      if (!res.ok) throw new Error(`Health check returned ${res.status}`);
    } catch (err: any) {
      throw new Error(
        `Dev server not reachable at ${BASE_URL}. Start it with: pnpm dev:backend\n${err.message}`
      );
    }
  });

  beforeEach(() => resetLog());

  // ─── 1. Sign-up flow ─────────────────────────────────────────
  describe("Sign-up", () => {
    afterAll(() => flushLogs("signup"));

    it("should sign up a new user and return token + user", async () => {
      const email = testEmail();
      const res = await request("signup_new_user", "POST", "/api/auth/sign-up/email", {
        body: {
          email,
          password: "TestPass123!",
          name: "E2E Tester",
          firstName: "E2E",
          lastName: "Tester",
          userType: "parent",
        },
      });

      expect(res.status).toBe(200);
      expect(res.body.user).toBeDefined();
      expect(res.body.user.email).toBe(email);
      expect(res.body.user.firstName).toBe("E2E");
      expect(res.body.user.lastName).toBe("Tester");
      expect(res.body.token).toBeDefined();
      expect(typeof res.body.token).toBe("string");
      expect(res.body.token.length).toBeGreaterThan(0);
    });

    it("should reject sign-up with missing fields", async () => {
      const res = await request("signup_missing_fields", "POST", "/api/auth/sign-up/email", {
        body: {
          email: testEmail(),
          password: "TestPass123!",
          // missing name, firstName, lastName, userType
        },
      });

      // Better Auth should reject this
      expect(res.status).toBeGreaterThanOrEqual(400);
    });

    it("should reject duplicate email", async () => {
      const email = testEmail();
      // First sign-up
      await request("signup_first", "POST", "/api/auth/sign-up/email", {
        body: {
          email,
          password: "TestPass123!",
          name: "First User",
          firstName: "First",
          lastName: "User",
          userType: "parent",
        },
      });

      // Second sign-up with same email
      const res = await request("signup_duplicate", "POST", "/api/auth/sign-up/email", {
        body: {
          email,
          password: "OtherPass456!",
          name: "Second User",
          firstName: "Second",
          lastName: "User",
          userType: "parent",
        },
      });

      expect(res.status).toBeGreaterThanOrEqual(400);
    });
  });

  // ─── 2. Sign-in flow ─────────────────────────────────────────
  describe("Sign-in", () => {
    const email = `e2e-signin-${Date.now()}@test.com`;
    const password = "SecurePass789!";
    let signUpToken: string;

    beforeAll(async () => {
      resetLog();
      // Create user first
      const res = await request("signin_setup_signup", "POST", "/api/auth/sign-up/email", {
        body: {
          email,
          password,
          name: "Sign In Test",
          firstName: "Sign",
          lastName: "InTest",
          userType: "parent",
        },
      });
      signUpToken = res.body.token;
    });

    afterAll(() => flushLogs("signin"));

    it("should sign in with correct credentials", async () => {
      const res = await request("signin_valid", "POST", "/api/auth/sign-in/email", {
        body: { email, password },
      });

      expect(res.status).toBe(200);
      expect(res.body.user).toBeDefined();
      expect(res.body.user.email).toBe(email);
      expect(res.body.token).toBeDefined();
      expect(typeof res.body.token).toBe("string");
    });

    it("should reject sign-in with wrong password", async () => {
      const res = await request("signin_wrong_password", "POST", "/api/auth/sign-in/email", {
        body: { email, password: "WrongPassword!" },
      });

      expect(res.status).toBeGreaterThanOrEqual(400);
    });

    it("should reject sign-in with non-existent email", async () => {
      const res = await request("signin_nonexistent", "POST", "/api/auth/sign-in/email", {
        body: { email: "nobody-exists@test.com", password: "anything" },
      });

      expect(res.status).toBeGreaterThanOrEqual(400);
    });
  });

  // ─── 3. Session flow ─────────────────────────────────────────
  describe("Session", () => {
    const email = `e2e-session-${Date.now()}@test.com`;
    const password = "SessionPass321!";
    let token: string;

    beforeAll(async () => {
      resetLog();
      // Sign up
      const signupRes = await request("session_setup_signup", "POST", "/api/auth/sign-up/email", {
        body: {
          email,
          password,
          name: "Session Test",
          firstName: "Session",
          lastName: "Test",
          userType: "professional",
        },
      });
      token = signupRes.body.token;
    });

    afterAll(() => flushLogs("session"));

    it("should get session with valid token", async () => {
      const res = await request("session_valid", "GET", "/api/auth/get-session", {
        token,
      });

      expect(res.status).toBe(200);
      expect(res.body.user).toBeDefined();
      expect(res.body.user.email).toBe(email);
    });

    it("should get profile via /api/me with valid token", async () => {
      const res = await request("profile_valid", "GET", "/api/me", {
        token,
      });

      expect(res.status).toBe(200);
      expect(res.body.user).toBeDefined();
      expect(res.body.user.email).toBe(email);
      expect(res.body.user.firstName).toBe("Session");
    });

    it("should reject session with invalid token", async () => {
      const res = await request("session_invalid_token", "GET", "/api/auth/get-session", {
        token: "invalid-token-12345",
      });

      // Better Auth returns 200 with null body, or 401
      expect([200, 401]).toContain(res.status);
      if (res.status === 200) {
        // Body is null or session is null
        expect(res.body === null || res.body?.session === null).toBe(true);
      }
    });

    it("should reject /api/me without token", async () => {
      const res = await request("profile_no_token", "GET", "/api/me");

      expect(res.status).toBe(401);
    });
  });

  // ─── 4. Full flow: sign up → sign in → session → sign out ───
  describe("Full login lifecycle", () => {
    afterAll(() => flushLogs("full_lifecycle"));

    it("should complete the full auth lifecycle", async () => {
      const email = testEmail();
      const password = "LifecyclePass!99";

      // Step 1: Sign up
      const signup = await request("lifecycle_1_signup", "POST", "/api/auth/sign-up/email", {
        body: {
          email,
          password,
          name: "Lifecycle Test",
          firstName: "Lifecycle",
          lastName: "Test",
          userType: "educator",
        },
      });
      expect(signup.status).toBe(200);
      expect(signup.body.token).toBeDefined();
      const signupToken = signup.body.token;

      // Step 2: Verify session works with signup token
      const session1 = await request("lifecycle_2_session_after_signup", "GET", "/api/auth/get-session", {
        token: signupToken,
      });
      expect(session1.status).toBe(200);
      expect(session1.body.user.email).toBe(email);

      // Step 3: Sign out
      const signout = await request("lifecycle_3_signout", "POST", "/api/auth/sign-out", {
        token: signupToken,
        body: {},
      });
      expect(signout.status).toBe(200);

      // Step 4: Verify old token no longer works
      const session2 = await request("lifecycle_4_session_after_signout", "GET", "/api/auth/get-session", {
        token: signupToken,
      });
      // After sign-out, session should be invalid
      if (session2.status === 200) {
        expect(session2.body === null || session2.body?.session === null).toBe(true);
      } else {
        expect(session2.status).toBe(401);
      }

      // Step 5: Sign in again with credentials
      const signin = await request("lifecycle_5_signin", "POST", "/api/auth/sign-in/email", {
        body: { email, password },
      });
      expect(signin.status).toBe(200);
      expect(signin.body.token).toBeDefined();
      const signinToken = signin.body.token;

      // Step 6: Verify new session works
      const session3 = await request("lifecycle_6_session_after_signin", "GET", "/api/auth/get-session", {
        token: signinToken,
      });
      expect(session3.status).toBe(200);
      expect(session3.body.user.email).toBe(email);
    });
  });

  // ─── 5. Sign-up then sign-in round-trip ────────────────────────
  describe("Sign-up then sign-in round-trip", () => {
    afterAll(() => flushLogs("signup_signin_roundtrip"));

    it("should sign up a new user and immediately sign in with same credentials", async () => {
      const email = testEmail();
      const password = "RoundTrip!456";

      // Sign up
      const signup = await request("roundtrip_signup", "POST", "/api/auth/sign-up/email", {
        body: {
          email,
          password,
          name: "Round Trip",
          firstName: "Round",
          lastName: "Trip",
          userType: "parent",
        },
      });
      expect(signup.status).toBe(200);
      expect(signup.body.token).toBeDefined();

      // Sign in with same credentials
      const signin = await request("roundtrip_signin", "POST", "/api/auth/sign-in/email", {
        body: { email, password },
      });
      expect(signin.status).toBe(200);
      expect(signin.body.user.email).toBe(email);
      expect(signin.body.token).toBeDefined();

      // Verify session works
      const session = await request("roundtrip_session", "GET", "/api/me", {
        token: signin.body.token,
      });
      expect(session.status).toBe(200);
      expect(session.body.user.email).toBe(email);
    });
  });
});
