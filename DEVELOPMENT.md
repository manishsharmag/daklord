# Development Guide

This guide covers setting up and working with the Public Portal project.

## Prerequisites

- Node.js 18.x or higher
- npm 9.x or higher (or yarn/pnpm)
- SQLite 3 (usually pre-installed on macOS/Linux)
- Redis (optional, for caching - can skip for basic development)

## Initial Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Database Setup

The project uses Prisma with SQLite by default for development.

```bash
# Generate Prisma client
npm run db:generate

# Create/update database schema
npm run db:push

# (Optional) Seed database with sample data
npx ts-node prisma/seed.ts
```

### 3. Environment Configuration

The `.env` and `.env.local` files are already configured for local development. 

For custom configuration, create a `.env.local` file:

```env
DATABASE_URL="file:./prisma/dev.db"
REDIS_URL="redis://localhost:6379"
NEXT_PUBLIC_SITE_URL="http://localhost:3000"
```

## Running the Application

### Development Mode

```bash
npm run dev
```

The application will be available at `http://localhost:3000`.

### Production Build & Start

```bash
npm run build
npm start
```

## Development Workflow

### Creating New Pages

1. Create a new directory in `app/` (e.g., `app/new-page/`)
2. Create `page.tsx` with your component
3. Add metadata using SEO utilities
4. Test with `npm run dev`

Example:
```typescript
import { Metadata } from 'next';
import { generateMetadata as generateSEO } from '@/lib/seo';

export const metadata: Metadata = generateSEO({
  title: 'Your Page Title',
  description: 'Page description for SEO',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/your-page`,
});

export default function YourPage() {
  return (
    <main>
      {/* Page content */}
    </main>
  );
}
```

### Working with the Database

#### Creating a New Model

1. Edit `prisma/schema.prisma`
2. Run `npm run db:migrate` to create a migration
3. Run `npm run db:push` to apply changes

#### Querying Data

Use the service layer in `lib/services/`:

```typescript
import { prisma } from '@/lib/db';
import { getCachedData } from '@/lib/cache';

export async function getData() {
  return getCachedData(
    'cache-key',
    async () => {
      return prisma.model.findMany();
    },
    3600 // Cache for 1 hour
  );
}
```

#### Seeding Data

Edit `prisma/seed.ts` and run:

```bash
npx ts-node prisma/seed.ts
```

### Working with Services

Services in `lib/services/` handle data fetching with caching. Key patterns:

1. **Caching**: Always use `getCachedData` for database queries
2. **ISR**: Set appropriate `revalidate` values in page components
3. **Error Handling**: Catch and log errors appropriately

### Adding New Features

#### Feature: New Search Filter

1. Update the database schema if needed
2. Create a service function with filter support
3. Add UI filter in the page component
4. Update API routes if needed

#### Feature: New API Route

```typescript
// app/api/your-route/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    // Your logic
    return NextResponse.json({ data: result });
  } catch (error) {
    return NextResponse.json(
      { error: 'Error message' },
      { status: 500 }
    );
  }
}
```

## Testing

### Unit Tests

```bash
npm test
npm run test:watch
```

Tests are located in `__tests__/unit/` and use Jest + React Testing Library.

Example unit test:
```typescript
describe('My Component', () => {
  it('should render', () => {
    const { getByText } = render(<MyComponent />);
    expect(getByText('text')).toBeInTheDocument();
  });
});
```

### End-to-End Tests

```bash
npm run e2e
npm run e2e:debug
```

E2E tests use Playwright and are in `e2e/`.

### Test Best Practices

- Test user interactions, not implementation details
- Mock external APIs
- Test error cases
- Keep tests focused and isolated

## Code Style & Formatting

### Format Code

```bash
npm run format
```

Uses Prettier with configured rules in `.prettierrc`.

### Lint Code

```bash
npm run lint
```

Uses ESLint with Next.js recommended config in `.eslintrc.json`.

### Pre-commit Hooks

The project uses Git hooks (if configured). Make sure to:
1. Format code before committing
2. Pass linting checks
3. Pass tests

## Performance & SEO

### Page-Specific SEO

Every page should have proper metadata:

```typescript
export const metadata: Metadata = generateSEO({
  title: 'Page Title',
  description: 'Description',
  canonical: url,
  ogImage: imageUrl,
  keywords: ['keyword1', 'keyword2'],
});
```

### Schema.org Markup

Use schema generators for detail pages:

```typescript
const schema = generateJobPostingSchema(job);
// Add to page:
<script type="application/ld+json">
  {JSON.stringify(schema)}
</script>
```

### Image Optimization

Use Next.js Image component with:
- Proper width/height
- Lazy loading
- Responsive sizes

```typescript
<Image
  src={url}
  alt={title}
  width={1200}
  height={630}
  loading="lazy"
/>
```

### Cache Strategy

**Results**: 1 hour
**Notices**: 30 minutes
**Jobs**: 1 hour
**Admit Cards**: 30 minutes
**Papers**: 2 hours
**Resources**: 1 hour

Adjust cache times in service files if needed.

### ISR Revalidation

Set appropriate `revalidate` in page files:

```typescript
export const revalidate = 3600; // 1 hour
```

Use lower values for frequently updated content.

## Debugging

### Browser DevTools

- Inspector: Check DOM structure
- Console: View errors and logs
- Network: Check API calls and assets
- Lighthouse: Run performance audit

### Server-side Debugging

Use console.log in server components:

```typescript
export default async function Page() {
  console.log('Debug info'); // Shows in terminal
  return <div>Content</div>;
}
```

### Prisma Studio

```bash
npm run db:studio
```

Opens a visual database browser at `http://localhost:5555`.

## Deployment

### Pre-deployment Checklist

- [ ] All tests passing
- [ ] No TypeScript errors
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] Performance checked with Lighthouse
- [ ] SEO validated

### Deployment Providers

Works with:
- Vercel (recommended for Next.js)
- Netlify
- AWS Amplify
- Docker/Container

### Environment Variables for Production

Set in your deployment platform:
- DATABASE_URL (production database)
- REDIS_URL (production Redis)
- NEXT_PUBLIC_SITE_URL
- Other secrets as needed

## Troubleshooting

### Port 3000 Already in Use

```bash
# Kill the process using port 3000
lsof -ti:3000 | xargs kill -9

# Or use a different port
npm run dev -- -p 3001
```

### Database Connection Error

```bash
# Check database file exists
ls -la prisma/dev.db

# Reset database
rm prisma/dev.db
npm run db:push
```

### Build Errors

```bash
# Clear cache and rebuild
rm -rf .next
npm run build
```

### Cache Issues

Redis cache failures should not crash the app. Check:

```bash
# Verify Redis is running (if used)
redis-cli ping
```

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://www.prisma.io/docs/)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Schema.org](https://schema.org)
- [Playwright](https://playwright.dev)
- [Jest](https://jestjs.io)

## Support

For issues:
1. Check the README.md
2. Review test files for examples
3. Check existing issues
4. Create a new issue with details

## Contributing

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes and test
3. Commit with clear message: `git commit -m "feat: add feature"`
4. Push and create pull request

Commit message format:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code style
- `refactor:` Code refactoring
- `perf:` Performance improvement
- `test:` Test addition/modification
