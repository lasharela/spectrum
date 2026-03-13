import type { PrismaClient } from "@prisma/client";
import type { Auth } from "../auth/auth.js";

export type UserContext = {
  id: string;
  email: string;
  name: string;
  userType: string;
  image: string | null;
};

export type AppBindings = {
  DB: D1Database;
  BETTER_AUTH_SECRET: string;
  ENVIRONMENT: string;
};

export type AppVariables = {
  user: UserContext;
  prisma: PrismaClient;
  auth: Auth;
};
