import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");

  const users = await Promise.all([
    prisma.user.upsert({
      where: { email: "sarah@example.com" },
      update: {},
      create: {
        email: "sarah@example.com",
        emailVerified: true,
        name: "Sarah M.",
        userType: "parent",
      },
    }),
    prisma.user.upsert({
      where: { email: "john@example.com" },
      update: {},
      create: {
        email: "john@example.com",
        emailVerified: true,
        name: "John D.",
        userType: "professional",
      },
    }),
    prisma.user.upsert({
      where: { email: "maria@example.com" },
      update: {},
      create: {
        email: "maria@example.com",
        emailVerified: true,
        name: "Maria L.",
        userType: "educator",
      },
    }),
  ]);

  // Individual creates (createMany with skipDuplicates not supported on SQLite)
  const postData = [
    {
      content:
        "Tips for managing sensory overload in public spaces. Noise-canceling headphones really help...",
      tags: '["Sensory", "Tips"]',
      authorId: users[0].id,
      likesCount: 45,
      commentsCount: 2,
    },
    {
      content:
        "Just discovered a great new therapy center in our area! They specialize in speech therapy for children.",
      tags: '["Resources", "Therapy"]',
      authorId: users[1].id,
      likesCount: 23,
      commentsCount: 1,
    },
    {
      content:
        "Our school just implemented a sensory room and the results have been amazing for our students.",
      tags: '["Education", "Sensory"]',
      authorId: users[2].id,
      likesCount: 67,
      commentsCount: 0,
    },
  ];

  for (const post of postData) {
    await prisma.post.create({ data: post });
  }

  console.log("Seed complete.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
