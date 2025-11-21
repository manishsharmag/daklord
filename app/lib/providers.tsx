"use client";

import { ReactNode, useCallback, useEffect, useState } from "react";

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [mounted, setMounted] = useState(false);
  const [theme, setTheme] = useState<"light" | "dark">("light");

  const initializeTheme = useCallback(() => {
    const savedTheme = localStorage.getItem("theme");
    const prefersDark = window.matchMedia(
      "(prefers-color-scheme: dark)"
    ).matches;
    const initialTheme =
      (savedTheme as "light" | "dark" | null) || (prefersDark ? "dark" : "light");
    setTheme(initialTheme);
    document.documentElement.classList.toggle("dark", initialTheme === "dark");
  }, []);

  // eslint-disable-next-line react-hooks/set-state-in-effect
  useEffect(() => {
    initializeTheme();
    setMounted(true);
  }, [initializeTheme]);

  const toggleTheme = () => {
    const newTheme = theme === "light" ? "dark" : "light";
    setTheme(newTheme);
    localStorage.setItem("theme", newTheme);
    document.documentElement.classList.toggle("dark", newTheme === "dark");
  };

  if (!mounted) {
    return <>{children}</>;
  }

  return (
    <>
      {children}
      <ThemeToggle theme={theme} onToggle={toggleTheme} />
    </>
  );
}

function ThemeToggle({
  theme,
  onToggle,
}: {
  theme: "light" | "dark";
  onToggle: () => void;
}) {
  return (
    <button
      onClick={onToggle}
      className="fixed bottom-6 right-6 p-3 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 transition-colors shadow-lg"
      aria-label="Toggle theme"
    >
      {theme === "light" ? (
        <svg
          className="w-6 h-6 text-slate-900"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
        </svg>
      ) : (
        <svg
          className="w-6 h-6 text-yellow-400"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path
            fillRule="evenodd"
            d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.536l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.828-2.828a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414l.707.707zm.707 5.657a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 1.414l-.707.707zM9 16a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1z"
            clipRule="evenodd"
          />
        </svg>
      )}
    </button>
  );
}
