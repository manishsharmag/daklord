import { prisma } from '@/lib/db';
import { getCachedData, invalidateCache } from '@/lib/cache';
import { PaginationParams, PaginatedResponse } from '@/types';

const CACHE_PREFIX = 'resources:';
const CACHE_TTL = 3600; // 1 hour

export async function getResources(
  params: PaginationParams
): Promise<PaginatedResponse<any>> {
  const page = params.page || 1;
  const limit = params.limit || 10;
  const search = params.search || '';
  const sort = params.sort || 'createdAt';
  const order = params.order || 'desc';

  const cacheKey = `${CACHE_PREFIX}${page}-${limit}-${search}-${sort}-${order}`;

  return getCachedData(
    cacheKey,
    async () => {
      const skip = (page - 1) * limit;

      const [data, total] = await Promise.all([
        prisma.resource.findMany({
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
        prisma.resource.count({
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

export async function getResourcesByCategory(
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
        prisma.resource.findMany({
          where: { category },
          orderBy: { createdAt: 'desc' },
          skip,
          take: limit,
        }),
        prisma.resource.count({ where: { category } }),
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

export async function getResourceById(id: string) {
  const cacheKey = `${CACHE_PREFIX}id:${id}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.resource.findUnique({
        where: { id },
      });
    },
    CACHE_TTL
  );
}

export async function getResourceCategories(): Promise<string[]> {
  const cacheKey = `${CACHE_PREFIX}categories`;

  return getCachedData(
    cacheKey,
    async () => {
      const categories = await prisma.resource.findMany({
        distinct: ['category'],
        select: { category: true },
      });

      return categories.map(c => c.category);
    },
    CACHE_TTL * 2
  );
}

export async function invalidateResourcesCache(): Promise<void> {
  await invalidateCache(`${CACHE_PREFIX}*`);
}
