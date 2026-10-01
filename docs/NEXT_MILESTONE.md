# Phase 2: connected services — in progress

The approved Home design and cyan selected navigation icons are preserved.
Version 0.3.0 adds a Flutter Supabase adapter for the user-provided project URL,
account forms, session tracking, password recovery callback handling and private
text draft screens for posts, sale listings and rental listings.

The app is not connected to the live project yet: the supplied key is still
`your-anon-key`, and no administrative database connection is available. See
[SUPABASE_SETUP.md](SUPABASE_SETUP.md) for exact configuration and SQL instructions.
The new `cn_*` migration isolates mobile tables from the existing website. The
older migration is retained as historical groundwork, not for shared-project use.

The account/draft features have code and automated tests, but require live project
and device acceptance tests. Existing Home, Buy/Rent, local composer and saved
collection remain demo features. No videos or media uploads are enabled.

Remaining milestones: connect and validate live auth/drafts; image compression,
validated storage and quotas; public feed/listing integration and private saves;
reports/moderation and account deletion; device/performance/accessibility coverage;
release signing, privacy/store disclosures, monitoring and launch review.
