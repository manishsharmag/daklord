import { checkHealth } from "@/lib/server";

export default async function HealthPage() {
  const health = await checkHealth();
  const isHealthy = health.status === "healthy";

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div
          className={`rounded-lg shadow-lg p-8 ${
            isHealthy
              ? "bg-green-50 dark:bg-green-900"
              : "bg-red-50 dark:bg-red-900"
          }`}
        >
          {/* Status Header */}
          <div className="flex items-center justify-between mb-6">
            <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
              System Health
            </h1>
            <div
              className={`h-4 w-4 rounded-full ${
                isHealthy
                  ? "bg-green-500 animate-pulse"
                  : "bg-red-500 animate-pulse"
              }`}
            />
          </div>

          {/* Status Badge */}
          <div className="mb-6">
            <span
              className={`inline-block px-4 py-2 rounded-full text-sm font-semibold ${
                isHealthy
                  ? "bg-green-200 dark:bg-green-800 text-green-900 dark:text-green-100"
                  : "bg-red-200 dark:bg-red-800 text-red-900 dark:text-red-100"
              }`}
            >
              {isHealthy ? "✓ Healthy" : "✗ Unhealthy"}
            </span>
          </div>

          {/* Database Status */}
          <div className="mb-4 p-4 bg-white dark:bg-slate-800 rounded-lg">
            <div className="flex items-center justify-between">
              <span className="text-slate-700 dark:text-slate-300 font-medium">
                Database
              </span>
              <span
                className={`text-sm font-semibold ${
                  health.database.connected
                    ? "text-green-600 dark:text-green-400"
                    : "text-red-600 dark:text-red-400"
                }`}
              >
                {health.database.connected ? "Connected" : "Disconnected"}
              </span>
            </div>
            {health.database.error && (
              <p className="text-sm text-red-600 dark:text-red-400 mt-2">
                {health.database.error}
              </p>
            )}
          </div>

          {/* Redis Status */}
          <div className="mb-4 p-4 bg-white dark:bg-slate-800 rounded-lg">
            <div className="flex items-center justify-between">
              <span className="text-slate-700 dark:text-slate-300 font-medium">
                Redis
              </span>
              <span
                className={`text-sm font-semibold ${
                  health.redis.connected
                    ? "text-green-600 dark:text-green-400"
                    : "text-red-600 dark:text-red-400"
                }`}
              >
                {health.redis.connected ? "Connected" : "Disconnected"}
              </span>
            </div>
            {health.redis.error && (
              <p className="text-sm text-red-600 dark:text-red-400 mt-2">
                {health.redis.error}
              </p>
            )}
          </div>

          {/* Timestamp */}
          <div className="mt-6 pt-4 border-t border-slate-200 dark:border-slate-700">
            <p className="text-xs text-slate-600 dark:text-slate-400">
              Last checked: {new Date(health.timestamp).toLocaleString()}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
