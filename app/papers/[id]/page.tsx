import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateNewsArticleSchema, generateBreadcrumbSchema } from '@/lib/seo';
import { getPaperById } from '@/lib/services/papers';
import { notFound } from 'next/navigation';

export const revalidate = 7200; // ISR: revalidate every 2 hours

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const paper = await getPaperById(params.id);

  if (!paper) {
    return {};
  }

  return generateSEO({
    title: `${paper.title} (${paper.year}) - Public Portal`,
    description: paper.description || `Exam paper from ${paper.year}`,
    canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/papers/${paper.id}`,
    ogType: 'article',
    ogImage: paper.imageUrl,
    keywords: paper.subject ? [paper.subject, String(paper.year)] : [String(paper.year)],
  });
}

async function PaperDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const paper = await getPaperById(params.id);

  if (!paper) {
    notFound();
  }

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Papers', url: '/papers' },
    { name: `${paper.title} (${paper.year})`, url: `/papers/${paper.id}` },
  ]);

  const schema = generateNewsArticleSchema(paper);

  return (
    <main className="min-h-screen bg-gray-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
      />

      <article className="max-w-4xl mx-auto px-4 py-12">
        <div className="bg-white rounded-lg shadow p-8">
          <h1 className="text-4xl font-bold mb-2">{paper.title}</h1>

          <div className="grid grid-cols-2 gap-4 mb-8 pb-8 border-b">
            <div>
              <p className="text-gray-600 text-sm">Year</p>
              <p className="font-semibold text-2xl">{paper.year}</p>
            </div>
            {paper.subject && (
              <div>
                <p className="text-gray-600 text-sm">Subject</p>
                <p className="font-semibold">{paper.subject}</p>
              </div>
            )}
          </div>

          {paper.imageUrl && (
            <img
              src={paper.imageUrl}
              alt={paper.title}
              className="w-full rounded-lg mb-8 max-h-96 object-cover"
              loading="lazy"
            />
          )}

          {paper.description && (
            <div className="mb-8">
              <h2 className="text-2xl font-bold mb-4">About This Paper</h2>
              <p className="text-gray-700">{paper.description}</p>
            </div>
          )}

          {paper.pdfUrl && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-8">
              <a
                href={paper.pdfUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block px-8 py-4 bg-red-600 text-white rounded-lg hover:bg-red-700 font-semibold"
              >
                📄 Download PDF
              </a>
            </div>
          )}
        </div>

        <div className="mt-8">
          <a href="/papers" className="text-blue-600 hover:underline">
            ← Back to Papers
          </a>
        </div>
      </article>
    </main>
  );
}

export default PaperDetailPage;
