# Phase 3: photo publishing pilot — 0.5.0

The welcome artwork now begins at the top of the viewport, including beneath
the status bar. The approved car image, logo and gradient are retained.

Signed-in Create offers a single JPEG photo, preview and caption. The protected
server validates, re-encodes and stores a bounded image, then atomically publishes
its post. Stable request IDs protect retries within the open composer.

See [PHOTO_SETUP.md](PHOTO_SETUP.md) for the new SQL migration, Edge Function
deployment instructions, conservative pilot quotas and acceptance checklist.
No admin connection was available; live SQL/function deployment is not claimed.

Next release gates: live two-account/device media testing, moderation and deletion
lifecycle, durable local drafts/retries, multiple images, website inventory mapping,
realtime/push delivery, production signing and measured device performance.
