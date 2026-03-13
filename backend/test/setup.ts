import { PrismaClient } from "@prisma/client";

const prisma = process.env.DATABASE_URL
  ? new PrismaClient()
  : (null as unknown as PrismaClient);

export { prisma };

export async function cleanDatabase() {
  if (!prisma) {
    // No database connection available — skip cleanup
    return;
  }
  await prisma.reaction.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.post.deleteMany();
  await prisma.session.deleteMany();
  await prisma.account.deleteMany();
  await prisma.verification.deleteMany();
  await prisma.user.deleteMany();
}
