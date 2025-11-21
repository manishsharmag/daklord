import { MetadataRoute } from 'next';
import { prisma } from '@/lib/db';

async function fetchSitemapData() {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000';

  const entries: MetadataRoute.Sitemap = [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 1,
    },
    {
      url: `${baseUrl}/results`,
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/jobs`,
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/notices`,
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 0.85,
    },
    {
      url: `${baseUrl}/admit-cards`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.85,
    },
    {
      url: `${baseUrl}/papers`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.8,
    },
    {
      url: `${baseUrl}/resources`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.8,
    },
  ];

  try {
    const [results, jobs, notices, admitCards, papers, resources] = await Promise.all([
      prisma.result.findMany({
        select: { id: true, updatedAt: true },
        orderBy: { updatedAt: 'desc' },
        take: 1000,
      }),
      prisma.jobPosting.findMany({
        select: { id: true, updatedAt: true },
        orderBy: { updatedAt: 'desc' },
        take: 1000,
      }),
      prisma.notice.findMany({
        select: { id: true, updatedAt: true },
        orderBy: { updatedAt: 'desc' },
        take: 1000,
      }),
      prisma.admitCard.findMany({
        select: { id: true, updatedAt: true },
        orderBy: { updatedAt: 'desc' },
        take: 1000,
      }),
      prisma.previousPaper.findMany({
        select: { id: true, updatedAt: true },
        orderBy: { updatedAt: 'desc' },
        take: 1000,
      }),
      prisma.resource.findMany({
        select: { id: true, updatedAt: true },
        orderBy: { updatedAt: 'desc' },
        take: 1000,
      }),
    ]);

    results.forEach((result) => {
      entries.push({
        url: `${baseUrl}/results/${result.id}`,
        lastModified: result.updatedAt,
        changeFrequency: 'weekly',
        priority: 0.7,
      });
    });

    jobs.forEach((job) => {
      entries.push({
        url: `${baseUrl}/jobs/${job.id}`,
        lastModified: job.updatedAt,
        changeFrequency: 'daily',
        priority: 0.7,
      });
    });

    notices.forEach((notice) => {
      entries.push({
        url: `${baseUrl}/notices/${notice.id}`,
        lastModified: notice.updatedAt,
        changeFrequency: 'weekly',
        priority: 0.65,
      });
    });

    admitCards.forEach((card) => {
      entries.push({
        url: `${baseUrl}/admit-cards/${card.id}`,
        lastModified: card.updatedAt,
        changeFrequency: 'monthly',
        priority: 0.65,
      });
    });

    papers.forEach((paper) => {
      entries.push({
        url: `${baseUrl}/papers/${paper.id}`,
        lastModified: paper.updatedAt,
        changeFrequency: 'monthly',
        priority: 0.6,
      });
    });

    resources.forEach((resource) => {
      entries.push({
        url: `${baseUrl}/resources/${resource.id}`,
        lastModified: resource.updatedAt,
        changeFrequency: 'monthly',
        priority: 0.6,
      });
    });
  } catch (error) {
    console.error('Error fetching sitemap data:', error);
  }

  return entries;
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  return fetchSitemapData();
}
