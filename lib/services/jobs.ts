import { prisma } from '@/lib/db';
import { getCachedData, invalidateCache } from '@/lib/cache';
import { PaginationParams, PaginatedResponse, JobFilter } from '@/types';

const CACHE_PREFIX = 'jobs:';
const CACHE_TTL = 3600; // 1 hour

export async function getJobs(
  params: PaginationParams,
  filters?: JobFilter
): Promise<PaginatedResponse<any>> {
  const page = params.page || 1;
  const limit = params.limit || 10;
  const search = params.search || '';
  const sort = params.sort || 'postedDate';
  const order = params.order || 'desc';

  const filterKey = filters ? Object.values(filters).join('-') : '';
  const cacheKey = `${CACHE_PREFIX}${page}-${limit}-${search}-${sort}-${order}-${filterKey}`;

  return getCachedData(
    cacheKey,
    async () => {
      const skip = (page - 1) * limit;

      const whereClause: any = {
        expiryDate: { gte: new Date() },
      };

      if (search) {
        whereClause.OR = [
          { title: { contains: search, mode: 'insensitive' } },
          { company: { contains: search, mode: 'insensitive' } },
          { description: { contains: search, mode: 'insensitive' } },
        ];
      }

      if (filters?.jobType) whereClause.jobType = filters.jobType;
      if (filters?.location) whereClause.location = { contains: filters.location, mode: 'insensitive' };
      if (filters?.company) whereClause.company = { contains: filters.company, mode: 'insensitive' };

      const [data, total] = await Promise.all([
        prisma.jobPosting.findMany({
          where: whereClause,
          orderBy: { [sort]: order },
          skip,
          take: limit,
        }),
        prisma.jobPosting.count({ where: whereClause }),
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

export async function getJobById(id: string) {
  const cacheKey = `${CACHE_PREFIX}id:${id}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.jobPosting.findUnique({
        where: { id },
      });
    },
    CACHE_TTL
  );
}

export async function getLatestJobs(limit: number = 5) {
  const cacheKey = `${CACHE_PREFIX}latest:${limit}`;

  return getCachedData(
    cacheKey,
    async () => {
      return prisma.jobPosting.findMany({
        where: {
          expiryDate: { gte: new Date() },
        },
        orderBy: { postedDate: 'desc' },
        take: limit,
      });
    },
    CACHE_TTL
  );
}

export async function getJobLocations(): Promise<string[]> {
  const cacheKey = `${CACHE_PREFIX}locations`;

  return getCachedData(
    cacheKey,
    async () => {
      const locations = await prisma.jobPosting.findMany({
        distinct: ['location'],
        select: { location: true },
        where: { location: { not: null } },
      });

      return locations.map(l => l.location).filter(Boolean) as string[];
    },
    CACHE_TTL * 2
  );
}

export async function getJobCompanies(): Promise<string[]> {
  const cacheKey = `${CACHE_PREFIX}companies`;

  return getCachedData(
    cacheKey,
    async () => {
      const companies = await prisma.jobPosting.findMany({
        distinct: ['company'],
        select: { company: true },
      });

      return companies.map(c => c.company);
    },
    CACHE_TTL * 2
  );
}

export async function invalidateJobsCache(): Promise<void> {
  await invalidateCache(`${CACHE_PREFIX}*`);
}
