import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateNewsArticleSchema, generateBreadcrumbSchema } from '@/lib/seo';
import { getResultById } from '@/lib/services/results';
import { notFound } from 'next/navigation';

export const revalidate = 3600; // ISR: revalidate every hour

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const result = await getResultById(params.id);

  if (!result) {
    return {};
  }

  return generateSEO({
    title: `${result.title} - Public Portal`,
    description: result.description || 'View exam result details',
    canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/results/${result.id}`,
    ogType: 'article',
    ogImage: result.imageUrl,
    publishedTime: new Date(result.releaseDate).toISOString(),
    modifiedTime: new Date(result.updatedAt).toISOString(),
    section: result.category,
  });
}

async function ResultDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const result = await getResultById(params.id);

  if (!result) {
    notFound();
  }

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Results', url: '/results' },
    { name: result.title, url: `/results/${result.id}` },
  ]);

  const schema = generateNewsArticleSchema(result);

  return (
    <main className="min-h-screen">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
      />

      <article className="max-w-4xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold mb-4">{result.title}</h1>

        <div className="text-gray-600 mb-8 flex gap-4 text-sm">
          <span>{new Date(result.releaseDate).toLocaleDateString()}</span>
          {result.category && <span className="bg-gray-100 px-3 py-1 rounded">{result.category}</span>}
        </div>

        {result.imageUrl && (
          <img
            src={result.imageUrl}
            alt={result.title}
            className="w-full rounded-lg mb-8 max-h-96 object-cover"
            loading="lazy"
          />
        )}

        {result.description && (
          <p className="text-lg text-gray-700 mb-8">{result.description}</p>
        )}

        {result.content && (
          <div
            className="prose prose-lg max-w-none mb-8"
            dangerouslySetInnerHTML={{ __html: result.content }}
          />
        )}

        {result.url && (
          <a
            href={result.url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 mb-12"
          >
            View Full Result
          </a>
        )}

        <div className="mt-12 pt-8 border-t">
          <a href="/results" className="text-blue-600 hover:underline">
            ← Back to Results
          </a>
        </div>
      </article>
    </main>
  );
}

export default ResultDetailPage;
