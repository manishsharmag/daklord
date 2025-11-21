import { prisma } from '@/lib/db';
import { getCachedData, invalidateCache } from '@/lib/cache';
import { PaginationParams, PaginatedResponse } from '@/types';

const CACHE_PREFIX = 'papers:';
const CACHE_TTL = 7200; // 2 hours

export async function getPapers(
  params: PaginationParams
): Promise<PaginatedResponse<any>> {
  const page = params.page || 1;
  const limit = params.limit || 10;
  const search = params.search || '';
  const sort = params.sort || 'year';
  const order = params.order || 'desc';

  const cacheKey = `${CACHE_PREFIX}${page}-${limit}-${search}-${sort}-${order}`;

  return getCachedData(
    cacheKey,
    async () => {
      const skip = (page - 1) * limit;

      const [data, total] = await Promise.all([
        prisma.previousPaper.findMany({
          where: search
            ? {
                OR: [
                  { title: { contains: search, mode: 'insensitive' } },
                  { subject: { contains: search, mode: 'insensitive' } },
                ],
              }
            : {},
          orderBy: {
            [sort]: order,
          },
          skip,
          take: limit,
        }),
        prisma.previousPaper.count({
          where: search
            ? {
                OR: [
                  { title: { contains: search, mode: 'insensitive' } },
                  { subject: { contains: search, mode: 'insensitive' } },
                ],
              }
            : {},
        }),
      ]);

      return {
        data,
        total,
        page,
        pageSize: limit,
        hasNextPage: page * limit < total,
        hasPreviousPage: page > 1,
      };
    },
    CACHE_TTL
  );
}

export async function getPapersBySubject(
  subject: string,
  params: PaginationParams
) {
  const page = params.page || 1;
  const limit = params.limit || 10;

  const cacheKey = `${CACHE_PREFIX}subject:${subject}:${page}-${limit}`;

  return getCachedData(
    cacheKey,
    async () => {
      const skip = (page - 1) * limit;

      const [data, total] = await Promise.all([
        prisma.previousPaper.findMany({
          where: { subject },
          orderBy: { year: 'desc' },
          skip,
          take: limit,
        }),
        prisma.previousPaper.count({ where: { subject } }),
      ]);

      return {
        data,
        total,
        page,
        pageSize: limit,
        hasNextPage: page * limit < total,
        hasPreviousPage: page > 1,
      };
    },
    CACHE_TTL
  );
}

export async function getPapersByYear(year: number) {
  const cacheKey = `${CACHE_PREFIX}year:${year}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.previousPaper.findMany({
        where: { year },
        orderBy: { subject: 'asc' },
      });
    },
    CACHE_TTL
  );
}

export async function getPaperById(id: string) {
  const cacheKey = `${CACHE_PREFIX}id:${id}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.previousPaper.findUnique({
        where: { id },
      });
    },
    CACHE_TTL
  );
}

export async function getPaperSubjects(): Promise<string[]> {
  const cacheKey = `${CACHE_PREFIX}subjects`;

  return getCachedData(
    cacheKey,
    async () => {
      const subjects = await prisma.previousPaper.findMany({
        distinct: ['subject'],
        select: { subject: true },
        where: { subject: { not: null } },
      });

      return subjects.map(s => s.subject).filter(Boolean) as string[];
    },
    CACHE_TTL * 2
  );
}

export async function getPaperYears(): Promise<number[]> {
  const cacheKey = `${CACHE_PREFIX}years`;

  return getCachedData(
    cacheKey,
    async () => {
      const years = await prisma.previousPaper.findMany({
        distinct: ['year'],
        select: { year: true },
      });

      return years.map(y => y.year).sort((a, b) => b - a);
    },
    CACHE_TTL * 2
  );
}

export async function invalidatePapersCache(): Promise<void> {
  await invalidateCache(`${CACHE_PREFIX}*`);
}
