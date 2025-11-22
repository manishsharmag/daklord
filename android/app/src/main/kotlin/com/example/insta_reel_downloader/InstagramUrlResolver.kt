package com.example.insta_reel_downloader

import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.regex.Pattern

class InstagramUrlResolver(private val httpClient: OkHttpClient) {
    private val mediaPattern = Pattern.compile(
        "^https?://(?:www\\.)?instagram.com/(?:reel|reels|p|tv)/[A-Za-z0-9._-]+/?",
        Pattern.CASE_INSENSITIVE
    )
    private val sharePattern = Pattern.compile(
        "^https?://(?:www\\.)?instagram.com/share/[A-Za-z0-9._-]+/?",
        Pattern.CASE_INSENSITIVE
    )

    suspend fun normalize(raw: String): String? = withContext(Dispatchers.IO) {
        if (raw.isBlank()) return@withContext null
        var candidate = ensureScheme(raw.trim())
        if (sharePattern.matcher(candidate).find()) {
            val resolved = resolveShare(candidate)
            if (!resolved.isNullOrBlank()) {
                candidate = resolved
            }
        }
        candidate = stripTracking(candidate)
        if (!candidate.startsWith("https://")) {
            candidate = candidate.replaceFirst("http://", "https://")
        }
        val matcher = mediaPattern.matcher(candidate)
        if (!matcher.find()) return@withContext null
        val uri = Uri.parse(candidate)
        val cleanPath = uri.path?.trimEnd('/') ?: return@withContext candidate
        Uri.Builder()
            .scheme("https")
            .authority(uri.host ?: "www.instagram.com")
            .path(cleanPath)
            .build()
            .toString()
    }

    suspend fun resolveShare(url: String): String? = withContext(Dispatchers.IO) {
        return@withContext try {
            val request = Request.Builder()
                .url(ensureScheme(url))
                .get()
                .header("User-Agent", INSTAGRAM_WEB_USER_AGENT)
                .header("Accept", "*/*")
                .build()
            httpClient.newCall(request).execute().use { response ->
                response.request.url.toString()
            }
        } catch (_: Exception) {
            null
        }
    }

    fun extractShortcode(url: String): String? {
        val matcher = SHORTCODE_PATTERN.matcher(url)
        return if (matcher.find()) matcher.group(1) else null
    }

    private fun stripTracking(value: String): String {
        val uri = Uri.parse(value)
        val path = uri.path?.trimEnd('/') ?: return value
        return Uri.Builder()
            .scheme(uri.scheme ?: "https")
            .authority(uri.host ?: "www.instagram.com")
            .encodedPath(path)
            .build()
            .toString()
    }

    private fun ensureScheme(value: String): String {
        return if (value.startsWith("http")) value else "https://$value"
    }

    fun isShareUrl(value: String?): Boolean {
        if (value.isNullOrBlank()) return false
        return sharePattern.matcher(value).find()
    }

    companion object {
        private val SHORTCODE_PATTERN = Pattern.compile("/(?:reel|reels|p|tv)/([A-Za-z0-9._-]+)/?", Pattern.CASE_INSENSITIVE)
    }
}
