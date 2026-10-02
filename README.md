# Cars Night — Flutter community app

**Version 0.4.0 — development preview.** Cars Night is a social app for car lovers,
with a marketplace as one destination. The approved dark/neon visual style remains.

Navigation: **Home / Messages / Create / Marketplace / Profile**.

## Implemented in this increment

- Discover and Following feed screens with cursor pagination and bounded image decoding.
- People search, follow/unfollow, likes and comments backed by Supabase adapters.
- Community/Marketplace/Requests inboxes, recipient acceptance, text messages with
  idempotent retry IDs, block/unblock and report submission.
- Combined Buy/Rent marketplace screen. Website inventory mapping is still pending;
  the marketplace currently shows explicitly labelled sample offers.
- Public Supabase client configuration included in the APK build. Auth settings and
  the existing website Listing endpoint were reachable in the initial API check.
- Additive social tables, RLS, request/message RPCs and basic write limits, with
  isolated PostgreSQL privacy/ownership tests.

These database-backed features require the prepared SQL to be installed. No live
DDL was executed with the anon key. A successful build is not a live account,
email, message-delivery or media-upload acceptance test.

## Activate your Supabase project

Follow [setup instructions](docs/SUPABASE_SETUP.md). The full first-install script is
[supabase/SETUP_SOCIAL.sql](supabase/SETUP_SOCIAL.sql). It creates only cn_* objects
and does not change the website's Listing table. If the 0.3.0 mobile schema already
exists, apply only the new social migration after reviewing migration history.
Never run the disposable SQL files in `supabase/tests` on your live project.

Add `com.carsnight.preview://auth-callback/` to allowed auth redirects while keeping
the website Site URL and redirects. Verify email delivery with dedicated accounts.
The supplied anon key is a public client credential; never embed a service-role key.

## Test APK and source

[Download version 0.4.0 APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/37035835530/artifacts/11241001708).
Verified: 29 Flutter tests, clean analysis, database privacy/ownership checks and
a successful 52.9 MB Android build. Available until 16 October 2026.

For later builds, open [GitHub Actions](https://github.com/Aamirn1/App-carnight/actions/workflows/android-apk.yml),
select the latest successful run, and download **CarsNight-test-APK**. Extract
**CarsNight-preview.apk** and install it on Android. GitHub sign-in may be required.
See [verification status](docs/STATUS.md) and [installation notes](docs/ANDROID_TESTING.md).

The preview is development signed. If Android refuses to update an older APK,
uninstall that preview first; local demo data and the stored session are removed.
Server-side data, once configured, persists.

## Local development

Flutter 3.35.7 and Java 17 are used by CI. The dependency lock and Android host are
committed. The editing environment has no Flutter SDK; actual Flutter verification
runs on GitHub Actions.

```sh
bash scripts/bootstrap_android.sh
flutter pub get
dart format lib test
bash scripts/check.sh
flutter run --dart-define-from-file=config/supabase.public.json
```

GitHub repository variables can override the public configuration. The workflow
rejects privileged keys before packaging. Test fixtures never use the live project.

## Remaining release work

Create currently saves **private text drafts**, not public photo posts. Validated
image upload/re-encoding/storage, publication, realtime/push messaging, unread
counts, public share links, connected saved collections, website inventory bridging,
moderation tools, account deletion and production signing remain unfinished.
Threads refresh manually. No videos or chat attachments are supported.

Home was previously reviewed on one physical phone. The new pages still need actual
device screenshot comparison, performance checks and live two-account tests after
SQL installation. No claim of production readiness or worldwide speed/device
coverage is made by a successful CI build.

Read [product and budget decisions](docs/SOCIAL_PRODUCT.md) and the
[current milestone](docs/NEXT_MILESTONE.md) for rationale and remaining phases.
