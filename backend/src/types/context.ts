import type { PrismaClient } from "@prisma/client/edge";
import type { Auth } from "../auth/auth.js";

export type UserContext = {
  id: string;
  email: string;
  name: string;
  userType: string;
  image: string | null;
};

export type AppBindings = {
  DATABASE_URL: string;
  BETTER_AUTH_SECRET: string;
  ENVIRONMENT: string;
};

export type AppVariables = {
  user: UserContext;
  prisma: PrismaClient;
  auth: Auth;
};
