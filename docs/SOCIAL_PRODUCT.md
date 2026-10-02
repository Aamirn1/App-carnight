# Cars Night: a community for car lovers

## Product decision

Cars Night is a social app first. Marketplace is one useful destination inside it.
Preserve the approved night palette, neon accents, wordmark and photo-card style.
Navigation is Home / Messages / Create / Marketplace / Profile. Buy and Rent are
filters inside Marketplace, not separate top-level destinations.

Home uses Discover and Following chronological feeds. Find car lovers supports
following and requesting a conversation. A follow does not bypass the recipient's
consent. Messages separates Community, Marketplace and Requests. Marketplace
conversations are enquiries; they do not imply payment, booking or order acceptance.
The first release should focus on these few dependable flows, not imitate every
feature of mature social networks at once.

## Backend choice and budget

Recommendation: retain the existing Supabase project initially. PostgreSQL fits
follow relationships, unique likes, comments, ownership and conversations. Reusing
it avoids an immediate backend migration and duplicate operational services.
Firebase is viable but would introduce migration work and a different query and
billing model; there is no evidence that switching would fix this app's speed.

Official pricing checked 2 October 2026:
https://supabase.com/pricing
Free includes 500 MB database, 1 GB file storage, 5 GB egress and 5 GB cached egress.
Free projects may pause after a week of inactivity; automatic backups are not
included. Pro starts at US$25/month. These are plan allowances, not guaranteed app
capacity. Website and app compete for the same project's resources. No plan change
or purchase was made. Firebase bills Firestore for document/index reads and writes:
https://firebase.google.com/docs/firestore/pricing

Early cost priorities: no video, no chat attachments, bounded pages, chronological
feeds, small thumbnails, image byte/dimension limits and no background presence/
typing subscriptions. Plan media at a maximum four images per post, 1600px longest
edge and 512 KiB per approved image, with separate feed thumbnails. The server must
validate/re-encode and strip metadata; limits in a database alone do not implement
this pipeline. Storage/egress, not just database rows, will matter for photo feeds.
Use usage alerts and measured budgets before growing the public audience.

## Connection evidence

The supplied legacy anon key was accepted for `/auth/v1/settings` (HTTP 200).
Email auth is enabled and email confirmation is required. No test account or email
was created. `cn_posts` and `cn_listings` returned PGRST205 (missing table).
The existing website `Listing` endpoint returned HTTP 200 and zero anon-visible
rows. This does not establish whether the table is empty or protected by RLS.
Schema enumeration requires privileged access and was not available with this key.
No privileged key was requested or embedded.

Therefore the website's column definitions, seller identity mapping, auth system,
RLS policies, region and resource usage remain unverified. Do not assume that its
users are Supabase Auth users; a Next.js site may use a separate login system.
Keep one canonical marketplace inventory once that mapping is inspected. Do not
silently duplicate or migrate the website's Listing data into the mobile draft
schema. A schema-only export/DDL of Listing and its seller/user relation is needed
for that bridge, without real customer rows.

## Implemented in 0.4.0

- Supplied public client key included in the APK build configuration, with override
  support through GitHub variables. Public anon keys are intended for clients; RLS
  remains the authorization boundary.
- Community-first navigation and combined Buy/Rent screen.
- Connected feed adapter with cursor pages of 20, follow/like/comment operations,
  people search and bounded media rendering. Share currently copies a post reference;
  working public share links and Android share-sheet integration remain future work.
- Inbox/request/thread screens, accept/decline, text messages with retry IDs,
  block/unblock and report submission. Threads refresh manually; realtime delivery,
  push, unread counters and read receipts are not implemented yet.
- Additive SQL schema/RLS/RPCs for interactions, messages, requests, approved media
  metadata and reports. Publication and approved-media writes remain privileged.
- SQL authorization tests cover third-party access, sender impersonation boundaries,
  consent, blocked messaging, draft visibility and idempotent message retry.

## Deployment boundary

No new tables have been created in the live project: an anon key cannot run DDL.
Run `supabase/SETUP_SOCIAL.sql` once from SQL Editor after review/backup. It is a
single transaction and touches only cn_* objects. Existing Listing is unchanged.
If cn_* objects already exist, do not rerun blindly; reconcile migration history.
Keep the website Site URL; add `com.carsnight.preview://auth-callback/` as an additional
allowed redirect. No service-role key belongs in Flutter or a public repository.

## Remaining release gates

1. Apply SQL and test two real accounts, consent, sign-out, blocking and restoration.
2. Build and deploy validated image upload/storage, quotas and a publish operation;
   Create currently saves private text drafts only, not public photo posts.
3. Inspect website schema and seller identities; connect existing sale/rent inventory
   and enquiries without inventing order/booking states.
4. Add realtime delivery only to active conversations; private notification payloads,
   unread counters, read receipts and push delivery, with usage monitoring.
5. Add moderation tools, report triage, stronger abuse/rate controls, account deletion,
   data export, production signing, privacy disclosures and email delivery checks.
6. Profile older Android hardware and poor networks, test large text and accessibility,
   and compare actual screenshots across all pages. No global speed/device guarantee
   or production-readiness claim is made by a successful build.
