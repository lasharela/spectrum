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
  // Delete in dependency order (children before parents)
  await prisma.promotionClaim.deleteMany();
  await prisma.promotionReaction.deleteMany();
  await prisma.promotion.deleteMany();
  await prisma.eventAttendee.deleteMany();
  await prisma.event.deleteMany();
  await prisma.savedItem.deleteMany();
  await prisma.rating.deleteMany();
  await prisma.organization.deleteMany();
  await prisma.reaction.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.post.deleteMany();
  await prisma.userRole.deleteMany();
  await prisma.session.deleteMany();
  await prisma.account.deleteMany();
  await prisma.verification.deleteMany();
  await prisma.user.deleteMany();
}
