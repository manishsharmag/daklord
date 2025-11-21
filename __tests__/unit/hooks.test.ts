import { renderHook, act } from '@testing-library/react';
import { useBookmark } from '@/hooks/useBookmark';

describe('useBookmark Hook', () => {
  it('should initialize with default state', () => {
    const { result } = renderHook(() =>
      useBookmark({
        resultId: 'test-id',
        isBookmarked: false,
      })
    );

    expect(result.current.isBookmarked).toBe(false);
    expect(result.current.isLoading).toBe(false);
    expect(result.current.error).toBeNull();
  });

  it('should handle bookmark toggle', async () => {
    const { result } = renderHook(() =>
      useBookmark({
        resultId: 'test-id',
        isBookmarked: false,
      })
    );

    // Mock fetch
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })
    ) as jest.Mock;

    await act(async () => {
      await result.current.toggleBookmark();
    });

    expect(result.current.isBookmarked).toBe(true);
  });

  it('should handle error during bookmark toggle', async () => {
    const { result } = renderHook(() =>
      useBookmark({
        resultId: 'test-id',
        isBookmarked: false,
      })
    );

    // Mock fetch error
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: false,
      })
    ) as jest.Mock;

    await act(async () => {
      await result.current.toggleBookmark();
    });

    expect(result.current.error).not.toBeNull();
  });
});
