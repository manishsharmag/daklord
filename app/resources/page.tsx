import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getResources, getResourceCategories } from '@/lib/services/resources';

export const revalidate = 3600; // ISR: revalidate every hour

export const metadata: Metadata = generateSEO({
  title: 'Resources - Public Portal',
  description: 'Study materials, guides, and educational resources',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/resources`,
  ogType: 'website',
});

async function ResourcesPage({
  searchParams,
}: {
  searchParams: { page?: string; search?: string; category?: string };
}) {
  const page = parseInt(searchParams.page || '1');
  const search = searchParams.search || '';
  const category = searchParams.category || '';

  const [resourcesResult, categories] = await Promise.all([
    getResources({
      page,
      limit: 12,
      search,
    }),
    getResourceCategories(),
  ]);

  const { data: resources, total, pageSize, hasNextPage } = resourcesResult;

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Resources', url: '/resources' },
  ]);

  const buildQueryString = (newParams: Record<string, string>) => {
    const params = new URLSearchParams();
    if (newParams.search) params.set('search', newParams.search);
    if (newParams.category) params.set('category', newParams.category);
    if (newParams.page) params.set('page', newParams.page);
    return params.toString();
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />

      <div className="max-w-7xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold mb-8">Resources</h1>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <aside className="lg:col-span-1">
            <div className="bg-white rounded-lg p-6 shadow">
              <h2 className="text-lg font-bold mb-4">Filters</h2>

              <form className="space-y-6">
                <div>
                  <label className="block font-semibold mb-2">Search</label>
                  <input
                    type="text"
                    name="search"
                    defaultValue={search}
                    placeholder="Resource name..."
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  />
                </div>

                <div>
                  <label className="block font-semibold mb-2">Category</label>
                  <select
                    name="category"
                    defaultValue={category}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  >
                    <option value="">All Categories</option>
                    {categories.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>

                <button
                  type="submit"
                  className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Apply Filters
                </button>

                <a
                  href="/resources"
                  className="block text-center text-blue-600 hover:underline text-sm"
                >
                  Reset Filters
                </a>
              </form>
            </div>
          </aside>

          <div className="lg:col-span-3">
            {resources.length > 0 ? (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                  {resources.map((resource) => (
                    <div
                      key={resource.id}
                      className="bg-white rounded-lg shadow hover:shadow-lg transition overflow-hidden flex flex-col"
                    >
                      {resource.imageUrl && (
                        <img
                          src={resource.imageUrl}
                          alt={resource.title}
                          className="w-full h-40 object-cover"
                          loading="lazy"
                        />
                      )}
                      <div className="p-6 flex flex-col flex-1">
                        <h3 className="text-lg font-bold mb-2 line-clamp-2">{resource.title}</h3>
                        {resource.category && (
                          <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded w-fit mb-2">
                            {resource.category}
                          </span>
                        )}
                        <p className="text-gray-600 text-sm mb-4 flex-1 line-clamp-3">
                          {resource.description}
                        </p>
                        <a
                          href={`/resources/${resource.id}`}
                          className="inline-block px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm"
                        >
                          View Resource
                        </a>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="flex justify-center gap-4 py-8">
                  {page > 1 && (
                    <a
                      href={`/resources?${buildQueryString({ ...searchParams, page: String(page - 1) })}`}
                      className="px-4 py-2 border rounded-lg hover:bg-gray-100"
                    >
                      Previous
                    </a>
                  )}
                  <span className="px-4 py-2">Page {page} of {Math.ceil(total / pageSize)}</span>
                  {hasNextPage && (
                    <a
                      href={`/resources?${buildQueryString({ ...searchParams, page: String(page + 1) })}`}
                      className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                      Next
                    </a>
                  )}
                </div>
              </>
            ) : (
              <div className="bg-white rounded-lg p-12 text-center">
                <p className="text-gray-600 text-lg">No resources found</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}

export default ResourcesPage;
