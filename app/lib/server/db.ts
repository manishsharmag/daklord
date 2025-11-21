import { PrismaClient as _PrismaClient } from "@prisma/client";

const globalForPrisma = global as unknown as { prisma: _PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new _PrismaClient({
    log: ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
