import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create sample results
  const result1 = await prisma.result.create({
    data: {
      title: 'EXAM Results 2024 - Session 1',
      description: 'Results for examination held on January 15, 2024',
      category: 'Final Results',
      releaseDate: new Date('2024-01-20'),
      expiryDate: new Date('2025-01-20'),
      content: '<p>Result declared with merit list.</p>',
    },
  });

  // Create sample notices
  const notice1 = await prisma.notice.create({
    data: {
      title: 'Important: Admit Card Release',
      description: 'Admit cards for upcoming exam are now available',
      publishedAt: new Date(),
      priority: 1,
    },
  });

  // Create sample jobs
  const job1 = await prisma.jobPosting.create({
    data: {
      title: 'Senior Software Engineer',
      company: 'Tech Solutions Inc',
      description: 'We are looking for experienced software engineers...',
      location: 'New York, USA',
      jobType: 'FULL_TIME',
      salary: '120000 - 150000 USD',
      postedDate: new Date(),
      expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  });

  // Create sample admit card
  const admitCard1 = await prisma.admitCard.create({
    data: {
      title: 'Admit Card - Exam 2024',
      description: 'Download your admit card for the upcoming examination',
      releaseDate: new Date(),
      examDate: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
    },
  });

  // Create sample paper
  const paper1 = await prisma.previousPaper.create({
    data: {
      title: 'Mathematics Paper 1',
      subject: 'Mathematics',
      year: 2023,
      description: 'Previous year mathematics question paper',
    },
  });

  // Create sample resource
  const resource1 = await prisma.resource.create({
    data: {
      title: 'Study Guide - Physics',
      category: 'Study Materials',
      description: 'Comprehensive guide for physics preparation',
      type: 'DOCUMENT',
    },
  });

  console.log('Seeding completed successfully!');
  console.log('Created:', {
    result: result1.id,
    notice: notice1.id,
    job: job1.id,
    admitCard: admitCard1.id,
    paper: paper1.id,
    resource: resource1.id,
  });
}

main()
  .catch((error) => {
    console.error('Seeding error:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
