'use client';

import { useState, useCallback } from 'react';
import { BookmarkState } from '@/types';

export function useBookmark(initialState: BookmarkState) {
  const [bookmarkState, setBookmarkState] = useState<BookmarkState>(initialState);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const toggleBookmark = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/bookmarks', {
        method: bookmarkState.isBookmarked ? 'DELETE' : 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(bookmarkState),
      });

      if (!response.ok) {
        throw new Error('Failed to update bookmark');
      }

      setBookmarkState(prev => ({
        ...prev,
        isBookmarked: !prev.isBookmarked,
      }));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      console.error('Bookmark error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [bookmarkState]);

  return {
    isBookmarked: bookmarkState.isBookmarked,
    isLoading,
    error,
    toggleBookmark,
  };
}
