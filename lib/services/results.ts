import { prisma } from '@/lib/db';
import { getCachedData, invalidateCache } from '@/lib/cache';
import { PaginationParams, PaginatedResponse } from '@/types';

const CACHE_PREFIX = 'results:';
const CACHE_TTL = 3600; // 1 hour

export async function getResults(
  params: PaginationParams
): Promise<PaginatedResponse<any>> {
  const page = params.page || 1;
  const limit = params.limit || 10;
  const search = params.search || '';
  const sort = params.sort || 'releaseDate';
  const order = params.order || 'desc';

  const cacheKey = `${CACHE_PREFIX}${page}-${limit}-${search}-${sort}-${order}`;

  return getCachedData(
    cacheKey,
    async () => {
      const skip = (page - 1) * limit;

      const [data, total] = await Promise.all([
        prisma.result.findMany({
          where: search
            ? {
                OR: [
                  { title: { contains: search, mode: 'insensitive' } },
                  { description: { contains: search, mode: 'insensitive' } },
                ],
              }
            : {},
          orderBy: {
            [sort]: order,
          },
          skip,
          take: limit,
        }),
        prisma.result.count({
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

export async function getResultById(id: string) {
  const cacheKey = `${CACHE_PREFIX}id:${id}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.result.findUnique({
        where: { id },
      });
    },
    CACHE_TTL
  );
}

export async function getResultsByCategory(
  category: string,
  params: PaginationParams
) {
  const page = params.page || 1;
  const limit = params.limit || 10;

  const cacheKey = `${CACHE_PREFIX}category:${category}:${page}-${limit}`;

  return getCachedData(
    cacheKey,
    async () => {
      const skip = (page - 1) * limit;

      const [data, total] = await Promise.all([
        prisma.result.findMany({
          where: { category },
          orderBy: { releaseDate: 'desc' },
          skip,
          take: limit,
        }),
        prisma.result.count({ where: { category } }),
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

export async function invalidateResultsCache(): Promise<void> {
  await invalidateCache(`${CACHE_PREFIX}*`);
}
