import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const userId = 'user-id'; // In a real app, get from session

    const { resultId, noticeId, jobPostingId, admitCardId, previousPaperId, resourceId } = body;

    // Validate that at least one ID is provided
    if (
      !resultId &&
      !noticeId &&
      !jobPostingId &&
      !admitCardId &&
      !previousPaperId &&
      !resourceId
    ) {
      return NextResponse.json(
        { error: 'At least one item ID is required' },
        { status: 400 }
      );
    }

    const bookmark = await prisma.bookmark.create({
      data: {
        userId,
        resultId: resultId || null,
        noticeId: noticeId || null,
        jobPostingId: jobPostingId || null,
        admitCardId: admitCardId || null,
        previousPaperId: previousPaperId || null,
        resourceId: resourceId || null,
      },
    });

    return NextResponse.json(bookmark);
  } catch (error) {
    console.error('Bookmark creation error:', error);
    return NextResponse.json(
      { error: 'Failed to create bookmark' },
      { status: 500 }
    );
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const body = await request.json();
    const userId = 'user-id'; // In a real app, get from session

    const { resultId, noticeId, jobPostingId, admitCardId, previousPaperId, resourceId } = body;

    await prisma.bookmark.deleteMany({
      where: {
        userId,
        OR: [
          { resultId: resultId || undefined },
          { noticeId: noticeId || undefined },
          { jobPostingId: jobPostingId || undefined },
          { admitCardId: admitCardId || undefined },
          { previousPaperId: previousPaperId || undefined },
          { resourceId: resourceId || undefined },
        ].filter((item) => Object.values(item)[0] !== undefined),
      },
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Bookmark deletion error:', error);
    return NextResponse.json(
      { error: 'Failed to delete bookmark' },
      { status: 500 }
    );
  }
}
