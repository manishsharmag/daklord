import { Redis } from 'redis';

let redis: Redis | null = null;

export function getRedisClient(): Redis {
  if (!redis) {
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    redis = new Redis({
      url: redisUrl,
    }) as any;
  }
  return redis;
}

export async function getCachedData<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttl: number = 3600 // 1 hour default
): Promise<T> {
  try {
    const client = getRedisClient();
    const cached = await client.get(key);
    
    if (cached) {
      return JSON.parse(cached) as T;
    }

    const data = await fetcher();
    await client.setEx(key, ttl, JSON.stringify(data));
    return data;
  } catch (error) {
    console.error('Cache error:', error);
    // Fallback to direct fetcher if cache fails
    return fetcher();
  }
}

export async function invalidateCache(pattern: string): Promise<void> {
  try {
    const client = getRedisClient();
    const keys = await client.keys(pattern);
    if (keys.length > 0) {
      await client.del(keys);
    }
  } catch (error) {
    console.error('Cache invalidation error:', error);
  }
}

export async function setCacheData<T>(
  key: string,
  data: T,
  ttl: number = 3600
): Promise<void> {
  try {
    const client = getRedisClient();
    await client.setEx(key, ttl, JSON.stringify(data));
  } catch (error) {
    console.error('Cache set error:', error);
  }
}

export async function getCacheData<T>(key: string): Promise<T | null> {
  try {
    const client = getRedisClient();
    const data = await client.get(key);
    return data ? (JSON.parse(data) as T) : null;
  } catch (error) {
    console.error('Cache get error:', error);
    return null;
  }
}
