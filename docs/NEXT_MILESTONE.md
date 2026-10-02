# Phase 2: social community — in progress

Version 0.4.0 makes the community the primary app experience. Home has Discover
and Following, Messages has request consent, and Marketplace combines Buy/Rent.
The approved palette, wordmark, cards and cyan selected icons are retained.

The public Supabase key has been supplied and verified against Auth and the
website Listing endpoint. The mobile/social tables still need installing with
[supabase/SETUP_SOCIAL.sql](../supabase/SETUP_SOCIAL.sql). No administrative
connection is available; no live database changes have been made.

Read [SOCIAL_PRODUCT.md](SOCIAL_PRODUCT.md) for implemented flows, budget rationale,
new table/RPC design, limits and remaining release gates. Read
[SUPABASE_SETUP.md](SUPABASE_SETUP.md) for the exact activation steps.

CI will validate ownership, conversation consent and privacy, Flutter behavior and
the Android build. Live two-account/device tests remain necessary after SQL setup.
Public photo uploads, realtime delivery, website inventory mapping and production
moderation/account-deletion tools are still unfinished. This is a development APK.
