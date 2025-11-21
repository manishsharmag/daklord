import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getNotices } from '@/lib/services/notices';

export const revalidate = 1800; // ISR: revalidate every 30 minutes

export const metadata: Metadata = generateSEO({
  title: 'Notices - Public Portal',
  description: 'Important notices and updates',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/notices`,
  ogType: 'website',
});

async function NoticesPage({
  searchParams,
}: {
  searchParams: { page?: string; search?: string };
}) {
  const page = parseInt(searchParams.page || '1');
  const search = searchParams.search || '';

  const { data: notices, total, pageSize, hasNextPage } = await getNotices({
    page,
    limit: 10,
    search,
  });

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Notices', url: '/notices' },
  ]);

  return (
    <main className="min-h-screen">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />

      <div className="max-w-4xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold mb-8">Notices</h1>

        <div className="mb-8">
          <form className="flex gap-4">
            <input
              type="text"
              name="search"
              placeholder="Search notices..."
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

        {notices.length > 0 ? (
          <>
            <div className="space-y-6 mb-8">
              {notices.map((notice) => (
                <article
                  key={notice.id}
                  className="border rounded-lg p-6 hover:shadow-lg transition"
                >
                  <div className="flex items-start justify-between mb-2">
                    <h2 className="text-2xl font-bold flex-1">{notice.title}</h2>
                    {notice.priority > 0 && (
                      <span className="ml-4 px-3 py-1 bg-red-100 text-red-800 rounded text-sm font-semibold">
                        Priority
                      </span>
                    )}
                  </div>

                  <p className="text-gray-600 text-sm mb-4">
                    {new Date(notice.publishedAt).toLocaleDateString()}
                    {notice.expiryDate &&
                      new Date(notice.expiryDate) > new Date() && (
                        <span className="ml-4">
                          Expires: {new Date(notice.expiryDate).toLocaleDateString()}
                        </span>
                      )}
                  </p>

                  {notice.description && (
                    <p className="text-gray-700 mb-4">{notice.description}</p>
                  )}

                  <a href={`/notices/${notice.id}`} className="text-blue-600 hover:underline">
                    Read full notice →
                  </a>
                </article>
              ))}
            </div>

            <div className="flex justify-center gap-4 py-8">
              {page > 1 && (
                <a
                  href={`/notices?page=${page - 1}${search ? `&search=${encodeURIComponent(search)}` : ''}`}
                  className="px-4 py-2 border rounded-lg hover:bg-gray-100"
                >
                  Previous
                </a>
              )}
              <span className="px-4 py-2">Page {page} of {Math.ceil(total / pageSize)}</span>
              {hasNextPage && (
                <a
                  href={`/notices?page=${page + 1}${search ? `&search=${encodeURIComponent(search)}` : ''}`}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Next
                </a>
              )}
            </div>
          </>
        ) : (
          <div className="text-center py-12 bg-gray-50 rounded-lg">
            <p className="text-gray-600 text-lg">No notices found</p>
          </div>
        )}
      </div>
    </main>
  );
}

export default NoticesPage;
