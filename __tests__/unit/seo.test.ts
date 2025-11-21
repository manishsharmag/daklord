import {
  generateJobPostingSchema,
  generateNewsArticleSchema,
  generateBreadcrumbSchema,
  generateOrganizationSchema,
} from '@/lib/seo';

describe('SEO Utilities', () => {
  describe('generateJobPostingSchema', () => {
    it('should generate valid JobPosting schema', () => {
      const job = {
        id: '1',
        title: 'Software Engineer',
        company: 'Tech Corp',
        description: 'Great job opportunity',
        location: 'New York',
        jobType: 'FULL_TIME',
        salary: '100000',
        postedDate: new Date(),
        expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      };

      const schema = generateJobPostingSchema(job);

      expect(schema['@type']).toBe('JobPosting');
      expect(schema.title).toBe(job.title);
      expect(schema.description).toBe(job.description);
      expect(schema['@context']).toBe('https://schema.org');
    });

    it('should handle job without salary', () => {
      const job = {
        title: 'Software Engineer',
        company: 'Tech Corp',
        description: 'Great job',
        location: 'NYC',
        jobType: 'FULL_TIME',
        salary: undefined,
        postedDate: new Date(),
      };

      const schema = generateJobPostingSchema(job);

      expect(schema.baseSalary).toBeUndefined();
      expect(schema.title).toBe('Software Engineer');
    });
  });

  describe('generateNewsArticleSchema', () => {
    it('should generate valid NewsArticle schema', () => {
      const article = {
        title: 'Breaking News',
        description: 'Important announcement',
        releaseDate: new Date(),
        updatedAt: new Date(),
      };

      const schema = generateNewsArticleSchema(article);

      expect(schema['@type']).toBe('NewsArticle');
      expect(schema.headline).toBe(article.title);
      expect(schema['@context']).toBe('https://schema.org');
    });
  });

  describe('generateBreadcrumbSchema', () => {
    it('should generate valid BreadcrumbList schema', () => {
      const breadcrumbs = [
        { name: 'Home', url: '/' },
        { name: 'Results', url: '/results' },
        { name: 'Result 1', url: '/results/1' },
      ];

      const schema = generateBreadcrumbSchema(breadcrumbs);

      expect(schema['@type']).toBe('BreadcrumbList');
      expect(schema.itemListElement).toHaveLength(3);
      expect(schema.itemListElement[0].position).toBe(1);
      expect(schema.itemListElement[2].position).toBe(3);
    });
  });

  describe('generateOrganizationSchema', () => {
    it('should generate valid Organization schema', () => {
      const schema = generateOrganizationSchema();

      expect(schema['@type']).toBe('Organization');
      expect(schema.name).toBeDefined();
      expect(schema['@context']).toBe('https://schema.org');
      expect(schema.sameAs).toBeInstanceOf(Array);
    });
  });
});
