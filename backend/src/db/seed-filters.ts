import { PrismaClient } from "@prisma/client";

// This script is run manually to seed filter option tables.
// Usage: npx tsx src/db/seed-filters.ts

const prisma = new PrismaClient();

async function main() {
  // Catalog Categories
  const categories = [
    { name: "Sensory-Friendly", icon: "spa", sortOrder: 1 },
    { name: "Indoor Playground", icon: "sports_handball", sortOrder: 2 },
    { name: "Outdoor Playground", icon: "park", sortOrder: 3 },
    { name: "Doctor", icon: "medical_services", sortOrder: 4 },
    { name: "Dentist", icon: "medical_information", sortOrder: 5 },
    { name: "Therapist", icon: "psychology", sortOrder: 6 },
    { name: "After-School", icon: "school", sortOrder: 7 },
    { name: "Education", icon: "cast_for_education", sortOrder: 8 },
    { name: "Restaurant", icon: "restaurant", sortOrder: 9 },
  ];

  for (const cat of categories) {
    await prisma.catalogCategory.upsert({
      where: { name: cat.name },
      update: { icon: cat.icon, sortOrder: cat.sortOrder },
      create: cat,
    });
  }

  // Age Groups
  const ageGroups = [
    { name: "Infants (0-2)", sortOrder: 1 },
    { name: "Toddlers (2-4)", sortOrder: 2 },
    { name: "Preschool (4-6)", sortOrder: 3 },
    { name: "School Age (6-12)", sortOrder: 4 },
    { name: "Teens (12-18)", sortOrder: 5 },
    { name: "Adults (18+)", sortOrder: 6 },
  ];

  for (const ag of ageGroups) {
    await prisma.ageGroup.upsert({
      where: { name: ag.name },
      update: { sortOrder: ag.sortOrder },
      create: ag,
    });
  }

  // Special Needs
  const specialNeeds = [
    { name: "Autism Specific", sortOrder: 1 },
    { name: "Wheelchair Accessible", sortOrder: 2 },
    { name: "Nonverbal Support", sortOrder: 3 },
    { name: "Sensory Processing", sortOrder: 4 },
  ];

  for (const sn of specialNeeds) {
    await prisma.specialNeed.upsert({
      where: { name: sn.name },
      update: { sortOrder: sn.sortOrder },
      create: sn,
    });
  }

  console.log("Filter options seeded successfully.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
