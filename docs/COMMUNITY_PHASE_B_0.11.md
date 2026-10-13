# Community and media checkpoint — 0.11.0+13

Tested source: `4cb6165a7543930a9b3d980743ac61839af87003`.
[Successful build and APK](https://github.com/Aamirn1/App-carnight/actions/runs/38379619493).
[APK artifact](https://github.com/Aamirn1/App-carnight/actions/runs/38379619493/artifacts/11802408879).

## Implemented and deployed

- Member profiles: optional public bio, city and dream car; actual follower/following/post counts, follow, message request and paginated posts.
- Online saved posts with owner isolation; full photo viewer and native photo-link sharing.
- New uploads generate a thumbnail up to 480px/64KiB and detail JPEG up to 448KiB; combined cap remains 512KiB. Legacy posts fall back to their original photo.
- Device image cache: seven-day stale period, target maximum 100 objects (eventual eviction, not a byte ceiling).
- Password-confirmed app-account deletion: validates live session, limits attempts, verifies current password and revokes sessions before deleting. Related app rows cascade; photos enter durable cleanup queue. Confirmed device cleanup is retried from a local journal.
- Upload processing limited to ten attempts/minute. Budget ledger survives account deletion. Current pilot limits remain 200 total reservations, 20/account, five/day. Abandoned reservations expire after seven days; cleanup runs every five minutes.

Live deployment on 13 October 2026: `cn_community_media` and `cn_expired_upload_schedule`; `cn-publish-photo` v2; `cn-delete-account` v1. Both functions require JWT authentication. Live metadata confirms the cleanup schedule is active.

## Identity and privacy

The website uses its own User/password model. Sharing a Supabase project does not establish shared login. App deletion leaves website accounts, listings and transactions untouched. Signup city remains private; editing the explicitly public profile saves a separate city field. Public member avatars currently use initials. Public photos may remain in external caches/downloads after deletion. Budget ledger retains pseudonymous owner/request IDs for quota integrity.

## Verification

- 52 functional Flutter tests passed; static analysis clean.
- 12 backend/media tests passed, including password/session/rate-limit rejection, revoke-before-delete, thumbnail dimensions and combined size.
- Database ownership and abuse checks passed in a disposable database: saved isolation, block filtering, private/public city separation, account cascades, website fixture preservation, durable cleanup and quota retention.
- 12 light/dark preview renders inspected: brand, profile, Buy, Rent, member profile and account deletion. Original script lettering and Night gradient preserved; Cars becomes black in light mode.
- Android APK built successfully (56.1MB). These checks do not establish physical-device or authenticated live-user acceptance.

## Remaining acceptance gates

Phase B implementation is delivered; acceptance remains open for two-account phone tests, live upload/interruption/retry, disposable-account deletion, measured transfer/storage and appointment of a moderator operator. Do not delete a real account merely to test this build.

Sharing currently provides a public photo URL with caption, not a hosted discussion page. Direct avatar upload, account suspension/appeals and multi-photo publication remain outside this checkpoint. Device cleanup is best-effort across server/device failures, not an atomic cross-system purge.

Phase C covers real marketplace inventory and ownership mapping, listing publication/enquiries and realtime conversations. Phase D covers all-feature device/network/accessibility/security/performance testing and public release requirements.

## Security advisor review

Service-only quota/cleanup/rate tables intentionally have RLS and no client policies. Exposed definer RPCs implement the intended feed/ownership/block/role checks and are covered by database tests. Existing website `update_updated_at` search-path warning and disabled leaked-password protection remain release review items; no blanket website permissions were changed.

[Search-path remediation](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable)
[Password protection guidance](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
