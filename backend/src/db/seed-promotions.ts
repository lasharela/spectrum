import { PrismaClient } from "@prisma/client";

// This script seeds sample promotions.
// Usage: npx tsx src/db/seed-promotions.ts

const prisma = new PrismaClient();

async function main() {
  // Fetch existing users for createdBy references
  const users = await prisma.user.findMany({ take: 3 });
  if (users.length === 0) {
    console.log("No users found — run seed.ts first. Skipping sample promotions.");
    return;
  }

  const owner = users[0];
  const now = new Date();

  const promotions = [
    {
      title: "Free Initial Consultation for ABA Therapy",
      description:
        "Book a free 30-minute consultation with our certified ABA therapists. " +
        "We specialize in working with children on the autism spectrum, providing " +
        "individualized behavior plans and parent training.",
      category: "Health & Wellness",
      discount: "FREE",
      store: "Bright Futures ABA",
      expiresAt: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000), // +14 days
      validFrom: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
      createdById: owner.id,
      likesCount: 42,
    },
    {
      title: "20% Off Sensory-Friendly Dining Experience",
      description:
        "Enjoy our quiet dining experience with dim lighting, noise-canceling " +
        "headphones available, and a picture menu. Valid for dine-in only.",
      category: "Food & Dining",
      discount: "20% OFF",
      store: "The Sensory Café",
      expiresAt: new Date(now.getTime() + 5 * 60 * 60 * 1000), // +5 hours
      validFrom: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000),
      createdById: owner.id,
      likesCount: 18,
    },
    {
      title: "Back-to-School Special: Sensory Kit Bundle",
      description:
        "Complete sensory kit with fidget tools, noise-canceling earmuffs, " +
        "weighted lap pad, and visual schedule cards. Perfect for the new school year.",
      category: "Education",
      discount: "30% OFF",
      store: "Spectrum Supplies",
      expiresAt: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000), // +30 days
      validFrom: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000),
      createdById: owner.id,
      likesCount: 67,
    },
    {
      title: "Family Movie Night — Sensory Screening",
      description:
        "Monthly sensory-friendly movie screenings with reduced volume, " +
        "brighter lights, and freedom to move around. All families welcome.",
      category: "Entertainment",
      discount: null,
      store: "Bay Cinema",
      expiresAt: null, // permanent
      validFrom: new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000),
      createdById: owner.id,
      likesCount: 95,
    },
    {
      title: "Free Developmental Screening for Ages 2-5",
      description:
        "Quick 15-minute developmental screening to identify early signs of " +
        "autism. No referral needed. Walk-ins welcome on Wednesdays.",
      category: "Health & Wellness",
      discount: "FREE",
      store: "Bay Area Discovery Center",
      expiresAt: null, // permanent
      validFrom: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000),
      createdById: owner.id,
      likesCount: 124,
    },
    {
      title: "Home Organization — Autism-Friendly Spaces",
      description:
        "Professional organizer specializing in creating structured, calming " +
        "environments for children with autism. Includes visual labels and zones.",
      category: "Services",
      discount: "15% OFF",
      store: "Calm Spaces Co.",
      expiresAt: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000), // +7 days
      validFrom: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000),
      createdById: owner.id,
      likesCount: 31,
    },
  ];

  for (const promo of promotions) {
    await prisma.promotion.create({ data: promo });
  }

  console.log(`Seeded ${promotions.length} sample promotions.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
