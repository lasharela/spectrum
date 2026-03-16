import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { bearer } from "better-auth/plugins/bearer";
import type { PrismaClient } from "@prisma/client";

export function createAuth(prisma: PrismaClient, secret: string, baseURL?: string) {
  return betterAuth({
    secret,
    baseURL: baseURL ?? "http://localhost:8788",
    trustedOrigins: ["http://localhost:*", "https://api.myspectrum.app", "https://web.myspectrum.app", "https://*.spectrum-web.pages.dev"],
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
        state: {
          type: "string",
          required: false,
          input: true,
        },
        city: {
          type: "string",
          required: false,
          input: true,
        },
      },
    },
  });
}

export type Auth = ReturnType<typeof createAuth>;
