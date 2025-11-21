import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getResults } from '@/lib/services/results';

export const revalidate = 3600; // ISR: revalidate every hour

export const metadata: Metadata = generateSEO({
  title: 'Results - Public Portal',
  description: 'Browse latest exam results and announcements',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/results`,
  ogType: 'website',
});

async function ResultsPage({
  searchParams,
}: {
  searchParams: { page?: string; search?: string };
}) {
  const page = parseInt(searchParams.page || '1');
  const search = searchParams.search || '';

  const { data: results, total, pageSize, hasNextPage } = await getResults({
    page,
    limit: 10,
    search,
  });

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Results', url: '/results' },
  ]);

  return (
    <main className="min-h-screen">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />

      <div className="max-w-7xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold mb-8">Results</h1>

        <div className="mb-8">
          <form className="flex gap-4">
            <input
              type="text"
              name="search"
              placeholder="Search results..."
              defaultValue={search}
              className="flex-1 px-4 py-2 border rounded-lg"
            />
            <button
              type="submit"
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Search
            </button>
          </form>
        </div>

        {results.length > 0 ? (
          <>
            <div className="space-y-4 mb-8">
              {results.map((result) => (
                <article
                  key={result.id}
                  className="border rounded-lg p-6 hover:shadow-md transition"
                >
                  <h2 className="text-2xl font-bold mb-2">{result.title}</h2>
                  <p className="text-gray-600 mb-3">{result.description}</p>
                  <div className="flex gap-4 text-sm text-gray-500 mb-4">
                    <span>{new Date(result.releaseDate).toLocaleDateString()}</span>
                    {result.category && <span className="bg-gray-100 px-2 py-1 rounded">{result.category}</span>}
                  </div>
                  <a href={`/results/${result.id}`} className="text-blue-600 hover:underline">
                    View details →
                  </a>
                </article>
              ))}
            </div>

            <div className="flex justify-center gap-4 py-8">
              {page > 1 && (
                <a
                  href={`/results?page=${page - 1}${search ? `&search=${encodeURIComponent(search)}` : ''}`}
                  className="px-4 py-2 border rounded-lg hover:bg-gray-100"
                >
                  Previous
                </a>
              )}
              <span className="px-4 py-2">Page {page} of {Math.ceil(total / pageSize)}</span>
              {hasNextPage && (
                <a
                  href={`/results?page=${page + 1}${search ? `&search=${encodeURIComponent(search)}` : ''}`}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Next
                </a>
              )}
            </div>
          </>
        ) : (
          <div className="text-center py-12">
            <p className="text-gray-600 text-lg">No results found</p>
          </div>
        )}
      </div>
    </main>
  );
}

export default ResultsPage;
