import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getPapers, getPaperSubjects, getPaperYears } from '@/lib/services/papers';

export const revalidate = 7200; // ISR: revalidate every 2 hours

export const metadata: Metadata = generateSEO({
  title: 'Previous Papers - Public Portal',
  description: 'Download previous exam papers by year and subject',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/papers`,
  ogType: 'website',
});

async function PapersPage({
  searchParams,
}: {
  searchParams: { page?: string; search?: string; subject?: string; year?: string };
}) {
  const page = parseInt(searchParams.page || '1');
  const search = searchParams.search || '';
  const subject = searchParams.subject || '';
  const year = searchParams.year || '';

  const [papersResult, subjects, years] = await Promise.all([
    getPapers({
      page,
      limit: 12,
      search,
      sort: 'year',
      order: 'desc',
    }),
    getPaperSubjects(),
    getPaperYears(),
  ]);

  const { data: papers, total, pageSize, hasNextPage } = papersResult;

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Papers', url: '/papers' },
  ]);

  const buildQueryString = (newParams: Record<string, string>) => {
    const params = new URLSearchParams();
    if (newParams.search) params.set('search', newParams.search);
    if (newParams.subject) params.set('subject', newParams.subject);
    if (newParams.year) params.set('year', newParams.year);
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
        <h1 className="text-4xl font-bold mb-8">Previous Exam Papers</h1>

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
                    placeholder="Paper title..."
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  />
                </div>

                <div>
                  <label className="block font-semibold mb-2">Subject</label>
                  <select
                    name="subject"
                    defaultValue={subject}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  >
                    <option value="">All Subjects</option>
                    {subjects.map((subj) => (
                      <option key={subj} value={subj}>
                        {subj}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-semibold mb-2">Year</label>
                  <select
                    name="year"
                    defaultValue={year}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  >
                    <option value="">All Years</option>
                    {years.map((y) => (
                      <option key={y} value={y}>
                        {y}
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
                  href="/papers"
                  className="block text-center text-blue-600 hover:underline text-sm"
                >
                  Reset Filters
                </a>
              </form>
            </div>
          </aside>

          <div className="lg:col-span-3">
            {papers.length > 0 ? (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                  {papers.map((paper) => (
                    <div
                      key={paper.id}
                      className="bg-white rounded-lg p-6 shadow hover:shadow-lg transition"
                    >
                      <h3 className="text-lg font-bold mb-2">{paper.title}</h3>
                      {paper.subject && (
                        <p className="text-gray-600 text-sm mb-1">Subject: {paper.subject}</p>
                      )}
                      <p className="text-gray-600 text-sm mb-3">Year: {paper.year}</p>
                      {paper.description && (
                        <p className="text-gray-600 text-sm mb-4 line-clamp-2">{paper.description}</p>
                      )}
                      <div className="flex gap-2">
                        <a
                          href={`/papers/${paper.id}`}
                          className="flex-1 text-center px-3 py-2 bg-blue-100 text-blue-600 rounded hover:bg-blue-200 text-sm"
                        >
                          View
                        </a>
                        {paper.pdfUrl && (
                          <a
                            href={paper.pdfUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex-1 text-center px-3 py-2 bg-green-100 text-green-600 rounded hover:bg-green-200 text-sm"
                          >
                            Download PDF
                          </a>
                        )}
                      </div>
                    </div>
                  ))}
                </div>

                <div className="flex justify-center gap-4 py-8">
                  {page > 1 && (
                    <a
                      href={`/papers?${buildQueryString({ ...searchParams, page: String(page - 1) })}`}
                      className="px-4 py-2 border rounded-lg hover:bg-gray-100"
                    >
                      Previous
                    </a>
                  )}
                  <span className="px-4 py-2">Page {page} of {Math.ceil(total / pageSize)}</span>
                  {hasNextPage && (
                    <a
                      href={`/papers?${buildQueryString({ ...searchParams, page: String(page + 1) })}`}
                      className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                      Next
                    </a>
                  )}
                </div>
              </>
            ) : (
              <div className="bg-white rounded-lg p-12 text-center">
                <p className="text-gray-600 text-lg">No papers found</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}

export default PapersPage;
