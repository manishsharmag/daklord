# Download Logic Review and Improvements

## Reference Implementation Analysis

### 1. [KishanViramgama/InstagramDownloader](https://github.com/KishanViramgama/InstagramDownloader)
- **Download approach**: Uses `AsyncHttpClient` + OkHttp streaming to hit Instagram's undocumented `?__a=1&__d=dis` GraphQL endpoint. Parses the JSON directly to extract `video_url` / `display_url` fields and loops through `edge_sidecar_to_children` for carousel posts.
- **Authentication & headers**: Sends explicit desktop `User-Agent`, `Accept`, `Content-Type`, and `x-requested-with` headers to mimic browser requests.
- **Error handling**: Validates URLs, checks network connectivity, and surfaces user-friendly toasts when responses fail or downloads are cancelled.
- **File handling**: Saves into the app's scoped external storage directory with timestamped filenames and maintains separate image/video arrays.
- **Progress reporting**: Wraps OkHttp responses with `ProgressHelper` to emit byte-level progress into a foreground notification.

### 2. [Okramjimmy/Instagram-reels-downloader](https://github.com/Okramjimmy/Instagram-reels-downloader)
- **Download approach**: Implements both HTML scraping (meta tags) and Instagram GraphQL POST calls (doc_id `10015901848480474`). Resolves `instagram.com/share/...` links by following redirects before extracting the shortcode.
- **Quality selection**: Chooses the highest quality stream from `video_resources` and `video_versions`, ensuring MP4 output.
- **Metadata**: Builds a rich `VideoInfo` payload (title, width, height, URL) and exposes it through a Next.js API. Uses Cheerio to parse fallbacks when GraphQL is denied.
- **Error handling**: Wraps responses in typed HTTP errors and surfaces consistent JSON to the frontend.
- **Networking**: Centralises fetch logic inside an API client with retry-safe error mapping, and configures headers (X-FB-LSD, X-IG-App-ID, etc.) to satisfy Instagram's web API expectations.

## Comparison With Our Previous Implementation

| Capability | Previous State | Reference Insights | New Behaviour |
| --- | --- | --- | --- |
| URL handling | Basic regex validation for `/reel|p|tv/` URLs; share links failed. | Okramjimmy resolver follows `/share/*` redirects before validation. | Added `InstagramUrlResolver` with OkHttp redirect following + normalization. Validation now happens asynchronously inside coroutines. |
| Metadata extraction | Only `yt-dlp --dump-json`, no API fallback, limited thumbnails. | GraphQL provided faster, lightweight metadata and direct MP4 URLs. | Added `InstagramGraphqlClient` to request GraphQL first, fall back to yt-dlp, and capture highest-quality direct URLs. |
| Quality selection | `yt-dlp -f best` with minimal error context. | Both repos explicitly pick MP4/H.264 streams and retry HTTP fetches. | Updated yt-dlp args to prefer AVC MP4 muxed with M4A, added retries/fragment retries, parsed ETA/progress, and surfaced failure reasons. |
| Download fallback | Generated synthetic stub files when yt-dlp failed. | Reference apps either retried or surfaced the error. | Removed stub behaviour. If yt-dlp fails we attempt a direct OkHttp download using GraphQL `video_url`; otherwise the task is marked failed with context. |
| File organisation | All files in a flat `instagram-reels` folder. | Reference apps grouped downloads logically. | Files now live under `Downloads/instagram-reels/<author>/Title_taskId.mp4` for easier navigation. |
| Error messaging | Generic "Download failed" from Kotlin layer. | Reference repos relayed richer errors (HTTP codes, not-supported). | Downloader pipeline now propagates yt-dlp/HTTP failure summaries up to the task stream, so the UI surfaces actionable feedback. |
| Networking stack | Platform channels only; no reusable HTTP helper. | Both repos leaned on OkHttp/fetch with tuned headers. | Introduced shared OkHttp client with tuned timeouts for validation, GraphQL, and direct download paths. |

## Improvements Implemented in This Branch

1. **Share URL normalization** — Added `InstagramUrlResolver` + suspendable `ReelUrlValidator` so `/share/...` links are dereferenced via OkHttp before validation/metadata extraction.
2. **GraphQL metadata pipeline** — New `InstagramGraphqlClient` mirrors Okramjimmy's request payload (headers, doc_id, LSD token) to fetch `video_resources`, thumbnails, and captions. Metadata now includes a `directDownloadUrl` for fallback downloads.
3. **Yt-dlp enhancements** — Updated format selector to prioritise H.264 MP4 muxed with M4A, enabled retries/fragment retries, parsed progress + ETA for better UI updates, and bubbled meaningful errors when yt-dlp exits non-zero.
4. **Direct HTTP fallback** — When yt-dlp can't deliver, we stream the GraphQL `video_url` with OkHttp, emit byte-level progress, and still run FFmpeg to guarantee H.264 + AAC output.
5. **Folder organisation** — Downloads are grouped by author handle (`Downloads/instagram-reels/<author>`), producing cleaner libraries while still honouring custom folders.
6. **Retry semantics** — Retrying a task now re-fetches metadata so a stale task picks up new thumbnails, durations, and direct URLs.
7. **Documentation** — Captured the above review + alignment in this file for future contributors.

## Verification

- Exercised URL validation on canonical reels, posts, and share links (ensuring redirects resolve and invalid URLs return descriptive reasons).
- Checked metadata extraction with network available/unavailable by forcing GraphQL success and yt-dlp fallback.
- Simulated yt-dlp failures to confirm direct-download fallback and error propagation update the UI stream.
- Verified downloads land inside `Downloads/instagram-reels/<author>/...` with sanitized filenames and FFmpeg remuxed output.

*(Instrumented tests are not provided in this environment; manual verification conducted via log output and emulator testing.)*
