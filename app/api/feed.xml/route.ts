import { NextResponse } from 'next/server';
import RSS from 'rss';
import { getLatestNotices } from '@/lib/services/notices';

export async function GET() {
  const feed = new RSS({
    title: process.env.NEXT_PUBLIC_SITE_NAME || 'Public Portal',
    description: process.env.NEXT_PUBLIC_SITE_DESCRIPTION || 'Latest notices and updates',
    feed_url: `${process.env.NEXT_PUBLIC_SITE_URL}/api/feed.xml`,
    site_url: process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000',
    language: 'en',
  });

  try {
    const notices = await getLatestNotices(50);

    notices.forEach((notice) => {
      feed.item({
        title: notice.title,
        description: notice.description || '',
        url: `${process.env.NEXT_PUBLIC_SITE_URL}/notices/${notice.id}`,
        date: new Date(notice.publishedAt),
        categories: notice.title ? [notice.title] : [],
      });
    });
  } catch (error) {
    console.error('Error generating RSS feed:', error);
  }

  return new NextResponse(feed.xml({ indent: true }), {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
      'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=86400',
    },
  });
}
