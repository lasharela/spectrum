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
      sendResetPassword: async (data, request) => {
        console.log(
          `[DEV] Password reset for ${data.user.email}: ${data.url}`
        );
      },
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
