import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { bearer } from "better-auth/plugins/bearer";
import type { PrismaClient } from "@prisma/client";

export function createAuth(prisma: PrismaClient, secret: string) {
  return betterAuth({
    secret,
    trustedOrigins: ["http://localhost:*"],
    database: prismaAdapter(prisma, {
      provider: "sqlite",
    }),
    plugins: [bearer()],
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
        firstName: {
          type: "string",
          required: true,
          input: true,
        },
        middleName: {
          type: "string",
          required: false,
          input: true,
        },
        lastName: {
          type: "string",
          required: true,
          input: true,
        },
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
