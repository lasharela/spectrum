import { createMiddleware } from "hono/factory";
import type { AppBindings, AppVariables } from "../types/context.js";

function setUserFromSession(c: any, session: any) {
  c.set("user", {
    id: session.user.id,
    email: session.user.email,
    name: session.user.name,
    firstName: (session.user as any).firstName,
    middleName: (session.user as any).middleName ?? null,
    lastName: (session.user as any).lastName,
    userType: (session.user as any).userType,
    image: session.user.image,
  });
}

export const sessionMiddleware = createMiddleware<{
  Bindings: AppBindings;
  Variables: AppVariables;
}>(async (c, next) => {
  const auth = c.get("auth");
  const session = await auth.api.getSession({
    headers: c.req.raw.headers,
  });

  if (!session) {
    return c.json(
      { error: "Not authenticated", code: "UNAUTHORIZED" },
      401
    );
  }

  setUserFromSession(c, session);
  await next();
});

export const optionalSessionMiddleware = createMiddleware<{
  Bindings: AppBindings;
  Variables: AppVariables;
}>(async (c, next) => {
  const auth = c.get("auth");
  try {
    const session = await auth.api.getSession({
      headers: c.req.raw.headers,
    });
    if (session) {
      setUserFromSession(c, session);
    }
  } catch {
    // No valid session — continue as unauthenticated
  }
  await next();
});
