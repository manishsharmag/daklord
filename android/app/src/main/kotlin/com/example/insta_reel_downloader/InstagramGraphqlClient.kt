package com.example.insta_reel_downloader

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject

class InstagramGraphqlClient(
    private val httpClient: OkHttpClient,
    private val urlResolver: InstagramUrlResolver,
) {
    suspend fun fetchMedia(url: String): InstagramGraphqlMedia? = withContext(Dispatchers.IO) {
        val shortcode = urlResolver.extractShortcode(url) ?: return@withContext null
        val requestBody = buildRequestBody(shortcode)
        val request = Request.Builder()
            .url(GRAPHQL_ENDPOINT)
            .post(requestBody)
            .header("Accept", "*/*")
            .header("Accept-Language", "en-US,en;q=0.9")
            .header("Content-Type", "application/x-www-form-urlencoded")
            .header("X-FB-Friendly-Name", FRIENDLY_NAME)
            .header("X-CSRFToken", CSRF_TOKEN)
            .header("X-IG-App-ID", APP_ID)
            .header("X-FB-LSD", FB_LSD)
            .header("X-ASBD-ID", ASBD_ID)
            .header("User-Agent", INSTAGRAM_MOBILE_USER_AGENT)
            .header("Referer", "https://www.instagram.com/")
            .build()
        try {
            httpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return@withContext null
                val payload = response.body?.string() ?: return@withContext null
                return@withContext parseResponse(shortcode, payload)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun buildRequestBody(shortcode: String): FormBody {
        val variables = JSONObject()
            .put("shortcode", shortcode)
            .put("fetch_comment_count", JSONObject.NULL)
            .put("fetch_related_profile_media_count", JSONObject.NULL)
            .put("parent_comment_count", JSONObject.NULL)
            .put("child_comment_count", JSONObject.NULL)
            .put("fetch_like_count", JSONObject.NULL)
            .put("fetch_tagged_user_count", JSONObject.NULL)
            .put("fetch_preview_comment_count", JSONObject.NULL)
            .put("has_threaded_comments", false)
            .put("hoisted_comment_id", JSONObject.NULL)
            .put("hoisted_reply_id", JSONObject.NULL)
        return FormBody.Builder()
            .add("av", "0")
            .add("__d", "www")
            .add("__user", "0")
            .add("__a", "1")
            .add("__req", "3")
            .add("__hs", "19624.HYP:instagram_web_pkg.2.1..0.0")
            .add("dpr", "3")
            .add("__ccg", "UNKNOWN")
            .add("__rev", "1008824440")
            .add("__s", "xf44ne:zhh75g:xr51e7")
            .add("__hsi", "7282217488877343271")
            .add(
                "__dyn",
                "7xeUmwlEnwn8K2WnFw9-2i5U4e0yoW3q32360CEbo1nEhw2nVE4W0om78b87C0yE5ufz81s8hwGwQwoEcE7O2l0Fwqo31w9a9x-0z8-U2zxe2GewGwso88cobEaU2eUlwhEe87q7-0iK2S3qazo7u1xwIw8O321LwTwKG1pg661pwr86C1mwraCg"
            )
            .add(
                "__csr",
                "gZ3yFmJkillQvV6ybimnG8AmhqujGbLADgjyEOWz49z9XDlAXBJpC7Wy-vQTSvUGWGh5u8KibG44dBiigrgjDxGjU0150Q0848azk48N09C02IR0go4SaR70r8owyg9pU0V23hwiA0LQczA48S0f-x-27o05NG0fkw"
            )
            .add("__comet_req", "7")
            .add("lsd", FB_LSD)
            .add("jazoest", "2957")
            .add("__spin_r", "1008824440")
            .add("__spin_b", "trunk")
            .add("__spin_t", "1695523385")
            .add("fb_api_caller_class", "RelayModern")
            .add("fb_api_req_friendly_name", FRIENDLY_NAME)
            .add("variables", variables.toString())
            .add("server_timestamps", "true")
            .add("doc_id", DOC_ID)
            .build()
    }

    private fun parseResponse(shortcode: String, payload: String): InstagramGraphqlMedia? {
        return try {
            val root = JSONObject(payload)
            val data = root.optJSONObject("data") ?: return null
            val media = data.optJSONObject("xdt_shortcode_media")
                ?: data.optJSONObject("shortcode_media")
                ?: return null
            if (!media.optBoolean("is_video", true)) {
                return null
            }
            val owner = media.optJSONObject("owner")
            val username = owner?.optString("username")?.takeIf { it.isNotBlank() }
            val titleCandidates = listOf(
                media.optString("title"),
                media.optJSONObject("edge_media_to_caption")
                    ?.optJSONArray("edges")
                    ?.optJSONObject(0)
                    ?.optJSONObject("node")
                    ?.optString("text"),
            ).mapNotNull { it?.takeIf { candidate -> candidate.isNotBlank() } }
            val title = titleCandidates.firstOrNull()
            val thumbnail = media.optString("display_url").takeIf { it.isNotBlank() }
                ?: media.optString("thumbnail_src").takeIf { it.isNotBlank() }
            val duration = media.optDouble("video_duration", 0.0)
                .takeIf { it > 0 }?.toInt()
            val dimensions = media.optJSONObject("dimensions")
            val width = dimensions?.optInt("width")?.takeIf { it > 0 }
            val height = dimensions?.optInt("height")?.takeIf { it > 0 }
            val resources = mutableListOf<GraphqlVideoResource>()
            collectResources(media.optJSONArray("video_resources"), "src", "config_width", "config_height", null, resources)
            collectResources(media.optJSONArray("video_versions"), "url", "width", "height", null, resources)
            val dashInfo = media.optJSONObject("dash_info")
            if (dashInfo != null) {
                collectResources(dashInfo.optJSONArray("video_resources"), "url", "width", "height", null, resources)
            }
            val directUrl = selectBestResource(resources)
                ?: media.optString("video_url").takeIf { it.isNotBlank() }
            InstagramGraphqlMedia(
                shortcode = shortcode,
                username = username,
                title = title,
                thumbnailUrl = thumbnail,
                durationSeconds = duration,
                width = width,
                height = height,
                videoUrl = directUrl,
                resources = resources
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun collectResources(
        array: JSONArray?,
        urlKey: String,
        widthKey: String,
        heightKey: String,
        bitrateKey: String?,
        output: MutableList<GraphqlVideoResource>,
    ) {
        if (array == null) return
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            val url = item.optString(urlKey).takeIf { it.isNotBlank() } ?: continue
            val width = item.optInt(widthKey).takeIf { it > 0 }
            val height = item.optInt(heightKey).takeIf { it > 0 }
            val bitrate = bitrateKey?.let { key -> item.optInt(key).takeIf { it > 0 } }
            output.add(GraphqlVideoResource(url, width, height, bitrate))
        }
    }

    private fun selectBestResource(resources: List<GraphqlVideoResource>): String? {
        if (resources.isEmpty()) return null
        return resources.maxWithOrNull(compareBy<GraphqlVideoResource> { (it.width ?: 0) * (it.height ?: 0) }
            .thenByDescending { it.bitrate ?: 0 })?.url
    }

    companion object {
        private const val GRAPHQL_ENDPOINT = "https://www.instagram.com/api/graphql"
        private const val FRIENDLY_NAME = "PolarisPostActionLoadPostQueryQuery"
        private const val DOC_ID = "10015901848480474"
        private const val APP_ID = "1217981644879628"
        private const val CSRF_TOKEN = "RVDUooU5MYsBbS1CNN3CzVAuEP8oHB52"
        private const val FB_LSD = "AVqbxe3J_YA"
        private const val ASBD_ID = "129477"
    }
}

data class InstagramGraphqlMedia(
    val shortcode: String,
    val username: String?,
    val title: String?,
    val thumbnailUrl: String?,
    val durationSeconds: Int?,
    val width: Int?,
    val height: Int?,
    val videoUrl: String?,
    val resources: List<GraphqlVideoResource>,
) {
    fun toMetadata(sourceUrl: String): ReelMetadata {
        val safeAuthor = username?.takeIf { it.isNotBlank() } ?: "instagram"
        val normalizedAuthor = if (safeAuthor.startsWith("@")) safeAuthor else "@$safeAuthor"
        val derivedTitle = title?.takeIf { it.isNotBlank() }
            ?: "Reel ${shortcode.uppercase()}"
        val duration = durationSeconds ?: 45
        return ReelMetadata(
            url = sourceUrl,
            title = derivedTitle,
            author = normalizedAuthor,
            durationSeconds = duration,
            thumbnailUrl = thumbnailUrl,
            width = width,
            height = height,
            directDownloadUrl = videoUrl,
        )
    }
}

data class GraphqlVideoResource(
    val url: String,
    val width: Int?,
    val height: Int?,
    val bitrate: Int?,
)
