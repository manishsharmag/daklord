import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateNewsArticleSchema, generateBreadcrumbSchema } from '@/lib/seo';
import { getNoticeById } from '@/lib/services/notices';
import { notFound } from 'next/navigation';

export const revalidate = 1800; // ISR: revalidate every 30 minutes

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const notice = await getNoticeById(params.id);

  if (!notice) {
    return {};
  }

  return generateSEO({
    title: `${notice.title} - Notice | Public Portal`,
    description: notice.description || 'Important notice',
    canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/notices/${notice.id}`,
    ogType: 'article',
    ogImage: notice.imageUrl,
    publishedTime: new Date(notice.publishedAt).toISOString(),
    modifiedTime: new Date(notice.updatedAt).toISOString(),
  });
}

async function NoticeDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const notice = await getNoticeById(params.id);

  if (!notice) {
    notFound();
  }

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Notices', url: '/notices' },
    { name: notice.title, url: `/notices/${notice.id}` },
  ]);

  const schema = generateNewsArticleSchema(notice);

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
          <h1 className="text-4xl font-bold mb-4">{notice.title}</h1>

          <div className="flex items-center gap-4 mb-8 pb-8 border-b">
            <span className="text-gray-600">
              {new Date(notice.publishedAt).toLocaleDateString()}
            </span>
            {notice.priority > 0 && (
              <span className="px-3 py-1 bg-red-100 text-red-800 rounded font-semibold">
                Priority
              </span>
            )}
            {notice.expiryDate && new Date(notice.expiryDate) > new Date() && (
              <span className="text-sm text-gray-500">
                Expires: {new Date(notice.expiryDate).toLocaleDateString()}
              </span>
            )}
          </div>

          {notice.imageUrl && (
            <img
              src={notice.imageUrl}
              alt={notice.title}
              className="w-full rounded-lg mb-8 max-h-96 object-cover"
              loading="lazy"
            />
          )}

          {notice.description && (
            <div className="mb-8">
              <p className="text-lg text-gray-700 mb-4">{notice.description}</p>
            </div>
          )}

          {notice.content && (
            <div
              className="prose prose-lg max-w-none mb-8"
              dangerouslySetInnerHTML={{ __html: notice.content }}
            />
          )}

          {notice.url && (
            <div className="mb-8">
              <a
                href={notice.url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                View Official Notice
              </a>
            </div>
          )}

          {notice.expiryDate && new Date(notice.expiryDate) < new Date() && (
            <div className="bg-gray-100 border border-gray-300 rounded-lg p-4 mb-8">
              <p className="text-gray-800">This notice has expired.</p>
            </div>
          )}
        </div>

        <div className="mt-8">
          <a href="/notices" className="text-blue-600 hover:underline">
            ← Back to Notices
          </a>
        </div>
      </article>
    </main>
  );
}

export default NoticeDetailPage;
