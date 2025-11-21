import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getAdmitCards } from '@/lib/services/admitCards';

export const revalidate = 1800; // ISR: revalidate every 30 minutes

export const metadata: Metadata = generateSEO({
  title: 'Admit Cards - Public Portal',
  description: 'Download admit cards and exam schedules',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/admit-cards`,
  ogType: 'website',
});

async function AdmitCardsPage({
  searchParams,
}: {
  searchParams: { page?: string; search?: string };
}) {
  const page = parseInt(searchParams.page || '1');
  const search = searchParams.search || '';

  const { data: admitCards, total, pageSize, hasNextPage } = await getAdmitCards({
    page,
    limit: 12,
    search,
  });

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Admit Cards', url: '/admit-cards' },
  ]);

  return (
    <main className="min-h-screen">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />

      <div className="max-w-7xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold mb-8">Admit Cards</h1>

        <div className="mb-8">
          <form className="flex gap-4">
            <input
              type="text"
              name="search"
              placeholder="Search admit cards..."
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

        {admitCards.length > 0 ? (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
              {admitCards.map((card) => (
                <div
                  key={card.id}
                  className="bg-white rounded-lg shadow hover:shadow-lg transition overflow-hidden"
                >
                  {card.imageUrl && (
                    <img
                      src={card.imageUrl}
                      alt={card.title}
                      className="w-full h-48 object-cover"
                      loading="lazy"
                    />
                  )}
                  <div className="p-6">
                    <h3 className="text-lg font-bold mb-2 line-clamp-2">{card.title}</h3>
                    <p className="text-gray-600 text-sm mb-3 line-clamp-2">{card.description}</p>
                    <div className="text-sm text-gray-500 mb-4">
                      <p>Released: {new Date(card.releaseDate).toLocaleDateString()}</p>
                      {card.examDate && (
                        <p>Exam Date: {new Date(card.examDate).toLocaleDateString()}</p>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <a
                        href={`/admit-cards/${card.id}`}
                        className="flex-1 text-center px-3 py-2 bg-blue-100 text-blue-600 rounded hover:bg-blue-200"
                      >
                        View Details
                      </a>
                      {card.downloadUrl && (
                        <a
                          href={card.downloadUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex-1 text-center px-3 py-2 bg-green-100 text-green-600 rounded hover:bg-green-200"
                        >
                          Download
                        </a>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-center gap-4 py-8">
              {page > 1 && (
                <a
                  href={`/admit-cards?page=${page - 1}${search ? `&search=${encodeURIComponent(search)}` : ''}`}
                  className="px-4 py-2 border rounded-lg hover:bg-gray-100"
                >
                  Previous
                </a>
              )}
              <span className="px-4 py-2">Page {page} of {Math.ceil(total / pageSize)}</span>
              {hasNextPage && (
                <a
                  href={`/admit-cards?page=${page + 1}${search ? `&search=${encodeURIComponent(search)}` : ''}`}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Next
                </a>
              )}
            </div>
          </>
        ) : (
          <div className="text-center py-12 bg-gray-50 rounded-lg">
            <p className="text-gray-600 text-lg">No admit cards found</p>
          </div>
        )}
      </div>
    </main>
  );
}

export default AdmitCardsPage;
