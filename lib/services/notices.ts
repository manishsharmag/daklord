import { prisma } from '@/lib/db';
import { getCachedData, invalidateCache } from '@/lib/cache';
import { PaginationParams, PaginatedResponse } from '@/types';

const CACHE_PREFIX = 'notices:';
const CACHE_TTL = 1800; // 30 minutes

export async function getNotices(
  params: PaginationParams
): Promise<PaginatedResponse<any>> {
  const page = params.page || 1;
  const limit = params.limit || 10;
  const search = params.search || '';

  const cacheKey = `${CACHE_PREFIX}${page}-${limit}-${search}`;

  return getCachedData(
    cacheKey,
    async () => {
      const skip = (page - 1) * limit;

      const [data, total] = await Promise.all([
        prisma.notice.findMany({
          where: search
            ? {
                OR: [
                  { title: { contains: search, mode: 'insensitive' } },
                  { description: { contains: search, mode: 'insensitive' } },
                ],
              }
            : {},
          orderBy: [{ priority: 'desc' }, { publishedAt: 'desc' }],
          skip,
          take: limit,
        }),
        prisma.notice.count({
          where: search
            ? {
                OR: [
                  { title: { contains: search, mode: 'insensitive' } },
                  { description: { contains: search, mode: 'insensitive' } },
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

export async function getLatestNotices(limit: number = 5) {
  const cacheKey = `${CACHE_PREFIX}latest:${limit}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.notice.findMany({
        where: {
          expiryDate: {
            gte: new Date(),
          },
        },
        orderBy: [{ priority: 'desc' }, { publishedAt: 'desc' }],
        take: limit,
      });
    },
    CACHE_TTL
  );
}

export async function getNoticeById(id: string) {
  const cacheKey = `${CACHE_PREFIX}id:${id}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.notice.findUnique({
        where: { id },
      });
    },
    CACHE_TTL
  );
}

export async function invalidateNoticesCache(): Promise<void> {
  await invalidateCache(`${CACHE_PREFIX}*`);
}
