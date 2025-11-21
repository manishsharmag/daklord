import { createClient } from "redis";

const globalForRedis = global as unknown as { redis: ReturnType<typeof createClient> };

const redis =
  globalForRedis.redis ||
  createClient({
    url: process.env.REDIS_URL || "redis://localhost:6379",
  });

if (process.env.NODE_ENV !== "production") globalForRedis.redis = redis;

export { redis };
