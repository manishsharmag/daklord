"""
Unit-style tests for the insta_dl.chaquopy_pipeline module.

These tests can be run:
1. On the JVM via Chaquopy (if pytest is available)
2. Locally in Python environment for development

Example local test run:
    cd android/app/src/main/python
    python3 insta_dl/tests.py

Example with pytest:
    python3 -m pytest android/app/src/main/python/insta_dl/tests.py -v

Example on JVM (if Chaquopy includes pytest):
    Add to build.gradle.kts: python { pip.install("pytest==7.4.3") }
    Then tests are available in build artifacts
"""

import os
import sys
import json
import tempfile
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

# Ensure insta_dl module can be imported
_script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _script_dir not in sys.path:
    sys.path.insert(0, _script_dir)


def test_imports():
    """Test that the module can be imported successfully."""
    try:
        from insta_dl import chaquopy_pipeline
        assert hasattr(chaquopy_pipeline, "extract_metadata")
        assert hasattr(chaquopy_pipeline, "download_reel")
        assert hasattr(chaquopy_pipeline, "download_video")
        print("✓ Module imports successfully")
        return True
    except Exception as e:
        print(f"✗ Import test failed: {e}")
        return False


def test_metadata_extractor_initialization():
    """Test that MetadataExtractor can be instantiated."""
    try:
        from insta_dl.chaquopy_pipeline import MetadataExtractor
        extractor = MetadataExtractor()
        assert hasattr(extractor, "extract")
        print("✓ MetadataExtractor initializes")
        return True
    except Exception as e:
        print(f"✗ MetadataExtractor init failed: {e}")
        return False


def test_reel_downloader_initialization():
    """Test that ReelDownloader can be instantiated."""
    try:
        from insta_dl.chaquopy_pipeline import ReelDownloader
        downloader = ReelDownloader()
        assert hasattr(downloader, "download")
        print("✓ ReelDownloader initializes")
        return True
    except Exception as e:
        print(f"✗ ReelDownloader init failed: {e}")
        return False


def test_fallback_metadata():
    """Test that metadata extraction returns fallback values on error."""
    try:
        from insta_dl.chaquopy_pipeline import MetadataExtractor

        extractor = MetadataExtractor()
        # Use a non-existent URL to trigger fallback
        result = extractor._fallback_metadata("https://instagram.com/reel/test123")

        assert isinstance(result, dict)
        assert "title" in result
        assert "author" in result
        assert "duration" in result
        assert result["duration"] > 0
        assert result["author"].startswith("@")
        print("✓ Fallback metadata returns valid structure")
        return True
    except Exception as e:
        print(f"✗ Fallback metadata test failed: {e}")
        return False


def test_title_derivation():
    """Test URL title derivation."""
    try:
        from insta_dl.chaquopy_pipeline import MetadataExtractor

        extractor = MetadataExtractor()
        title = extractor._derive_title_from_url("https://instagram.com/reel/ABC123XYZ/")
        assert title.startswith("Reel_")
        assert len(title) > 0
        print("✓ Title derivation works")
        return True
    except Exception as e:
        print(f"✗ Title derivation test failed: {e}")
        return False


def test_author_derivation():
    """Test URL author derivation."""
    try:
        from insta_dl.chaquopy_pipeline import MetadataExtractor

        extractor = MetadataExtractor()
        author = extractor._derive_author_from_url("https://instagram.com/john_doe/reel/ABC123/")
        assert author.startswith("@")
        assert len(author) > 1
        print("✓ Author derivation works")
        return True
    except Exception as e:
        print(f"✗ Author derivation test failed: {e}")
        return False


def test_normalize_metadata_with_mock():
    """Test metadata normalization with mocked yt-dlp data."""
    try:
        from insta_dl.chaquopy_pipeline import MetadataExtractor

        extractor = MetadataExtractor()
        mock_info = {
            "title": "Cool Reel",
            "uploader": "john_doe",
            "duration": 30,
            "width": 1080,
            "height": 1920,
            "thumbnails": [{"url": "https://example.com/thumb.jpg", "width": 100, "height": 100}],
        }

        result = extractor._normalize_metadata("https://instagram.com/reel/test/", mock_info)

        assert result["title"] == "Cool Reel"
        assert result["author"] == "@john_doe"
        assert result["duration"] == 30
        assert result["width"] == 1080
        assert result["height"] == 1920
        assert result["thumbnail_url"] == "https://example.com/thumb.jpg"
        print("✓ Metadata normalization works")
        return True
    except Exception as e:
        print(f"✗ Metadata normalization test failed: {e}")
        return False


def test_download_response_structure():
    """Test that download returns correct structure even on failure."""
    try:
        from insta_dl.chaquopy_pipeline import ReelDownloader

        downloader = ReelDownloader()

        # Use a mock to avoid actual download
        with patch.object(downloader, "_download_attempt") as mock_attempt:
            mock_attempt.return_value = {
                "success": False,
                "error": "Test error",
                "file_path": None,
                "final_status": None,
            }

            result = downloader.download(
                "https://instagram.com/reel/test/",
                "/tmp/test_output.mp4",
            )

            assert isinstance(result, dict)
            assert "success" in result
            assert "error" in result
            assert "file_path" in result
            assert "final_status" in result
            print("✓ Download response has correct structure")
            return True
    except Exception as e:
        print(f"✗ Download response structure test failed: {e}")
        return False


def test_exception_normalization():
    """Test exception message normalization."""
    try:
        from insta_dl.chaquopy_pipeline import ReelDownloader

        downloader = ReelDownloader()

        # Test various exception types
        exceptions = [
            (Exception("Generic error"), "Generic error"),
            (RuntimeError("Runtime problem"), "RuntimeError: Runtime problem"),
        ]

        for exc, expected_substring in exceptions:
            result = downloader._normalize_exception(exc)
            assert isinstance(result, str)
            assert len(result) > 0

        print("✓ Exception normalization works")
        return True
    except Exception as e:
        print(f"✗ Exception normalization test failed: {e}")
        return False


def test_logger():
    """Test logger functionality."""
    try:
        from insta_dl.chaquopy_pipeline import PipelineLogger
        import io
        from contextlib import redirect_stderr

        logger = PipelineLogger("TestModule")

        # Capture stderr
        stderr_capture = io.StringIO()
        with redirect_stderr(stderr_capture):
            logger.debug("Debug message")
            logger.info("Info message")
            logger.error("Error message")

        output = stderr_capture.getvalue()
        assert "[TestModule:DEBUG]" in output
        assert "[TestModule:INFO]" in output
        assert "[TestModule:ERROR]" in output
        print("✓ Logger works correctly")
        return True
    except Exception as e:
        print(f"✗ Logger test failed: {e}")
        return False


def test_output_directory_creation():
    """Test that download creates necessary output directories."""
    try:
        from insta_dl.chaquopy_pipeline import ReelDownloader

        downloader = ReelDownloader()

        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a nested path that doesn't exist yet
            nested_output = os.path.join(tmpdir, "nested", "path", "file.mp4")

            # Mock the actual download to avoid network calls
            with patch.object(downloader, "_download_attempt") as mock_attempt:
                mock_attempt.return_value = {
                    "success": False,
                    "error": "Mocked failure",
                    "file_path": None,
                    "final_status": None,
                }

                result = downloader.download(
                    "https://instagram.com/reel/test/",
                    nested_output,
                )

                # Even though download failed, directory should have been created
                assert os.path.exists(os.path.dirname(nested_output))

        print("✓ Output directory creation works")
        return True
    except Exception as e:
        print(f"✗ Output directory creation test failed: {e}")
        return False


def run_all_tests():
    """Run all tests and report results."""
    print("\n" + "=" * 60)
    print("Running insta_dl.chaquopy_pipeline smoke tests")
    print("=" * 60 + "\n")

    tests = [
        test_imports,
        test_metadata_extractor_initialization,
        test_reel_downloader_initialization,
        test_fallback_metadata,
        test_title_derivation,
        test_author_derivation,
        test_normalize_metadata_with_mock,
        test_download_response_structure,
        test_exception_normalization,
        test_logger,
        test_output_directory_creation,
    ]

    results = []
    for test in tests:
        try:
            results.append(test())
        except Exception as e:
            print(f"✗ Test {test.__name__} crashed: {e}")
            results.append(False)

    print("\n" + "=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} tests passed")
    print("=" * 60 + "\n")

    return all(results)


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
