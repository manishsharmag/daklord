"""
Structured yt-dlp pipeline for Instagram reel downloads and metadata extraction.

Provides:
- extract_metadata(): Extract normalized metadata with fallbacks
- download_reel(): Download with progress tracking and error handling
"""

import json
import os
import sys
import time
from typing import Optional, Dict, Any, Callable
from pathlib import Path


class MetadataExtractor:
    """Wraps yt-dlp for structured metadata extraction with fallbacks."""

    def __init__(self):
        self.logger = PipelineLogger("MetadataExtractor")

    def extract(self, url: str) -> Dict[str, Any]:
        """
        Extract metadata from a URL using yt-dlp.

        Args:
            url: The URL to extract metadata from

        Returns:
            Dictionary with normalized fields:
                - title: str
                - author: str (uploader username)
                - duration: int (seconds)
                - width: int or None
                - height: int or None
                - thumbnail_url: str or None
                - best_stream_url: str or None (direct download URL if available)
                - raw_info: dict (raw yt-dlp output for debugging)
        """
        try:
            import yt_dlp

            self.logger.debug(f"Extracting metadata for URL: {url}")

            ydl_opts = {
                "quiet": True,
                "no_warnings": True,
                "extract_flat": False,
                "skip_download": True,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                self.logger.debug("Successfully extracted metadata via yt-dlp")
                return self._normalize_metadata(url, info)

        except Exception as e:
            self.logger.error(f"Metadata extraction failed: {e}")
            return self._fallback_metadata(url)

    def _normalize_metadata(self, url: str, info: Dict[str, Any]) -> Dict[str, Any]:
        """Normalize yt-dlp output to consistent format with fallbacks."""
        try:
            # Extract title with fallbacks
            title = (
                info.get("title", "").strip()
                or info.get("description", "").strip()[:100]
                or self._derive_title_from_url(url)
            )

            # Extract author/uploader with fallbacks
            author = (
                info.get("uploader", "").strip()
                or info.get("uploader_id", "").strip()
                or info.get("channel", "").strip()
                or "instagram"
            )

            # Ensure author has @ prefix if not already
            if author and not author.startswith("@"):
                author = f"@{author}"

            # Extract dimensions
            width = info.get("width") or None
            height = info.get("height") or None

            # Ensure positive dimensions
            if width is not None and width <= 0:
                width = None
            if height is not None and height <= 0:
                height = None

            # Extract duration
            duration = max(1, info.get("duration", 45) or 45)

            # Extract thumbnail URL
            thumbnail_url = self._extract_thumbnail_url(info, url)

            # Extract best stream URL for direct download fallback
            best_stream_url = self._extract_stream_url(info)

            return {
                "title": title,
                "author": author,
                "duration": duration,
                "width": width,
                "height": height,
                "thumbnail_url": thumbnail_url,
                "best_stream_url": best_stream_url,
                "raw_info": info,
            }
        except Exception as e:
            self.logger.error(f"Normalization failed: {e}")
            return self._fallback_metadata(url)

    def _extract_thumbnail_url(self, info: Dict[str, Any], url: str) -> Optional[str]:
        """Extract thumbnail URL with fallbacks."""
        # Try thumbnails array first
        thumbnails = info.get("thumbnails", [])
        if thumbnails:
            # Return highest quality thumbnail
            best = max(thumbnails, key=lambda t: (t.get("width", 0) * t.get("height", 0)))
            if "url" in best:
                return best["url"]

        # Try direct thumbnail field
        if info.get("thumbnail"):
            return info["thumbnail"]

        # Fallback to Instagram thumbnail derivation
        try:
            # Extract reel ID from URL
            parts = url.rstrip("/").split("/")
            for i, part in enumerate(parts):
                if part in ("reel", "reels", "p", "tv"):
                    reel_id = parts[i + 1] if i + 1 < len(parts) else None
                    if reel_id:
                        return f"https://instagram.com/p/{reel_id}/media/?size=m"
        except Exception:
            pass

        return None

    def _extract_stream_url(self, info: Dict[str, Any]) -> Optional[str]:
        """Extract best available stream URL for fallback downloads."""
        # Try to find a direct video URL
        if info.get("url"):
            return info["url"]

        # Check formats for best video URL
        formats = info.get("formats", [])
        if formats:
            # Find best MP4 format
            mp4_formats = [f for f in formats if f.get("ext") == "mp4"]
            if mp4_formats:
                best = max(mp4_formats, key=lambda f: f.get("filesize", 0) or 0)
                if best.get("url"):
                    return best["url"]

            # Fallback to any format with URL
            for fmt in formats:
                if fmt.get("url"):
                    return fmt["url"]

        return None

    def _derive_title_from_url(self, url: str) -> str:
        """Derive a title from URL when metadata extraction fails."""
        try:
            parts = url.rstrip("/").split("/")
            # Extract the reel ID (last part of URL)
            reel_id = parts[-1] if parts else "reel"
            return f"Reel_{reel_id.upper()}"
        except Exception:
            return "Instagram_Reel"

    def _fallback_metadata(self, url: str) -> Dict[str, Any]:
        """Return fallback metadata when extraction completely fails."""
        try:
            # Try to derive reel ID
            parts = url.rstrip("/").split("/")
            reel_id = None
            for i, part in enumerate(parts):
                if part in ("reel", "reels", "p", "tv"):
                    reel_id = parts[i + 1] if i + 1 < len(parts) else None
                    break

            return {
                "title": self._derive_title_from_url(url),
                "author": self._derive_author_from_url(url),
                "duration": 45,
                "width": 1080,
                "height": 1920,
                "thumbnail_url": (
                    f"https://instagram.com/p/{reel_id}/media/?size=m"
                    if reel_id
                    else None
                ),
                "best_stream_url": None,
                "raw_info": {},
            }
        except Exception:
            return {
                "title": "Instagram_Reel",
                "author": "@instagram",
                "duration": 45,
                "width": 1080,
                "height": 1920,
                "thumbnail_url": None,
                "best_stream_url": None,
                "raw_info": {},
            }

    def _derive_author_from_url(self, url: str) -> str:
        """Derive author from URL when metadata extraction fails."""
        try:
            parts = url.rstrip("/").split("/")
            # Extract username (typically after instagram.com/)
            if len(parts) > 3:
                username = parts[3]
                if username and not username.startswith("p"):
                    return f"@{username}"
        except Exception:
            pass
        return "@instagram"


class ReelDownloader:
    """Wraps yt-dlp for downloading with progress tracking and retries."""

    def __init__(self):
        self.logger = PipelineLogger("ReelDownloader")
        self.max_retries = 3
        self.retry_delay = 2

    def download(
        self,
        url: str,
        output_path: str,
        progress_callback: Optional[Callable[[Dict[str, Any]], None]] = None,
    ) -> Dict[str, Any]:
        """
        Download a reel with retries and progress tracking.

        Args:
            url: The URL to download
            output_path: Path where the video should be saved (not a template)
            progress_callback: Optional callable that receives progress dicts with:
                - status: 'downloading' or 'finished'
                - downloaded_bytes: int
                - total_bytes: int or None
                - eta: int (seconds)

        Returns:
            Dictionary with:
                - success: bool
                - error: str or None (error message if failed)
                - file_path: str or None (absolute path if successful)
                - final_status: dict (last status from progress hook)
        """
        output_path = os.path.abspath(output_path)

        self.logger.debug(f"Starting download: {url} -> {output_path}")

        # Ensure output directory exists
        output_dir = os.path.dirname(output_path)
        try:
            os.makedirs(output_dir, exist_ok=True)
        except Exception as e:
            error_msg = f"Failed to create output directory: {e}"
            self.logger.error(error_msg)
            return {
                "success": False,
                "error": error_msg,
                "file_path": None,
                "final_status": None,
            }

        # Try download with retries
        for attempt in range(1, self.max_retries + 1):
            try:
                self.logger.debug(f"Download attempt {attempt}/{self.max_retries}")
                result = self._download_attempt(url, output_path, progress_callback)
                if result["success"]:
                    return result
                elif attempt < self.max_retries:
                    self.logger.info(
                        f"Retrying download (attempt {attempt}/{self.max_retries}): {result['error']}"
                    )
                    time.sleep(self.retry_delay)
                else:
                    return result
            except Exception as e:
                error_msg = self._normalize_exception(e)
                self.logger.error(f"Download attempt {attempt} failed: {error_msg}")
                if attempt < self.max_retries:
                    time.sleep(self.retry_delay)
                else:
                    return {
                        "success": False,
                        "error": error_msg,
                        "file_path": None,
                        "final_status": None,
                    }

        return {
            "success": False,
            "error": "All retry attempts failed",
            "file_path": None,
            "final_status": None,
        }

    def _download_attempt(
        self,
        url: str,
        output_path: str,
        progress_callback: Optional[Callable[[Dict[str, Any]], None]] = None,
    ) -> Dict[str, Any]:
        """Single download attempt."""
        try:
            import yt_dlp

            final_status = {}

            class ProgressHook:
                """Bridges yt-dlp progress to caller callback."""

                def __init__(self, callback, logger):
                    self.callback = callback
                    self.logger = logger

                def __call__(self, d):
                    """Process yt-dlp progress update."""
                    try:
                        # Normalize yt-dlp status to our format
                        status_dict = {
                            "status": d.get("status", ""),
                            "downloaded_bytes": d.get("downloaded_bytes", 0),
                            "total_bytes": d.get("total_bytes") or d.get("total_bytes_estimate"),
                            "eta": d.get("eta", 0),
                        }

                        if self.callback:
                            try:
                                self.callback(status_dict)
                            except Exception as e:
                                self.logger.error(f"Progress callback error: {e}")

                        # Track final status for return value
                        nonlocal final_status
                        final_status = status_dict
                    except Exception as e:
                        self.logger.error(f"Progress hook error: {e}")

            # Configure yt-dlp with best format for Instagram
            ydl_opts = {
                "outtmpl": os.path.splitext(output_path)[0],  # Without extension
                "format": "bestvideo[ext=mp4][vcodec^=avc]+bestaudio[ext=m4a]/best[ext=mp4]/best",
                "quiet": True,
                "no_warnings": True,
                "retries": 5,
                "fragment_retries": 5,
                "retry_sleep": 2,
                "concurrent_fragments": 4,
                "socket_timeout": 30,
            }

            if progress_callback:
                ydl_opts["progress_hooks"] = [ProgressHook(progress_callback, self.logger)]

            self.logger.debug("Downloading with yt-dlp options: retries=5, fragments=4")

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])

            # yt-dlp may have created a file with a slightly different extension
            actual_output = self._find_downloaded_file(output_path)

            if actual_output and os.path.exists(actual_output) and os.path.getsize(actual_output) > 0:
                self.logger.debug(f"Download successful: {actual_output}")
                return {
                    "success": True,
                    "error": None,
                    "file_path": actual_output,
                    "final_status": final_status,
                }
            else:
                error_msg = "Download completed but no valid output file found"
                self.logger.error(error_msg)
                return {
                    "success": False,
                    "error": error_msg,
                    "file_path": None,
                    "final_status": final_status,
                }

        except Exception as e:
            error_msg = self._normalize_exception(e)
            self.logger.error(f"Download attempt failed: {error_msg}")
            return {
                "success": False,
                "error": error_msg,
                "file_path": None,
                "final_status": None,
            }

    def _find_downloaded_file(self, expected_path: str) -> Optional[str]:
        """Find the actual downloaded file (yt-dlp may adjust extension)."""
        base_path = os.path.splitext(expected_path)[0]
        dir_path = os.path.dirname(expected_path)

        # Check exact path first
        if os.path.exists(expected_path):
            return expected_path

        # Check for common video extensions
        for ext in [".mp4", ".mkv", ".webm", ".avi", ".mov"]:
            candidate = base_path + ext
            if os.path.exists(candidate):
                return candidate

        # Check if yt-dlp added any number suffix (for conflicts)
        base_name = os.path.basename(base_path)
        try:
            for entry in os.listdir(dir_path):
                if entry.startswith(base_name) and entry.endswith((".mp4", ".mkv", ".webm", ".avi", ".mov")):
                    candidate = os.path.join(dir_path, entry)
                    if os.path.getsize(candidate) > 0:
                        return candidate
        except Exception:
            pass

        return None

    def _normalize_exception(self, error: Exception) -> str:
        """Convert exceptions to readable error messages."""
        error_type = type(error).__name__
        error_msg = str(error)

        # Handle common yt-dlp errors
        if error_type == "DownloadError":
            return f"Download error: {error_msg}"
        elif error_type == "ExtractorError":
            return f"Extractor error: {error_msg}"
        elif error_type == "HTTP" in error_type or "URLError" in error_type:
            return f"Network error: {error_msg}"
        elif "No such file" in error_msg or "FileNotFoundError" in error_type:
            return f"File path error: {error_msg}"
        elif "Permission" in error_type or "Permission denied" in error_msg:
            return f"Permission error: {error_msg}"
        elif "timeout" in error_msg.lower():
            return f"Network timeout: {error_msg}"
        else:
            return f"{error_type}: {error_msg}"


class PipelineLogger:
    """Simple logger that prefixes messages with module name."""

    def __init__(self, name: str):
        self.name = name

    def debug(self, msg: str):
        print(f"[{self.name}:DEBUG] {msg}", file=sys.stderr)

    def info(self, msg: str):
        print(f"[{self.name}:INFO] {msg}", file=sys.stderr)

    def error(self, msg: str):
        print(f"[{self.name}:ERROR] {msg}", file=sys.stderr)


# Module-level instances
_metadata_extractor = MetadataExtractor()
_reel_downloader = ReelDownloader()


def extract_metadata(url: str) -> Dict[str, Any]:
    """
    Public function: Extract metadata from a URL.

    Args:
        url: Instagram reel URL

    Returns:
        Dictionary with:
            - title: str
            - author: str
            - duration: int (seconds)
            - width: int or None
            - height: int or None
            - thumbnail_url: str or None
            - best_stream_url: str or None
            - raw_info: dict (yt-dlp raw output)
    """
    return _metadata_extractor.extract(url)


def download_reel(
    url: str,
    output_path: str,
    progress_token: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Public function: Download a reel with progress tracking.

    Args:
        url: Instagram reel URL
        output_path: Absolute path where file should be saved (not a template)
        progress_token: Optional token for matching progress updates (currently unused,
                       for future use with async callbacks)

    Returns:
        Dictionary with:
            - success: bool
            - error: str or None
            - file_path: str or None (absolute path to downloaded file)
            - final_status: dict or None (last progress status)

    Note:
        Progress updates are printed to stderr and can be captured via Chaquopy
        if a progress callback is registered. For Kotlin integration, pass a
        callable that receives progress dicts as the internal progress callback.
    """
    return _reel_downloader.download(url, output_path, progress_callback=None)


# Alternate function for Kotlin convenience (same as download_reel)
def download_video(url: str, output_path: str, progress_callback=None) -> Dict[str, Any]:
    """
    Alternate download function for backward compatibility with Kotlin integration.

    This function matches the signature expected by Kotlin/Chaquopy platform channel calls.
    """
    return _reel_downloader.download(url, output_path, progress_callback=progress_callback)
