import "dotenv/config";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  console.log("Starting seed...");

  try {
    // Clear existing data
    await prisma.notification.deleteMany();
    await prisma.bookmark.deleteMany();
    await prisma.seoMetadata.deleteMany();
    await prisma.adminLog.deleteMany();
    await prisma.paper.deleteMany();
    await prisma.admitCard.deleteMany();
    await prisma.job.deleteMany();
    await prisma.result.deleteMany();
    await prisma.user.deleteMany();

    // Create sample users
    const user1 = await prisma.user.create({
      data: {
        email: "user1@example.com",
        name: "User One",
        password: "hashed_password_1",
      },
    });

    await prisma.user.create({
      data: {
        email: "user2@example.com",
        name: "User Two",
        password: "hashed_password_2",
      },
    });

    // Create sample results
    await prisma.result.create({
      data: {
        userId: user1.id,
        score: 85.5,
        percentage: 85.5,
        status: "completed",
      },
    });

    // Create sample jobs
    await prisma.job.create({
      data: {
        userId: user1.id,
        title: "Math Assignment",
        description: "Complete math homework",
        status: "in_progress",
        progress: 50,
      },
    });

    // Create sample admit cards
    await prisma.admitCard.create({
      data: {
        admitNumber: "ADM-2024-001",
        candidateName: "John Doe",
        examDate: new Date("2024-12-15"),
        examTime: "10:00 AM",
        center: "Center A",
      },
    });

    // Create sample papers
    const paper1 = await prisma.paper.create({
      data: {
        title: "Mathematics Previous Year Paper",
        subject: "Mathematics",
        type: "paper",
        year: 2023,
      },
    });

    await prisma.paper.create({
      data: {
        title: "Physics Study Material",
        subject: "Physics",
        type: "resource",
        year: 2024,
      },
    });

    // Create sample bookmarks
    await prisma.bookmark.create({
      data: {
        userId: user1.id,
        paperId: paper1.id,
      },
    });

    // Create sample admin logs
    await prisma.adminLog.create({
      data: {
        adminId: "admin-1",
        action: "CREATE",
        resource: "User",
        details: `Created user: ${user1.email}`,
        ipAddress: "192.168.1.1",
      },
    });

    // Create sample SEO metadata
    await prisma.seoMetadata.create({
      data: {
        path: "/",
        title: "Education Platform",
        description: "A comprehensive education platform",
        keywords: "education, learning, platform",
        ogImage: "https://example.com/og-image.png",
      },
    });

    // Create sample notifications
    await prisma.notification.create({
      data: {
        userId: user1.id,
        title: "Welcome",
        message: "Welcome to the platform",
        read: false,
      },
    });

    console.log("✓ Seed data created successfully!");
  } catch (error) {
    console.error("Error seeding database:", error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
