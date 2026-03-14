import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// bcrypt hash of "password123" — pre-computed for seeding
// In production, Better Auth hashes passwords automatically during sign-up
const PASSWORD_HASH =
  "$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012";

async function main() {
  console.log("Seeding database...");

  // Clear existing data
  await prisma.reaction.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.post.deleteMany();
  await prisma.account.deleteMany();
  await prisma.session.deleteMany();
  await prisma.user.deleteMany();

  const users = await Promise.all([
    prisma.user.create({
      data: {
        email: "sarah@example.com",
        emailVerified: true,
        name: "Sarah Miller",
        firstName: "Sarah",
        lastName: "Miller",
        userType: "parent",
      },
    }),
    prisma.user.create({
      data: {
        email: "john@example.com",
        emailVerified: true,
        name: "John Davis",
        firstName: "John",
        lastName: "Davis",
        userType: "professional",
      },
    }),
    prisma.user.create({
      data: {
        email: "maria@example.com",
        emailVerified: true,
        name: "Maria Lopez",
        firstName: "Maria",
        lastName: "Lopez",
        userType: "educator",
      },
    }),
  ]);

  // Create account records (credential provider) so users can log in
  // NOTE: These use a placeholder hash. For actual login, sign up through the app.
  // Seed users are for displaying data, not for login testing.
  for (const user of users) {
    await prisma.account.create({
      data: {
        userId: user.id,
        accountId: user.id,
        providerId: "credential",
        password: PASSWORD_HASH,
      },
    });
  }

  const postData = [
    {
      content:
        "Tips for managing sensory overload in public spaces. Noise-canceling headphones really help...",
      tags: '["Sensory", "Tips"]',
      category: "Sensory",
      authorId: users[0].id,
      likesCount: 45,
      commentsCount: 2,
    },
    {
      content:
        "Just discovered a great new therapy center in our area! They specialize in speech therapy for children.",
      tags: '["Resources", "Therapy"]',
      category: "Resources",
      authorId: users[1].id,
      likesCount: 23,
      commentsCount: 1,
    },
    {
      content:
        "Our school just implemented a sensory room and the results have been amazing for our students.",
      tags: '["Education", "Sensory"]',
      category: "Education",
      authorId: users[2].id,
      likesCount: 67,
      commentsCount: 0,
    },
    {
      content:
        "Looking for recommendations on social skills groups for teens. Any experiences to share?",
      tags: '["Social", "Support"]',
      category: "Social",
      authorId: users[0].id,
      likesCount: 12,
      commentsCount: 0,
    },
    {
      content:
        "Daily routine visual schedule template that works great for morning routines. Happy to share!",
      tags: '["Daily Life", "Tips"]',
      category: "Daily Life",
      authorId: users[2].id,
      likesCount: 89,
      commentsCount: 3,
    },
  ];

  const posts = [];
  for (const post of postData) {
    posts.push(await prisma.post.create({ data: post }));
  }

  // Add some comments
  await prisma.comment.create({
    data: {
      content: "This is so helpful! We use the same strategy at home.",
      authorId: users[1].id,
      postId: posts[0].id,
    },
  });
  await prisma.comment.create({
    data: {
      content: "Can you share the location? We've been looking for something similar.",
      authorId: users[2].id,
      postId: posts[1].id,
    },
  });

  console.log(`Seeded ${users.length} users, ${posts.length} posts, 2 comments.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
