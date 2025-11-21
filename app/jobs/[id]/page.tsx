import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateJobPostingSchema, generateBreadcrumbSchema } from '@/lib/seo';
import { getJobById } from '@/lib/services/jobs';
import { notFound } from 'next/navigation';

export const revalidate = 3600; // ISR: revalidate every hour

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const job = await getJobById(params.id);

  if (!job) {
    return {};
  }

  return generateSEO({
    title: `${job.title} - ${job.company} | Public Portal`,
    description: job.description || `Job opportunity at ${job.company}`,
    canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/jobs/${job.id}`,
    ogType: 'article',
    ogImage: job.imageUrl,
    publishedTime: new Date(job.postedDate).toISOString(),
    modifiedTime: new Date(job.updatedAt).toISOString(),
  });
}

async function JobDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const job = await getJobById(params.id);

  if (!job) {
    notFound();
  }

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Jobs', url: '/jobs' },
    { name: job.title, url: `/jobs/${job.id}` },
  ]);

  const schema = generateJobPostingSchema(job);

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
          <h1 className="text-4xl font-bold mb-2">{job.title}</h1>
          <h2 className="text-2xl text-gray-700 mb-6">{job.company}</h2>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8 pb-8 border-b">
            {job.location && (
              <div>
                <p className="text-gray-600 text-sm">Location</p>
                <p className="font-semibold">{job.location}</p>
              </div>
            )}
            {job.jobType && (
              <div>
                <p className="text-gray-600 text-sm">Employment Type</p>
                <p className="font-semibold">{job.jobType}</p>
              </div>
            )}
            {job.salary && (
              <div>
                <p className="text-gray-600 text-sm">Salary</p>
                <p className="font-semibold text-green-600">{job.salary}</p>
              </div>
            )}
            <div>
              <p className="text-gray-600 text-sm">Posted</p>
              <p className="font-semibold">{new Date(job.postedDate).toLocaleDateString()}</p>
            </div>
          </div>

          {job.imageUrl && (
            <img
              src={job.imageUrl}
              alt={job.company}
              className="w-full rounded-lg mb-8 max-h-96 object-cover"
              loading="lazy"
            />
          )}

          {job.description && (
            <div className="mb-8">
              <h3 className="text-2xl font-bold mb-4">Job Description</h3>
              <p className="text-gray-700 whitespace-pre-wrap">{job.description}</p>
            </div>
          )}

          {job.requirements && (
            <div className="mb-8">
              <h3 className="text-2xl font-bold mb-4">Requirements</h3>
              <p className="text-gray-700 whitespace-pre-wrap">{job.requirements}</p>
            </div>
          )}

          {job.applicationUrl && (
            <div className="mb-8">
              <a
                href={job.applicationUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block px-8 py-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-semibold"
              >
                Apply Now
              </a>
            </div>
          )}

          {job.expiryDate && new Date(job.expiryDate) > new Date() && (
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-8">
              <p className="text-sm text-yellow-800">
                Application deadline: {new Date(job.expiryDate).toLocaleDateString()}
              </p>
            </div>
          )}
        </div>

        <div className="mt-8">
          <a href="/jobs" className="text-blue-600 hover:underline">
            ← Back to Job Listings
          </a>
        </div>
      </article>
    </main>
  );
}

export default JobDetailPage;
