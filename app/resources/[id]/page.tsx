import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getResourceById } from '@/lib/services/resources';
import { notFound } from 'next/navigation';

export const revalidate = 3600; // ISR: revalidate every hour

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const resource = await getResourceById(params.id);

  if (!resource) {
    return {};
  }

  return generateSEO({
    title: `${resource.title} - Resource | Public Portal`,
    description: resource.description || 'Educational resource',
    canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/resources/${resource.id}`,
    ogType: 'article',
    ogImage: resource.imageUrl,
  });
}

async function ResourceDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const resource = await getResourceById(params.id);

  if (!resource) {
    notFound();
  }

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Resources', url: '/resources' },
    { name: resource.title, url: `/resources/${resource.id}` },
  ]);

  return (
    <main className="min-h-screen bg-gray-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />

      <article className="max-w-4xl mx-auto px-4 py-12">
        <div className="bg-white rounded-lg shadow p-8">
          <h1 className="text-4xl font-bold mb-2">{resource.title}</h1>

          <div className="mb-8 pb-8 border-b">
            {resource.category && (
              <span className="inline-block px-3 py-1 bg-blue-100 text-blue-800 rounded font-semibold text-sm">
                {resource.category}
              </span>
            )}
          </div>

          {resource.imageUrl && (
            <img
              src={resource.imageUrl}
              alt={resource.title}
              className="w-full rounded-lg mb-8 max-h-96 object-cover"
              loading="lazy"
            />
          )}

          {resource.description && (
            <div className="mb-8">
              <h2 className="text-2xl font-bold mb-4">Description</h2>
              <p className="text-gray-700">{resource.description}</p>
            </div>
          )}

          {resource.resourceUrl && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-8">
              <a
                href={resource.resourceUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block px-8 py-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-semibold"
              >
                Access Resource →
              </a>
            </div>
          )}

          {resource.type && (
            <div className="bg-gray-100 rounded-lg p-4">
              <p className="text-sm text-gray-700">
                <strong>Resource Type:</strong> {resource.type}
              </p>
            </div>
          )}
        </div>

        <div className="mt-8">
          <a href="/resources" className="text-blue-600 hover:underline">
            ← Back to Resources
          </a>
        </div>
      </article>
    </main>
  );
}

export default ResourceDetailPage;
