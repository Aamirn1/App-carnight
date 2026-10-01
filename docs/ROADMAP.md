# Phased development plan

## Objective and launch boundaries

Build a Flutter application for Android and iOS: image-based car community,
car sale listings and rental listings with the reference's dark neon identity.
Start with a tightly scoped release, not a worldwide transactional rental system.
Worldwide installability and actual marketplace operations are different goals.
Initial rental flows should be enquiries; booking, insurance, deposits, payments
and paid promotion need their own requirements before being enabled.

“Ads” is provisionally interpreted as user-created car listings. No external ad
network or paid campaign system is assumed. No videos, reels, livestreaming,
video stories or video attachments in launch scope. AI chat is deferred.

## Phases and completion gates

| Phase | Deliverable | Must pass before marked complete |
|---|---|---|
| 0 — Scope and reference | Screen inventory, image-only constraints, provisional visual tokens, architecture and cost limits | Separate observed design from assumptions; document unknown assets/backend/budget |
| 1 — Flutter foundation | Source layout, theme, navigation, domain types, fixtures and test baseline | Real SDK pin, native host generation, formatting, analyze, tests and first real-device run |
| 2 — Visual prototype | Faithful welcome/feed/buy/rent/drawer, original brand/hero assets and layouts for unseen pages | Reviewed Flutter screenshots, narrow/large-text checks, no misleading working buttons |
| 3 — Secure services | Authentication, recovery, deletion, database, object storage and image processing | Ownership rules, invalid media rejection, quotas, signed uploads, deletion, authorization tests |
| 4 — Community | Image composer, paginated feed, profiles, likes/comments/saves, reporting/blocking | Create/edit/delete flows, restart persistence, failures/retries, authorization and moderation checks |
| 5 — Buy marketplace | Sale listings, photo gallery, filters, details, seller profile and contact/enquiry | Listing ownership, currency correctness, search pagination, expiry and abuse reporting |
| 6 — Rent marketplace | Rental listings, dates/location, daily pricing, owner enquiries | Time-zone/date validation; availability and price claims only when backed by real data |
| 7 — Supporting pages | Settings, notifications, blog, about/contact, plan explanation, moderation console | Correct deep links, delivery retries, accessibility, genuine content and permissions |
| 8 — Release hardening | Device/network profiling, image/cost audit, security review, signed builds | End-to-end and permission-denial tests, backups/restore, monitoring, all critical gaps closed |
| 9 — Final fidelity report | Screenshots and reference comparisons, feature matrix, measured performance and limitations | Honest per-screen results, real build/test logs, documented launch blockers |

Current progress: Phase 0 initial specification produced; Phase 1 source authored,
runtime verification blocked. Phase 2 visual prototype source and supporting layouts
have been added. Phase 1 and Phase 2 acceptance gates remain open. Connected services
and Phases 3–9 are not implemented. See STATUS.md for the latest evidence.

## Architecture and implementation discipline

Use feature-oriented presentation code with explicit domain models and repository
boundaries as services arrive. Keep Flutter as the sole UI source of truth. The
current in-memory demo is deliberately small; it is not a backend architecture.
Introduce repositories for authentication, posts, listings, media and profiles in
Phase 3; inject real and fake implementations for meaningful tests.

A single managed relational backend plus object storage is a candidate starting
point. Select the provider only after comparing current pricing, regions, free
limits, egress, image processing and auth support. No provider or spending is
committed in this bundle. Do not create microservices for the MVP.

Suggested entities: profiles, posts, post_images, listings, listing_images,
likes, comments, saved_items, reports and rental_enquiries. Store original currency
codes and integer minor-unit amounts. Use UTC timestamps and explicit local/date
semantics for rentals. Do not use hard-coded demo currency formatting in production.
Use keyset pagination and database indexes for feed/listing queries. Enforce row
ownership server-side; mobile code is not a trust boundary. Moderators receive
separate least-privilege permissions. Server secrets never ship in the app.

Prevent common AI development failures: one reviewed phase at a time, trace each
requirement to a screen and test, no fabricated API responses, no swallowed errors,
no invented test results, and no automatic “production-ready” label. Review package
maintenance and compatibility before adding dependencies. Test authorization and
failure cases rather than just widget existence. Use screenshot review to catch
spacing/asset drift that generated code can miss.

## Low-budget image strategy (proposed limits)

- Start at 4 images per post/listing and 8 MiB input per source image. Allow JPEG,
  PNG and WebP; on-device HEIC conversion can be added with a tested mobile plugin.
- Before upload, resize to at most 1600 pixels on the long edge and compress to a
  target around 250 KB; enforce a separate hard processed-output limit server-side.
- Produce a roughly 480-pixel feed thumbnail, targeting around 50 KB; use larger
  derivatives only on detail views. Quality targets require inspection of car text
  and details and may need adjustment rather than destroying image clarity.
- Decode/re-encode on the server, validate dimensions and byte limits, strip EXIF
  including location metadata, and reject malformed files or disguised videos.
- Upload into a temporary owner-scoped area; publish only after validation. Delete
  rejected/orphaned objects with a scheduled cleanup task.
- Retain only approved derivatives after processing succeeds unless an explicit
  recovery requirement justifies keeping originals. Use transactional deletion
  jobs so deleted posts and accounts do not leave permanent media objects.
- Start pagination at 15–20 items. Use lazy lists, bounded disk cache and decode
  dimensions appropriate to the display; avoid downloading full image galleries
  in feeds. A data-saver setting should prefer thumbnails.
- Quota uploads and posting frequency per account, add abuse controls and budget
  alerts, and support a server upload-disable switch without a new app release.

Illustration, not a hosting quote: 10,000 items × 3 images × (250 KB detail + 50 KB
thumbnail) is about 9 GB decimal before backups, metadata and overhead. One million
50 KB image deliveries is about 50 GB transfer. Image-only still has ongoing costs;
bandwidth and abuse can matter more than stored bytes. Exact monthly budget and
expected active users/uploads remain unknown.

## Broad compatibility and speed

The currently retrieved Flutter platform matrix lists Android API 24+ and iOS 15+
as supported for its documented release. Confirm the matrix for the SDK actually
pinned and all plugins; do not promise every phone or a percentage of global devices.
Provide ARM32/ARM64 Android builds when supported by the selected toolchain/plugins.
Maintain an explicit test matrix covering low-memory Android, midrange Android,
supported iPhones, narrow screens, large text and slow/offline networks.

Localization-ready strings, RTL layouts, phone/email formats, currencies and local
dates are required for global usability. English demo copy is not localization.
Release with selected languages and service regions instead of claiming untested
worldwide support. Downloadable Android builds and iOS signing/distribution need
separate release setup.

Proposed targets, NOT measured results: useful cached UI within 2 seconds on an
agreed low-end baseline; smooth 60 Hz scrolling with most frames within 16.7 ms;
no full-resolution feed downloads, no unbounded cache and no crashes after repeated
scroll/upload cycles. Final targets depend on the actual test device, release/profile
mode, network, image payload and backend region. Measure cold startup, jank, memory,
network bytes, binary size and upload success rather than assuming Flutter guarantees
speed. Profile with DevTools on real devices, not debug-mode browser timings.

## References consulted

- https://docs.flutter.dev/reference/supported-platforms
- https://docs.flutter.dev/perf/best-practices
- https://docs.flutter.dev/perf/ui-performance

Official guidance supports lazy construction of long lists and real profiling.
It does not certify this unexecuted source bundle's performance.
