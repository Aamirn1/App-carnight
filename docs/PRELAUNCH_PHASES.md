> Phase C checkpoint: live app marketplace and realtime/unread messaging implemented; schema deployed. See [MARKETPLACE_PHASE_C_0.12.md](MARKETPLACE_PHASE_C_0.12.md). Acceptance and remaining feature work are explicitly open. APK builds deferred at the user’s request.

> Latest checkpoint: **0.11.0+13 — Phase B implementation deployed; device acceptance pending.** See [COMMUNITY_PHASE_B_0.11.md](COMMUNITY_PHASE_B_0.11.md) for features, test evidence, APK and remaining gates. This supersedes older statements below about missing deletion, member profiles, saved feeds and thumbnails. Website login is separate; app deletion does not remove website records.

# Cars Night consolidated pre-launch plan

This plan replaces fragmented milestone sequencing. Complete the four phases in
order. A phase closes only when its acceptance gates pass; working source alone
does not mean public-launch readiness. Initial scope remains image-only social
media for car lovers, with a secondary Buy/Rent marketplace.

| Phase | Combined work | Acceptance gate |
|---|---|---|
| A — Consistent UI and feature audit | Original logo in both themes; colour/readability audit; spacing and narrow-screen fixes; navigation and complete inventory of controls | Theme renders and functional tests pass; original lettering/gradient preserved; every control classified as live, sample, deferred or broken |
| B — Community safety, account lifecycle and media | Finish moderation/post cleanup; account deletion with shared website identity handled explicitly; public profiles; photo publication/retry acceptance; thumbnails, caching, saved collections, share links and image limits | Ownership/abuse tests, two-account device scenarios, deletion/retry tests and storage/transfer measurements pass; moderator operator assigned |
| C — Live marketplace and conversations | Map existing website sale/rental inventory; listing publication/photos/details; country/city/category search; correct prices/dates; seller enquiries; realtime messages/unread state and notifications | Real inventory round trips, two-account enquiries/conversations, consent/block isolation, date/currency checks and reconnect tests pass |
| D — Whole-app beta and public release | Test all pages and controls; slow/offline network and denied permissions; low-memory phones, accessibility, crash/security/cost checks; policies/support; signing/store preparation and final fidelity report | No critical defects; measured performance and budget approved; verified backup/recovery/monitoring; production signing and release-owner requirements complete |

## Current checkpoint

A source/UI acceptance is complete for 0.10.0: 47 functional tests, 8 inspected
preview renders, SQL/media checks and the APK build passed. Device/live acceptance
remains explicitly part of the full beta in D. Original light-mode logo restored using the same image geometry
and colours, changing only bright near-neutral lettering to black at rendering time.
Light gradient controls use black ink for readability. No layout redesign is part
of this fix. See UI_PHASE_A_0.10.md for the tested build and APK.
B implementation now includes deployed account deletion, profiles, saved posts and media efficiency; physical-device and operator acceptance remain open. C now includes live app inventory publication, enquiries, realtime and unread state; remaining marketplace features and website identity linking are tracked in MARKETPLACE_PHASE_C_0.12.md.
D has CI checks but is not a completed public beta.

## Whole-app test matrix

| Area | Required scenarios |
|---|---|
| Welcome/auth | Signup, duplicate/invalid input, email confirm, recovery, incorrect password, restart session, logout, expired session, callback errors |
| Home/community | Discover/Following, stories scope, paging, refresh, empty/offline feed, follows, likes, comments, save, share, post report/delete |
| Images/Create | Gallery permission denied/cancelled, valid JPEG, invalid/oversized media, draft save/restart/account isolation, interrupted publication and retry, quota errors |
| Profile/settings | Metadata save/failure, own/other identity, counts, tabs, avatar/cover scope, Light/Dark/System persistence, data-saver behaviour |
| Messaging | Follow/consent requests, accept/decline, both accounts, duplicate retry IDs, block/unblock, reconnect, unread state, privacy isolation |
| Marketplace | Buy/Rent, actual inventory, search/filter/reset, country/city, listing ownership, galleries, dates, currency, enquiries and unavailable offers |
| Moderation/deletion | Ordinary account denied tools, moderator review/cancel/audit, post removal, image cleanup retries, account scope and session revocation |
| Supporting pages | Drawer links, notifications, plan, blog/article, about/contact, saved content; no sample content mistaken for public inventory |
| Release | Small screen/large text, TalkBack, dark/light contrast, slow mobile network, memory/scroll/startup profiling, crashes, backups, signed installation/update |

For each scenario record expected result, actual result, build/device, evidence,
severity and fix/retest status. Automated checks are distinguished from device and
live-service checks. Deferred features must be clearly absent or explained, never
presented as working buttons. Payments, videos and AI chat remain outside initial
launch unless explicitly added to scope.

## Actual decisions needed before public release

Moderator account identity, verified website seller linking, selected launch
regions/languages, monthly hosting budget, public privacy/support details and
production store/signing ownership must be settled. Work that does not depend on
these proceeds normally; they are not grounds to pause UI and source work.
