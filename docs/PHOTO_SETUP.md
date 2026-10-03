# Phase 3: one-photo publishing pilot (0.5.0)

## Verification

Tested source: `d051342c203e86c63132278e667e5dfe481eca80`.
[Successful Actions run](https://github.com/Aamirn1/App-carnight/actions/runs/37126623765).
30 Flutter tests, 4 Deno media validation tests, TypeScript checking and the
PostgreSQL social/ownership/photo quota checks passed. Flutter analysis had no
errors or warnings; one unnecessary-import informational note was removed in the
final source cleanup. Runner formatting and the resolved Dart dependency lock are preserved.
The Deno imports pin their direct package versions; no Deno lock was produced.
[Download development APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/37126623765/artifacts/11274887422) — 53.6 MB, available until 17 October 2026.
No live Supabase deployment or physical-device gallery/upload test was performed.

## Welcome-screen fix

The welcome image is anchored to the top rather than vertically centered. The
background can draw behind a transparent status bar, while lower controls retain
bottom safe-area protection. Existing logo, car image and gradients are retained.
A regression test checks the top edge with an explicit status-bar inset.

## What is implemented

Signed-in Create opens a device gallery picker, JPEG preview and caption editor.
The picker requests a 1440-pixel bound and reduced quality. Before publishing, the
client caps its input at 2 MiB. Video and other formats are rejected in this pilot.
The server validates the authenticated, confirmed account itself; user identity
is never taken from request JSON. JPEG dimensions are checked before decompression,
then pixels are re-encoded into a fresh JPEG to discard original metadata. Stored
files are at most 512 KiB and 1600 pixels per side. No originals are stored.

A server-only reservation and atomic finalization insert one published post and
its media row. The feed reloads after successful publishing. Retrying the same
request returns the same post, and conflicting content is refused. A failed upload
keeps the photo/caption on the open composer page; it is not a durable local draft.
On Android, return to Create to recover a gallery result after process recreation;
captions may need re-entering. Publication retries across app restarts are not yet
persisted; check your feed before creating a replacement post after restarting.

## Activation: SQL AND Edge Function deployment required

1. If the earlier mobile/social tables are not installed, first run
   [SETUP_SOCIAL.sql](../supabase/SETUP_SOCIAL.sql) as described in
   [Supabase setup](SUPABASE_SETUP.md). Do not rerun it on an existing installation.
2. Then run only
   [202610030001_photo_publish.sql](../supabase/migrations/202610030001_photo_publish.sql)
   in Supabase SQL Editor. It adds the photo reservation table, protected functions
   and the cn-media storage bucket. No website Listing table is modified.
3. Deploy the included function using the Supabase CLI from this repository:

   ```sh
   supabase login
   supabase link --project-ref romhqgmsoabzowwvuvvp
   supabase functions deploy cn-publish-photo --project-ref romhqgmsoabzowwvuvvp
   ```

   Keep JWT verification enabled. The function also calls Auth getUser to validate
   the token. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are Supabase-hosted function
   environment values; never put an administrative key into Flutter or public files.
   SQL alone does not deploy a function. This update does not claim live deployment.
4. With a dedicated confirmed account, choose a JPEG, publish, then verify it in
   Discover from another account. Retry a failed request on the same composer;
   check one post appears. Test oversized, corrupt and non-image inputs, plus quotas.

## Deliberately small pilot budgets

- Five new reservations per user per rolling 24 hours.
- Twenty reservations per user total (at most 10 MiB).
- Two hundred reservations across the app (at most 100 MiB).
- One photo per post. No videos or chat attachments.

Limits are enforced under a database lock and include unfinished requests and
deleted posts, so failures cannot create unlimited storage orphans. This is a
small pilot ceiling, not a monthly reset or a complete cost-control system.
Egress, Auth/email, function CPU and other website usage still consume shared
project resources. Increase limits only after reviewing actual usage.

If a request fails after uploading but before DB finalization, retrying the same
request reconciles the object; the reservation remains charged. Cleanup needs
an operator reconciliation process using Storage API deletion (not SQL deletes
of storage.objects). Do not release reservations until their objects are removed.

## Release boundaries

cn-media contains public post photos: anyone holding a URL can view them. Blocking
filters app interactions, not already public URLs. Publication does not include
automated content moderation. Reports exist, but an operational moderation queue,
image takedown/delete lifecycle, account deletion, durable offline drafts,
multiple-photo posts and realtime/push messaging remain release work. No live
upload, camera/gallery interaction, device rendering or performance claim follows
from CI alone. This is a controlled testing build, not an unrestricted public launch.

## Sources used for implementation

- Flutter-maintained image_picker: https://pub.dev/packages/image_picker/versions/1.2.1
- Supabase function auth: https://supabase.com/docs/guides/functions/auth
- Supabase Storage access control: https://supabase.com/docs/guides/storage/security/access-control
- ImageScript API: https://github.com/matmen/ImageScript
