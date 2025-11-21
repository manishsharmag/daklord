import { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: '404 - Page Not Found | Public Portal',
  description: 'The page you are looking for does not exist.',
};

export default function NotFound() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center px-4">
        <h1 className="text-6xl font-bold mb-4">404</h1>
        <p className="text-2xl font-semibold mb-2">Page Not Found</p>
        <p className="text-gray-600 mb-8">Sorry, the page you are looking for does not exist.</p>
        <div className="flex gap-4 justify-center">
          <Link href="/" className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            Go Home
          </Link>
          <Link href="/results" className="px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-100">
            Browse Results
          </Link>
        </div>
      </div>
    </main>
  );
}
