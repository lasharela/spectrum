import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import type { PrismaClient } from "@prisma/client";

export function createAuth(prisma: PrismaClient, secret: string) {
  return betterAuth({
    secret,
    database: prismaAdapter(prisma, {
      provider: "sqlite",
    }),
    emailAndPassword: {
      enabled: true,
    },
    user: {
      additionalFields: {
        userType: {
          type: "string",
          required: true,
          input: true,
        },
      },
    },
  });
}

export type Auth = ReturnType<typeof createAuth>;
