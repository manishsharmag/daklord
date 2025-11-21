import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getAdmitCardById } from '@/lib/services/admitCards';
import { notFound } from 'next/navigation';

export const revalidate = 1800; // ISR: revalidate every 30 minutes

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const card = await getAdmitCardById(params.id);

  if (!card) {
    return {};
  }

  return generateSEO({
    title: `${card.title} - Admit Card | Public Portal`,
    description: card.description || 'Download exam admit card',
    canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/admit-cards/${card.id}`,
    ogType: 'article',
    ogImage: card.imageUrl,
  });
}

async function AdmitCardDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const card = await getAdmitCardById(params.id);

  if (!card) {
    notFound();
  }

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Admit Cards', url: '/admit-cards' },
    { name: card.title, url: `/admit-cards/${card.id}` },
  ]);

  return (
    <main className="min-h-screen bg-gray-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbs) }}
      />

      <article className="max-w-4xl mx-auto px-4 py-12">
        <div className="bg-white rounded-lg shadow p-8">
          <h1 className="text-4xl font-bold mb-2">{card.title}</h1>

          <div className="grid grid-cols-2 gap-4 mb-8 pb-8 border-b">
            <div>
              <p className="text-gray-600 text-sm">Released</p>
              <p className="font-semibold">{new Date(card.releaseDate).toLocaleDateString()}</p>
            </div>
            {card.examDate && (
              <div>
                <p className="text-gray-600 text-sm">Exam Date</p>
                <p className="font-semibold">{new Date(card.examDate).toLocaleDateString()}</p>
              </div>
            )}
            {card.expiryDate && (
              <div>
                <p className="text-gray-600 text-sm">Expiry</p>
                <p className="font-semibold">{new Date(card.expiryDate).toLocaleDateString()}</p>
              </div>
            )}
          </div>

          {card.imageUrl && (
            <img
              src={card.imageUrl}
              alt={card.title}
              className="w-full rounded-lg mb-8 max-h-96 object-cover"
              loading="lazy"
            />
          )}

          {card.description && (
            <div className="mb-8">
              <h2 className="text-2xl font-bold mb-4">Description</h2>
              <p className="text-gray-700">{card.description}</p>
            </div>
          )}

          {card.downloadUrl && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-8">
              <a
                href={card.downloadUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block px-8 py-4 bg-green-600 text-white rounded-lg hover:bg-green-700 font-semibold"
              >
                📥 Download Admit Card
              </a>
            </div>
          )}

          {card.expiryDate && new Date(card.expiryDate) < new Date() && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-8">
              <p className="text-red-800">This admit card has expired.</p>
            </div>
          )}
        </div>

        <div className="mt-8">
          <a href="/admit-cards" className="text-blue-600 hover:underline">
            ← Back to Admit Cards
          </a>
        </div>
      </article>
    </main>
  );
}

export default AdmitCardDetailPage;
