import { prisma } from "./db";
import { redis } from "./redis";

export interface HealthStatus {
  status: "healthy" | "unhealthy";
  database: {
    connected: boolean;
    error?: string;
  };
  redis: {
    connected: boolean;
    error?: string;
  };
  timestamp: string;
}

export async function checkHealth(): Promise<HealthStatus> {
  const timestamp = new Date().toISOString();
  let dbConnected = false;
  let dbError: string | undefined;
  let redisConnected = false;
  let redisError: string | undefined;

  // Check database connection
  try {
    await prisma.$queryRaw`SELECT 1`;
    dbConnected = true;
  } catch (error) {
    dbConnected = false;
    dbError = error instanceof Error ? error.message : "Unknown database error";
  }

  // Check Redis connection
  try {
    if (!redis.isOpen) {
      await redis.connect();
    }
    await redis.ping();
    redisConnected = true;
  } catch (error) {
    redisConnected = false;
    redisError = error instanceof Error ? error.message : "Unknown Redis error";
  }

  const status: HealthStatus = {
    status: dbConnected && redisConnected ? "healthy" : "unhealthy",
    database: {
      connected: dbConnected,
      ...(dbError && { error: dbError }),
    },
    redis: {
      connected: redisConnected,
      ...(redisError && { error: redisError }),
    },
    timestamp,
  };

  return status;
}
