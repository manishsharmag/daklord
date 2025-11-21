# Public SEO Pages

A comprehensive public-facing portal with SEO optimization, Redis caching, Incremental Static Regeneration (ISR), and modern performance best practices.

## Features

### Core Pages
- **Home Feed** - Latest results, notices, and job opportunities
- **Results** - Searchable exam results with pagination
- **Job Listings** - Filterable job postings with search and pagination
- **Admit Cards** - Downloadable admit cards for exams
- **Previous Papers** - Access to previous exam papers by year and subject
- **Notices** - Important announcements and updates
- **Resources** - Study materials and guides

### Technical Features

#### Data & Caching
- **Prisma ORM** - Type-safe database operations
- **Redis Caching** - Fast data retrieval with configurable TTL
- **ISR (Incremental Static Regeneration)** - Dynamic pages revalidate at specified intervals
- **Pagination & Search** - Efficient data browsing with filters

#### SEO Optimization
- **Dynamic Metadata** - Page-specific titles, descriptions, and Open Graph tags
- **Schema.org Markup** - JobPosting, NewsArticle, BreadcrumbList, Organization schemas
- **Robots.txt** - Search engine crawler directives
- **Sitemap Index** - Dynamic XML sitemaps with segmented URLs
- **RSS Feed** - Syndication of latest notices
- **Canonical Tags** - Prevent duplicate content issues
- **Image Optimization** - Responsive images with lazy loading

#### User Experience
- **Bookmark Hooks** - UI placeholders for user bookmarking functionality
- **Lazy-loaded Cards** - Efficient resource loading
- **Responsive Design** - Mobile-first layouts
- **Core Web Vitals** - Optimized for performance metrics
- **Accessible Forms** - Proper labels and semantic HTML

#### Testing
- **Jest Unit Tests** - Hooks and utilities testing
- **Playwright E2E Tests** - Smoke tests for all key routes
- **SEO Validation** - Schema markup and metadata verification

## Project Structure

```
├── app/                          # Next.js app directory
│   ├── layout.tsx               # Root layout with SEO
│   ├── page.tsx                 # Home page
│   ├── results/                 # Results pages
│   ├── jobs/                    # Job listing pages
│   ├── admit-cards/             # Admit card pages
│   ├── papers/                  # Previous papers pages
│   ├── notices/                 # Notices pages
│   ├── resources/               # Resources pages
│   ├── api/                     # API routes
│   │   ├── bookmarks/           # Bookmark API
│   │   └── feed.xml/            # RSS feed
│   ├── robots.ts                # Robots.txt
│   └── sitemap.ts               # XML sitemap
├── lib/
│   ├── db.ts                    # Prisma client singleton
│   ├── cache.ts                 # Redis caching utilities
│   ├── seo.ts                   # SEO helper functions
│   └── services/                # Data fetching services
│       ├── results.ts
│       ├── jobs.ts
│       ├── notices.ts
│       ├── admitCards.ts
│       ├── papers.ts
│       └── resources.ts
├── hooks/
│   └── useBookmark.ts           # Bookmark state management
├── types/
│   └── index.ts                 # TypeScript type definitions
├── __tests__/                   # Jest tests
├── e2e/                         # Playwright E2E tests
├── prisma/
│   ├── schema.prisma            # Database schema
│   └── seed.ts                  # Database seed script
├── public/                      # Static assets
├── next.config.js               # Next.js configuration
├── tsconfig.json                # TypeScript configuration
└── playwright.config.ts         # Playwright configuration
```

## Getting Started

### Prerequisites
- Node.js 18+
- npm or yarn
- SQLite (local development)
- Redis (optional for caching)

### Installation

1. Clone the repository and install dependencies:
```bash
npm install
```

2. Create environment files:
```bash
cp .env.example .env.local
```

3. Setup database:
```bash
npm run db:migrate
npm run db:push
npm run prisma db:seed   # Optional: seed sample data
```

4. Start development server:
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the application.

## Environment Variables

See `.env.example` for all available configuration options:

- `DATABASE_URL` - SQLite or PostgreSQL connection string
- `REDIS_URL` - Redis connection URL (for caching)
- `NEXT_PUBLIC_SITE_URL` - Base URL for the site
- `NEXT_PUBLIC_SITE_NAME` - Site name for SEO
- `NEXT_PUBLIC_SITE_DESCRIPTION` - Site description for metadata

## Development

### Running Tests

```bash
# Unit tests with Jest
npm test

# Watch mode
npm run test:watch

# End-to-end tests with Playwright
npm run e2e

# Debug E2E tests
npm run e2e:debug
```

### Building for Production

```bash
npm run build
npm start
```

### Database Operations

```bash
# Generate Prisma client
npm run db:generate

# Run migrations
npm run db:migrate

# Push schema to database
npm run db:push

# Open Prisma Studio
npm run db:studio

# Seed database
npx ts-node prisma/seed.ts
```

### Code Quality

```bash
# Format code
npm run format

# Lint code
npm run lint
```

## SEO Features

### Pages with SEO
All pages include:
- Unique title tags
- Meta descriptions
- Open Graph tags for social sharing
- Canonical URLs to prevent duplication
- JSON-LD schema markup

### Structured Data
- **JobPosting** - Job listing details
- **NewsArticle** - Notice and result articles
- **BreadcrumbList** - Navigation hierarchy
- **Organization** - Company information

### Sitemaps
- Dynamic XML sitemap with all content
- Proper update frequency and priority
- Segmented for large datasets

### Performance
- Image optimization with next/image
- Lazy loading for off-screen content
- ISR for fast updates without rebuilds
- Redis caching for database queries
- Compression and minification

## Caching Strategy

### Cache TTLs
- Results: 1 hour
- Notices: 30 minutes
- Jobs: 1 hour
- Admit Cards: 30 minutes
- Papers: 2 hours
- Resources: 1 hour

### ISR Revalidation
- Home: 1 hour
- Results: 1 hour
- Jobs: 1 hour
- Notices: 30 minutes
- Admit Cards: 30 minutes
- Papers: 2 hours
- Resources: 1 hour

## Core Web Vitals Optimization

1. **Largest Contentful Paint (LCP)** - Optimized through:
   - Next.js Image optimization
   - Efficient data fetching
   - Strategic preloading

2. **First Input Delay (FID)** - Improved through:
   - Minimal JavaScript
   - Server-side rendering
   - Code splitting

3. **Cumulative Layout Shift (CLS)** - Prevented through:
   - Reserved image dimensions
   - Font display swap
   - Stable grid layouts

## Accessibility

- Semantic HTML structure
- Proper heading hierarchy (h1 → h2 → h3)
- Form labels associated with inputs
- Alt text for all images
- ARIA attributes where needed
- Keyboard navigation support

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## License

MIT

## Support

For issues and questions, please create an issue in the repository.
