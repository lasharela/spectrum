import { PrismaClient } from "@prisma/client";

// This script seeds event categories and sample events.
// Usage: npx tsx src/db/seed-events.ts

const prisma = new PrismaClient();

async function main() {
  // Event Categories
  const categories = [
    { name: "Workshop", icon: "build", sortOrder: 1 },
    { name: "Support Group", icon: "groups", sortOrder: 2 },
    { name: "Social", icon: "people", sortOrder: 3 },
    { name: "Educational", icon: "school", sortOrder: 4 },
    { name: "Recreation", icon: "sports_soccer", sortOrder: 5 },
  ];

  for (const cat of categories) {
    await prisma.eventCategory.upsert({
      where: { name: cat.name },
      update: { icon: cat.icon, sortOrder: cat.sortOrder },
      create: cat,
    });
  }

  console.log(`Seeded ${categories.length} event categories.`);

  // Fetch existing users for organizer references
  const users = await prisma.user.findMany({ take: 3 });
  if (users.length === 0) {
    console.log("No users found — run seed.ts first. Skipping sample events.");
    return;
  }

  // Sample events (all approved for display)
  const now = new Date();
  const eventData = [
    {
      title: "Parent Support Group Meeting",
      description:
        "Monthly support group for parents of children on the spectrum. Share experiences, strategies, and connect with other families.",
      category: "Support Group",
      location: "123 Market St, San Francisco",
      startDate: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000), // +7 days
      endDate: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      isOnline: false,
      isFree: true,
      status: "approved",
      organizerId: users[0].id,
    },
    {
      title: "Sensory Play Workshop",
      description:
        "Hands-on workshop exploring sensory activities for kids. Learn techniques to create sensory-friendly environments at home.",
      category: "Workshop",
      location: "221 4th St, San Francisco",
      startDate: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      isOnline: false,
      isFree: false,
      price: "$25",
      status: "approved",
      organizerId: users[1 % users.length].id,
    },
    {
      title: "Teen Social Skills Group",
      description:
        "Weekly social skills development for teens on the spectrum. Practice conversation, teamwork, and friendship skills in a supportive virtual setting.",
      category: "Social",
      location: "Online via Zoom",
      startDate: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      isOnline: true,
      isFree: true,
      status: "approved",
      organizerId: users[2 % users.length].id,
    },
    {
      title: "Understanding IEPs Workshop",
      description:
        "Learn how to advocate for your child's educational needs. Understand the IEP process, your rights, and how to work effectively with schools.",
      category: "Educational",
      location: "SF Public Library, Main Branch",
      startDate: new Date(now.getTime() + 18 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 18 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      isOnline: false,
      isFree: true,
      status: "approved",
      organizerId: users[0].id,
    },
    {
      title: "Adaptive Swimming Lessons",
      description:
        "Swimming lessons designed for children with special needs. Small group sizes with trained instructors.",
      category: "Recreation",
      location: "YMCA Pool, 1 Tennis Dr",
      startDate: new Date(now.getTime() + 21 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 21 * 24 * 60 * 60 * 1000 + 1 * 60 * 60 * 1000),
      isOnline: false,
      isFree: false,
      price: "$40",
      status: "approved",
      organizerId: users[1 % users.length].id,
    },
    {
      title: "Siblings Support Circle",
      description:
        "Support group for siblings of children with autism. A safe space to share feelings and connect with peers who understand.",
      category: "Support Group",
      location: "Community Center, 100 Oak St",
      startDate: new Date(now.getTime() + 25 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 25 * 24 * 60 * 60 * 1000 + 1.5 * 60 * 60 * 1000),
      isOnline: false,
      isFree: true,
      status: "approved",
      organizerId: users[2 % users.length].id,
    },
    {
      title: "Art Therapy Session",
      description:
        "Express yourself through art in a supportive environment. All materials provided. No experience necessary.",
      category: "Workshop",
      location: "456 Valencia St, San Francisco",
      startDate: new Date(now.getTime() + 28 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 28 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      isOnline: false,
      isFree: false,
      price: "$35",
      status: "approved",
      organizerId: users[0].id,
    },
    {
      title: "Parent Education Seminar",
      description:
        "Latest research and strategies for supporting your child. Join experts for an interactive webinar on evidence-based approaches.",
      category: "Educational",
      location: "Online Webinar",
      startDate: new Date(now.getTime() + 32 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 32 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      isOnline: true,
      isFree: true,
      status: "approved",
      organizerId: users[1 % users.length].id,
    },
    {
      title: "Music Therapy Group",
      description:
        "Interactive music therapy session for all ages. Use rhythm, melody, and movement to build communication and social skills.",
      category: "Recreation",
      location: "789 Mission St, San Francisco",
      startDate: new Date(now.getTime() + 35 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 35 * 24 * 60 * 60 * 1000 + 1 * 60 * 60 * 1000),
      isOnline: false,
      isFree: false,
      price: "$30",
      status: "approved",
      organizerId: users[2 % users.length].id,
    },
    {
      title: "Sensory-Friendly Movie Night",
      description:
        "Enjoy a movie in a sensory-friendly environment. Lower volume, brighter lights, and freedom to move around.",
      category: "Social",
      location: "California Academy of Sciences, 55 Music Concourse Dr",
      startDate: new Date(now.getTime() + 38 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 38 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      isOnline: false,
      isFree: false,
      price: "$15",
      status: "approved",
      organizerId: users[0].id,
    },
  ];

  for (const data of eventData) {
    await prisma.event.create({ data });
  }

  console.log(`Seeded ${eventData.length} sample events.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
