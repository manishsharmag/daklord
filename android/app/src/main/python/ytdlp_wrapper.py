"""
Wrapper for yt-dlp functionality used by the Android app via Chaquopy.
"""
import json
import os
import sys
from typing import Optional, Dict, Any


def extract_metadata(url: str) -> Optional[str]:
    """
    Extract metadata from a URL using yt-dlp.
    
    Args:
        url: The URL to extract metadata from
        
    Returns:
        JSON string containing metadata or None if extraction fails
    """
    try:
        import yt_dlp
        
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
            'skip_download': True,
        }
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            return json.dumps(info)
    except Exception as e:
        print(f"Error extracting metadata: {e}", file=sys.stderr)
        return None


def download_video(url: str, output_path: str, progress_callback=None) -> Dict[str, Any]:
    """
    Download a video using yt-dlp.
    
    Args:
        url: The URL to download
        output_path: Path where the video should be saved
        progress_callback: Optional callback function for progress updates
        
    Returns:
        Dictionary with 'success' (bool), 'error' (str or None), and 'file_path' (str or None)
    """
    try:
        import yt_dlp
        
        class ProgressHook:
            def __init__(self, callback):
                self.callback = callback
                
            def __call__(self, d):
                if self.callback is None:
                    return
                    
                if d['status'] == 'downloading':
                    total = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                    downloaded = d.get('downloaded_bytes', 0)
                    if total > 0:
                        progress = downloaded / total
                        eta = d.get('eta', 0)
                        self.callback(progress, eta)
                elif d['status'] == 'finished':
                    if self.callback:
                        self.callback(1.0, 0)
        
        ydl_opts = {
            'outtmpl': output_path,
            'format': 'bestvideo[ext=mp4][vcodec^=avc]+bestaudio[ext=m4a]/best[ext=mp4]/best',
            'quiet': True,
            'no_warnings': True,
            'retries': 5,
            'fragment_retries': 5,
            'retry_sleep': 2,
            'concurrent_fragments': 4,
        }
        
        if progress_callback:
            ydl_opts['progress_hooks'] = [ProgressHook(progress_callback)]
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
            
        # Check if file was created
        if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
            return {
                'success': True,
                'error': None,
                'file_path': output_path
            }
        else:
            return {
                'success': False,
                'error': 'Download completed but file not found or empty',
                'file_path': None
            }
            
    except Exception as e:
        error_msg = str(e)
        print(f"Error downloading video: {error_msg}", file=sys.stderr)
        return {
            'success': False,
            'error': error_msg,
            'file_path': None
        }
