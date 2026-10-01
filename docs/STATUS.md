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
