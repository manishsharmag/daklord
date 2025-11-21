import type { Metadata } from 'next';
import { generateMetadata as generateSEO } from '@/lib/seo';
import './globals.css';

export const metadata: Metadata = generateSEO({
  title: 'Public Portal - Results, Jobs & Resources',
  description: process.env.NEXT_PUBLIC_SITE_DESCRIPTION || 'A comprehensive public portal with results, notices, job listings, admit cards, and study resources.',
  canonical: process.env.NEXT_PUBLIC_SITE_URL,
  ogType: 'website',
  ogImage: `${process.env.NEXT_PUBLIC_SITE_URL}/og-image.png`,
  keywords: ['results', 'notices', 'jobs', 'admit cards', 'exam papers', 'resources'],
});

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
        <link rel="icon" href="/favicon.ico" />
        <link rel="alternate" type="application/rss+xml" href="/feed.xml" />
        <link rel="sitemap" type="application/xml" href="/sitemap.xml" />
      </head>
      <body>
        {children}
      </body>
    </html>
  );
}
