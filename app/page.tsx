import { Metadata } from 'next';
import { generateMetadata as generateSEO } from '@/lib/seo';
import { getLatestNotices } from '@/lib/services/notices';
import { getLatestJobs } from '@/lib/services/jobs';
import { getLatestAdmitCards } from '@/lib/services/admitCards';

export const revalidate = 3600; // ISR: revalidate every hour

export const metadata: Metadata = generateSEO({
  title: 'Home - Public Portal',
  description: 'Latest results, notices, job opportunities, admit cards, and study resources',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/`,
  ogType: 'website',
  ogImage: `${process.env.NEXT_PUBLIC_SITE_URL}/og-image.png`,
});

async function HomePage() {
  let latestNotices = [];
  let latestJobs = [];
  let latestAdmitCards = [];

  try {
    [latestNotices, latestJobs, latestAdmitCards] = await Promise.all([
      getLatestNotices(5),
      getLatestJobs(5),
      getLatestAdmitCards(5),
    ]);
  } catch (error) {
    console.error('Error fetching feed data:', error);
  }

  return (
    <main className="min-h-screen">
      <section className="py-12 px-4 max-w-7xl mx-auto">
        <h1 className="text-4xl font-bold mb-2">Public Portal</h1>
        <p className="text-lg text-gray-600 mb-8">
          Your one-stop destination for latest results, job opportunities, admit cards, and study resources
        </p>
      </section>

      <div className="bg-gray-50 py-12">
        <div className="max-w-7xl mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <a href="/results" className="group">
              <div className="bg-white rounded-lg shadow hover:shadow-lg transition p-6">
                <h3 className="text-xl font-bold mb-2 group-hover:text-blue-600">Results</h3>
                <p className="text-gray-600">Find latest exam results and announcements</p>
              </div>
            </a>

            <a href="/jobs" className="group">
              <div className="bg-white rounded-lg shadow hover:shadow-lg transition p-6">
                <h3 className="text-xl font-bold mb-2 group-hover:text-blue-600">Job Listings</h3>
                <p className="text-gray-600">Browse available job opportunities</p>
              </div>
            </a>

            <a href="/admit-cards" className="group">
              <div className="bg-white rounded-lg shadow hover:shadow-lg transition p-6">
                <h3 className="text-xl font-bold mb-2 group-hover:text-blue-600">Admit Cards</h3>
                <p className="text-gray-600">Download admit cards and exam schedules</p>
              </div>
            </a>

            <a href="/papers" className="group">
              <div className="bg-white rounded-lg shadow hover:shadow-lg transition p-6">
                <h3 className="text-xl font-bold mb-2 group-hover:text-blue-600">Previous Papers</h3>
                <p className="text-gray-600">Access previous exam papers</p>
              </div>
            </a>

            <a href="/resources" className="group">
              <div className="bg-white rounded-lg shadow hover:shadow-lg transition p-6">
                <h3 className="text-xl font-bold mb-2 group-hover:text-blue-600">Resources</h3>
                <p className="text-gray-600">Study materials and guides</p>
              </div>
            </a>

            <a href="/notices" className="group">
              <div className="bg-white rounded-lg shadow hover:shadow-lg transition p-6">
                <h3 className="text-xl font-bold mb-2 group-hover:text-blue-600">Notices</h3>
                <p className="text-gray-600">Important notices and updates</p>
              </div>
            </a>
          </div>
        </div>
      </div>

      {latestNotices.length > 0 && (
        <section className="py-12 px-4 max-w-7xl mx-auto">
          <h2 className="text-3xl font-bold mb-6">Latest Notices</h2>
          <div className="space-y-4">
            {latestNotices.map((notice) => (
              <article key={notice.id} className="border rounded-lg p-4 hover:shadow-md transition">
                <h3 className="text-xl font-semibold mb-2">{notice.title}</h3>
                <p className="text-gray-600 mb-3">{notice.description}</p>
                <a href={`/notices/${notice.id}`} className="text-blue-600 hover:underline">
                  Read more →
                </a>
              </article>
            ))}
          </div>
        </section>
      )}

      {latestJobs.length > 0 && (
        <section className="py-12 px-4 max-w-7xl mx-auto bg-gray-50">
          <h2 className="text-3xl font-bold mb-6">Latest Job Opportunities</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {latestJobs.map((job) => (
              <div key={job.id} className="bg-white rounded-lg p-6 shadow hover:shadow-lg transition">
                <h3 className="text-xl font-semibold mb-2">{job.title}</h3>
                <p className="text-gray-600 mb-1">{job.company}</p>
                <p className="text-gray-500 text-sm mb-4">{job.location}</p>
                <a href={`/jobs/${job.id}`} className="text-blue-600 hover:underline">
                  View job →
                </a>
              </div>
            ))}
          </div>
        </section>
      )}
    </main>
  );
}

export default HomePage;
