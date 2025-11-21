import { Metadata } from 'next';
import { generateMetadata as generateSEO, generateBreadcrumbSchema } from '@/lib/seo';
import { getJobs, getJobLocations, getJobCompanies } from '@/lib/services/jobs';

export const revalidate = 3600; // ISR: revalidate every hour

export const metadata: Metadata = generateSEO({
  title: 'Job Listings - Public Portal',
  description: 'Browse and filter job opportunities by location, company, and job type',
  canonical: `${process.env.NEXT_PUBLIC_SITE_URL}/jobs`,
  ogType: 'website',
});

async function JobsPage({
  searchParams,
}: {
  searchParams: {
    page?: string;
    search?: string;
    location?: string;
    company?: string;
    jobType?: string;
  };
}) {
  const page = parseInt(searchParams.page || '1');
  const search = searchParams.search || '';
  const location = searchParams.location || '';
  const company = searchParams.company || '';
  const jobType = searchParams.jobType || '';

  const [jobsResult, locations, companies] = await Promise.all([
    getJobs(
      { page, limit: 12, search },
      { location, company, jobType: jobType || undefined }
    ),
    getJobLocations(),
    getJobCompanies(),
  ]);

  const { data: jobs, total, pageSize, hasNextPage } = jobsResult;

  const breadcrumbs = generateBreadcrumbSchema([
    { name: 'Home', url: '/' },
    { name: 'Jobs', url: '/jobs' },
  ]);

  const buildQueryString = (newParams: Record<string, string>) => {
    const params = new URLSearchParams();
    if (newParams.search) params.set('search', newParams.search);
    if (newParams.location) params.set('location', newParams.location);
    if (newParams.company) params.set('company', newParams.company);
    if (newParams.jobType) params.set('jobType', newParams.jobType);
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
        <h1 className="text-4xl font-bold mb-8">Job Listings</h1>

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
                    placeholder="Job title, keywords..."
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  />
                </div>

                <div>
                  <label className="block font-semibold mb-2">Location</label>
                  <select
                    name="location"
                    defaultValue={location}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  >
                    <option value="">All Locations</option>
                    {locations.map((loc) => (
                      <option key={loc} value={loc}>
                        {loc}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-semibold mb-2">Company</label>
                  <select
                    name="company"
                    defaultValue={company}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  >
                    <option value="">All Companies</option>
                    {companies.map((comp) => (
                      <option key={comp} value={comp}>
                        {comp}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-semibold mb-2">Job Type</label>
                  <select
                    name="jobType"
                    defaultValue={jobType}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  >
                    <option value="">All Types</option>
                    <option value="FULL_TIME">Full Time</option>
                    <option value="PART_TIME">Part Time</option>
                    <option value="CONTRACT">Contract</option>
                    <option value="TEMPORARY">Temporary</option>
                  </select>
                </div>

                <button
                  type="submit"
                  className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Apply Filters
                </button>

                <a
                  href="/jobs"
                  className="block text-center text-blue-600 hover:underline text-sm"
                >
                  Reset Filters
                </a>
              </form>
            </div>
          </aside>

          <div className="lg:col-span-3">
            {jobs.length > 0 ? (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                  {jobs.map((job) => (
                    <div
                      key={job.id}
                      className="bg-white rounded-lg p-6 shadow hover:shadow-lg transition"
                    >
                      <h3 className="text-xl font-bold mb-2 line-clamp-2">{job.title}</h3>
                      <p className="text-gray-700 font-semibold mb-1">{job.company}</p>
                      {job.location && <p className="text-gray-600 text-sm mb-3">{job.location}</p>}
                      {job.salary && <p className="text-green-600 font-semibold text-sm mb-3">{job.salary}</p>}
                      <p className="text-gray-600 text-sm line-clamp-2 mb-4">{job.description}</p>
                      <a href={`/jobs/${job.id}`} className="text-blue-600 hover:underline text-sm">
                        View job details →
                      </a>
                    </div>
                  ))}
                </div>

                <div className="flex justify-center gap-4 py-8">
                  {page > 1 && (
                    <a
                      href={`/jobs?${buildQueryString({ ...searchParams, page: String(page - 1) })}`}
                      className="px-4 py-2 border rounded-lg hover:bg-gray-100"
                    >
                      Previous
                    </a>
                  )}
                  <span className="px-4 py-2">Page {page} of {Math.ceil(total / pageSize)}</span>
                  {hasNextPage && (
                    <a
                      href={`/jobs?${buildQueryString({ ...searchParams, page: String(page + 1) })}`}
                      className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                      Next
                    </a>
                  )}
                </div>
              </>
            ) : (
              <div className="bg-white rounded-lg p-12 text-center">
                <p className="text-gray-600 text-lg">No jobs found matching your criteria</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}

export default JobsPage;
