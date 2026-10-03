# Latest: version 0.6.0 — account and Home feed update

See [AUTH_AND_HOME_0.6.md](AUTH_AND_HOME_0.6.md) for the APK, verified results and
required hosted email configuration. All 34 Flutter tests, 4 media tests and
isolated database checks passed; analysis found no issues. The 54.0 MB preview
APK built successfully. Native Gmail, live confirmation and physical-device
visual acceptance remain unverified. No hosted Auth/SMTP settings were changed.
Country/city use account metadata; website inventory remains a separate bridge.

---

# Latest: version 0.5.0 — welcome fix and photo publishing pilot

See [PHOTO_SETUP.md](PHOTO_SETUP.md) for verified results, the latest APK,
new SQL migration and Edge Function deployment instructions. Earlier reports
below describe historical versions; their photo-publication status is superseded.
Live deployment, device upload testing and production release gates remain open.

---

# Latest: version 0.4.1

See [the verified launcher and UI update report](UI_UPDATE_0.4.1.md) for the latest APK.
The backend scope and remaining work described below are unchanged.

---

# Version 0.4.0 verification — 2 October 2026 (UTC)

Tested source commit: `5382f918d60427c5ec6b491e68d7ed417dbb7f5a`.

- [GitHub Actions run](https://github.com/Aamirn1/App-carnight/actions/runs/37035835530).
- Flutter analysis: **No issues found**.
- Flutter unit/widget/mocked HTTP tests: **29 passed**.
- Isolated PostgreSQL ownership and social checks: **passed**. Coverage includes
  conversation consent, private-message isolation, blocking, message retry IDs,
  draft publication restrictions and basic write limits.
- Android release-mode preview APK: **52.9 MB**, development signed.
- [Download APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/37035835530/artifacts/11241001708).
  Available until 16 October 2026; rerun Actions after expiry.
- The initial Android build hit an invalid NDK download; a fresh runner completed
  successfully without app-source changes.

## Scope of this increment

Home / Messages / Create / Marketplace / Profile now places the community first.
Discover/Following, people search, follows, likes, comments, consent-based text
conversations, block/unblock and reports have Supabase-backed implementations.
Marketplace combines sample Buy/Rent offers. Create saves private text drafts.
The supplied public anon key is included in client build configuration.

## Live activation and limits

The last successful read-only API check reached Supabase Auth and the website
Listing endpoint. The mobile tables were missing at that check. Listing returned
no anon-visible rows; this does not establish that the website database is empty.
No live DDL, real account/email creation, message sending or user-data mutation
was performed. The anon key cannot install SQL. Use [setup instructions](SUPABASE_SETUP.md)
and the prepared first-install script; existing mobile installations need only
its new social migration after checking migration history.

Public photo uploads/publication, realtime/push delivery, unread counts, public
share links, online saved collections, website Listing mapping, moderation tools,
account deletion and production signing are still open. Threads refresh manually.
Keep Supabase initially; see [product/budget decisions](SOCIAL_PRODUCT.md).

## Design and device verification

The approved dark background, neon accents, wordmark and card styling remain;
selected navigation icons are cyan. New social pages and navigation intentionally
extend the reference. No new physical-device screenshots or performance profiles
were captured. Pixel matching and broad phone compatibility are unverified.
The build is a development preview, not a production release.

Runner-formatted Dart and the resolved dependency lock are preserved alongside
this report. Subsequent documentation/formatting commits do not change app behavior.

---

# Historical reports (superseded by version 0.4.0 above)

# Version 0.3.0 verification — 2 October 2026 (Pakistan time)

Built source commit: `f62ceaf68b2c36d05aeab112350cd5400f1aaa78`.

- [Successful GitHub Actions run](https://github.com/Aamirn1/App-carnight/actions/runs/36927176905).
- Flutter analysis: **No issues found**.
- Flutter unit/widget/mocked HTTP tests: **25 passed**.
- Isolated PostgreSQL ownership checks: **passed**, including protection of generic
  website table names while the mobile migration creates separate `cn_*` tables.
- Android release-mode preview APK: **51.6 MB**, development signed.
- [Download APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/36927176905/artifacts/11194860781).
  Artifact retention ends 15 October 2026; rerun Actions for another build.

## What changed

Flutter Supabase initialization and public-key validation, email account flows,
session/recovery event handling, Android callback/internet configuration, private
paged post/sale/rental text drafts, error/retry states and ownership filters.
The selected navigation icon remains cyan. Home's approved layout and imagery
are retained in source. This increment has no new device screenshots; exact
reference matching across pages/devices and callback behavior are not verified.

## Live connection is blocked on configuration

The supplied key was `your-anon-key`. The build's public key variable was empty.
No real credentials were submitted; no real email, account or draft was created;
no migration or auth settings were applied to the website's live Supabase project.
See [Supabase setup](SUPABASE_SETUP.md) for the public key, isolated SQL migration
and callback configuration. The SDK code is implemented, but live functionality
must not be represented as tested until those checks are completed.

Public image uploads, publishing, server validation/moderation and quotas, live
feed/listing integration, online saved collections/reactions, account deletion,
production signing and broad device/performance testing remain unfinished.
The app remains a development preview, not a production release.

---

# Historical reports (superseded by the status above)

# GitHub Actions verification — 1 October 2026

The previous local SDK limitation has been resolved for Android through GitHub
Actions. The offline prototype has now been compiled into an installable APK.

- Tested source commit: `1e02e3ed334cedb8a7675112f6f89d8d7db591c0`.
- [Successful build and logs](https://github.com/Aamirn1/App-carnight/actions/runs/36845637727).
- Flutter 3.35.7, Java 17, Ubuntu 24.04.
- Analyzer: no errors or warnings; two informational `prefer_const_constructors`
  suggestions. The workflow allows informational suggestions only.
- Automated tests: **17 passed**.
- Release-mode APK: **48.4 MB**, development-signed for testing.
- [APK artifact](https://github.com/Aamirn1/App-carnight/actions/runs/36845637727/artifacts/11153237715).
- Artifact expiry: 15 October 2026. Use Run workflow to generate a fresh build.
- Runner-formatted Dart source, resolved pubspec.lock and generated Android host
  are retained in this repository. Machine-local paths and generated registration
  files are excluded. The source below has only formatting differences from the
  tested commit; no functional changes were made after the build.

Device installation, screenshots, performance profiling and exact reference matching
have NOT been verified. Login, uploads, bookings and seller enquiries are still
unconnected. This is a testable offline prototype, not a production release.

---

## Historical Phase 2 source-work report (before GitHub Actions)

# Cars Night — Phase 2 development report

## Status

Phase 2 source work has advanced. **Phase 1 runtime verification and Phase 2 visual
acceptance remain open.** This is an offline prototype source bundle, not a
production build, APK/IPA, deployed web app or verified Flutter preview.

## Work added

| Area | Current behavior in source |
|---|---|
| Welcome | Local neon car/city artwork, generated script wordmark, Get Started, sign-in navigation |
| Feed | Photo cards, sample story viewer, text search, local likes/saves/comments, copy-caption action |
| Create | Caption validation, 1–4 bundled sample images, add/delete local demo posts; no upload or video |
| Buy | Search/category filters, photo cards, details, save/unsave, recoverable no-results state |
| Rent | City and model filters, date range, compact cards; sample base-price calculation |
| Saved/profile | Collection updates when items are saved or removed; profile displays local posts |
| Navigation | Reference-inspired drawer and five bottom destinations; tabs constructed on first visit |
| Supporting layouts | Sign-in/signup/recovery, listing form/preview, settings, notifications, plan, blog/article, about and contact |

State is session-only. Leaving the demo resets it. Authentication and enquiry
buttons clearly explain that services are not connected. No emails, seller messages,
bookings, uploads or payments are sent. No live premium entitlement is fabricated.

## Asset and performance work

Five bundled assets total **556,369 bytes** (approximately 543 KiB): four WebP
photographs and one alpha-transparent PNG wordmark. They are generated artwork,
not real listing photos or exact extracts from the montage. Original generated
outputs remain separate; the source bundle contains delivery-size assets.

The source uses fixed image aspect ratios, error fallbacks and bounded decode
widths. The normal cap is 1,000 pixels; the lower-detail option caps at 480 pixels.
Long feed/marketplace lists use lazy builders. Unvisited main tabs are not built.
No animations, external fonts, remote images or additional package dependencies
were added in this milestone.

These are implementation choices, not measured speed claims. Actual launch time,
frame timings, memory footprint, install size and network behavior are untested.
Flutter documents custom image decode dimensions as a way to reduce image-cache
memory: https://api.flutter.dev/flutter/widgets/Image/Image.asset.html

## Checks actually performed

- All local Dart imports and declared image asset paths resolve: passed.
- Image file inspection: four RGB WebP assets and one RGBA PNG; dimensions valid.
- Shell syntax checks for bootstrap.sh and check.sh: passed.
- SDK verification runner invoked: exited 2, `BLOCKED: Flutter SDK is not installed.`
- Seventeen test cases authored (12 domain/state and 5 widget tests): NOT RUN.
- Dart formatting, compiler/type checking, Flutter analysis: NOT RUN.
- Android/iOS native generation, application builds and device launch: NOT RUN.
- Real screenshots, accessibility execution, golden tests and performance tests: NOT RUN.

The import/asset and shell checks do not establish Dart correctness. Tests are
included for later execution, not reported as passing.

## Reference comparison

| Reference screen | Improvements in source | Remaining differences | Rendered match |
|---|---|---|---|
| Welcome | Actual hero artwork and script logo replace placeholders; gradient and outlined CTAs | Artwork and lettering are new interpretations; spacing requires device review | Unverified |
| Social feed | Photos, circular photo rail, header actions, engagement row and bottom navigation | Reference uses specific brand/user circles; ours are sample themed stories; avatars are initials | Unverified |
| Buy | Search, categories, large car photos, favorites and detail navigation | All/Buy/Rent segmented switch and circular category styling differ; demo assortment is smaller | Unverified |
| Rent | Location, pickup/drop-off controls and horizontal cards | Two sample vehicles; no unsupported real ratings; no live availability | Unverified |
| Drawer | Script logo, close control, gradient selected item and named menu destinations | Guest identity replaces the pictured account; premium membership is not claimed | Unverified |

Supporting pages follow the same theme but have no exact counterpart in the
reference. No percentage fidelity score is claimed. A generated artwork image
is not a screenshot of the running app.

## Next checkpoint

Use a Flutter-enabled computer or CI environment to run the supplied commands
and tests. Fix all errors, capture real screens, compare against the supplied
reference and resolve the layout differences before clearing visual acceptance.
A backend provider, actual monthly spending limit, service regions, account/store
identities and original brand assets still need to be settled for later phases.
