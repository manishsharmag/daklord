import Link from "next/link";

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center px-4 py-12">
      <div className="w-full max-w-2xl text-center space-y-8">
        {/* Header */}
        <div className="space-y-4">
          <h1 className="text-5xl md:text-6xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
            Education Platform
          </h1>
          <p className="text-xl text-slate-600 dark:text-slate-400">
            A comprehensive platform for learning, assessment, and resource management
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 my-8">
          <div className="p-6 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
            <div className="text-3xl mb-2">📚</div>
            <h3 className="font-semibold text-lg mb-2">Learning Resources</h3>
            <p className="text-sm text-slate-600 dark:text-slate-400">
              Access papers, study materials, and learning resources
            </p>
          </div>

          <div className="p-6 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
            <div className="text-3xl mb-2">✅</div>
            <h3 className="font-semibold text-lg mb-2">Assessments</h3>
            <p className="text-sm text-slate-600 dark:text-slate-400">
              Take tests and track your performance
            </p>
          </div>

          <div className="p-6 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
            <div className="text-3xl mb-2">🎫</div>
            <h3 className="font-semibold text-lg mb-2">Admit Cards</h3>
            <p className="text-sm text-slate-600 dark:text-slate-400">
              Manage exam schedules and admit card information
            </p>
          </div>

          <div className="p-6 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
            <div className="text-3xl mb-2">🔔</div>
            <h3 className="font-semibold text-lg mb-2">Notifications</h3>
            <p className="text-sm text-slate-600 dark:text-slate-400">
              Stay updated with important announcements
            </p>
          </div>
        </div>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center mt-8">
          <Link
            href="/health"
            className="px-8 py-3 rounded-lg bg-blue-600 hover:bg-blue-700 text-white font-semibold transition-colors"
          >
            System Status
          </Link>
          <a
            href="https://nextjs.org/docs"
            target="_blank"
            rel="noopener noreferrer"
            className="px-8 py-3 rounded-lg border border-slate-300 dark:border-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 font-semibold transition-colors"
          >
            Documentation
          </a>
        </div>

        {/* Footer Info */}
        <div className="mt-12 pt-8 border-t border-slate-200 dark:border-slate-700">
          <p className="text-sm text-slate-600 dark:text-slate-400">
            Built with Next.js 14, TypeScript, Tailwind CSS, and PostgreSQL
          </p>
        </div>
      </div>
    </main>
  );
}
