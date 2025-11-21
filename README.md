# Education Platform

A comprehensive Next.js 14 education platform with TypeScript, Tailwind CSS, PostgreSQL, and Redis.

## Features

- **Next.js 14** with App Router
- **TypeScript** for type safety
- **Tailwind CSS** with mobile-first design and light/dark theme support
- **PostgreSQL** for data persistence
- **Redis** for caching and session management
- **Prisma ORM** for database management
- **ESLint** and **Prettier** for code quality
- **Docker Compose** for local development stack
- **Server-only database layer** for secure data access
- **Health check endpoint** to verify database and Redis connectivity

## Tech Stack

- **Frontend**: React 19, Next.js 16, TypeScript
- **Styling**: Tailwind CSS 4.1
- **Database**: PostgreSQL with Prisma ORM
- **Caching**: Redis
- **Code Quality**: ESLint, Prettier
- **Development**: Docker Compose, Node.js 20+

## Project Structure

```
.
├── app/
│   ├── api/
│   │   └── health/              # Health check API endpoint
│   ├── health/                  # Health check UI page
│   ├── lib/
│   │   ├── providers.tsx        # Theme provider and context
│   │   └── server/              # Server-only utilities
│   │       ├── db.ts            # Prisma client
│   │       ├── redis.ts         # Redis client
│   │       ├── health.ts        # Health check logic
│   │       └── index.ts         # Exports
│   ├── layout.tsx               # Root layout with theme provider
│   ├── page.tsx                 # Home page
│   └── globals.css              # Global styles
├── prisma/
│   ├── schema.prisma            # Database schema
│   └── seed.ts                  # Seed script for initial data
├── public/                      # Static assets
├── .env                         # Local environment variables
├── .env.example                 # Example environment variables
├── docker-compose.yml           # Docker Compose configuration
├── package.json                 # Project dependencies
└── tsconfig.json                # TypeScript configuration
```

## Prerequisites

- Node.js 20+ (with pnpm)
- Docker and Docker Compose (for local database stack)

## Getting Started

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Set Up Local Database Stack

Start PostgreSQL and Redis using Docker Compose:

```bash
docker-compose up -d
```

Wait for services to be healthy:

```bash
docker-compose ps
```

### 3. Create Database and Run Migrations

Prisma will automatically run migrations when you start the dev server. Alternatively, run manually:

```bash
pnpm prisma:migrate
```

### 4. Seed Database (Optional)

Load initial sample data:

```bash
pnpm prisma:seed
```

### 5. Start Development Server

```bash
pnpm dev
```

The application will be available at `http://localhost:3000`

### 6. Verify Setup

Visit the health check page to verify database and Redis connectivity:
- **UI**: http://localhost:3000/health
- **API**: http://localhost:3000/api/health

## Environment Variables

Copy `.env.example` to `.env` and configure as needed:

```env
# Database
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/nextjs_dev?schema=public"

# Redis
REDIS_URL="redis://localhost:6379"

# Next.js
NODE_ENV="development"
```

## Available Scripts

### Development
```bash
pnpm dev          # Start development server with migrations
pnpm build        # Build for production with migrations
pnpm start        # Start production server
```

### Database
```bash
pnpm prisma:generate  # Generate Prisma client
pnpm prisma:migrate   # Create and run migrations
pnpm prisma:seed      # Seed database with initial data
```

### Code Quality
```bash
pnpm lint         # Run ESLint
pnpm format       # Format code with Prettier
pnpm test         # Run tests (if configured)
```

## Database Schema

The application includes the following Prisma models:

- **User**: User accounts and authentication
- **Result**: Test results and scores
- **Job**: Background jobs and tasks
- **AdmitCard**: Exam admit card information
- **Paper**: Study materials and papers
- **AdminLog**: Administrative action logs
- **SeoMetadata**: Page SEO metadata
- **Bookmark**: User-saved resources
- **Notification**: User notifications

## Light/Dark Theme

The application features a global light/dark theme toggle:

- **Toggle Button**: Fixed button in the bottom-right corner
- **Persistence**: Theme preference saved to localStorage
- **System Preference**: Respects OS dark mode preference on first visit
- **Styling**: All components support both themes via Tailwind's `dark:` prefix

## Server-Only Database Access

Database and Redis clients are configured for server-side use only:

- Located in `app/lib/server/`
- Singleton instances with proper connection pooling
- Development mode logging for debugging

### Usage Example

```typescript
import { prisma, redis, checkHealth } from "@/lib/server";

// Database queries
const users = await prisma.user.findMany();

// Redis operations
await redis.set("key", "value");
const value = await redis.get("key");

// Health checks
const health = await checkHealth();
```

## Health Check

Monitor system connectivity via:

- **Page**: `/health` - Visual dashboard
- **API**: `/api/health` - JSON response

Response includes:
- Overall system status
- Database connection status
- Redis connection status
- Detailed error messages
- Timestamp

## Docker Compose

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Remove Volumes (Clean Slate)
```bash
docker-compose down -v
```

## Troubleshooting

### Database Connection Issues
1. Check PostgreSQL is running: `docker-compose ps`
2. Verify DATABASE_URL in `.env`
3. Check Docker logs: `docker-compose logs postgres`

### Redis Connection Issues
1. Check Redis is running: `docker-compose ps`
2. Verify REDIS_URL in `.env`
3. Check Docker logs: `docker-compose logs redis`

### Prisma Issues
1. Regenerate Prisma client: `pnpm prisma:generate`
2. Check schema syntax: `pnpm prisma validate`
3. View migrations status: `pnpm prisma migrate status`

### Port Already in Use
- PostgreSQL (5432): `lsof -i :5432`
- Redis (6379): `lsof -i :6379`

## Development Workflow

1. Make database schema changes in `prisma/schema.prisma`
2. Create migration: `pnpm prisma:migrate`
3. Generate Prisma client: `pnpm prisma:generate`
4. Update API routes and components
5. Test changes: `pnpm dev`
6. Format code: `pnpm format`
7. Check linting: `pnpm lint`

## Deployment

For production deployment:

1. Set environment variables (DATABASE_URL, REDIS_URL, etc.)
2. Run migrations: `prisma migrate deploy`
3. Build application: `pnpm build`
4. Start server: `pnpm start`

## Contributing

1. Follow the existing code style
2. Run linting and formatting before committing
3. Keep components server-first
4. Use TypeScript for type safety

## License

Proprietary
