# Cars Night — Flutter mobile app

**Version 0.3.0 — connected-services development preview.**

The approved dark/neon Home design and cyan selected navigation icons are retained.
The feed, marketplace, image composer, likes, comments and saved collection still
use sample content. No videos are supported.

## Supabase integration

Flutter account and private text-draft flows are implemented: email signup,
sign-in, session tracking, password recovery, sign-out and create/edit/delete for
post, sale and rental drafts. Live verification is pending: the supplied project
configuration contained `your-anon-key`, and the database migration has not been
applied to the shared project.

Follow [Supabase setup](docs/SUPABASE_SETUP.md) to provide the **public** key,
apply the isolated `cn_*` schema and configure the mobile callback. This is a
Flutter integration, not a Next.js/npm setup. The workflow refuses to embed a
privileged key. With no public key configured, account submission is disabled.

The website's auth project is shared; its content is not automatically imported.
The new migration does not alter existing website tables or auth triggers.

## Test APK

Open [GitHub Actions](https://github.com/Aamirn1/App-carnight/actions/workflows/android-apk.yml),
select the latest successful run, and download **CarsNight-test-APK** under Artifacts.
Extract **CarsNight-preview.apk** and install it on Android. GitHub sign-in may be
required. See [installation instructions](docs/ANDROID_TESTING.md).

The development signing key may change between builds. If Android refuses an
update, uninstall the old preview before installing; local sample data and the
stored sign-in session are lost. Server drafts, once connected, are unaffected.

The workflow runs isolated PostgreSQL ownership checks, Flutter analysis, unit/
widget/mocked-HTTP tests and an Android release-mode build. This does not certify
live Supabase auth/email, actual device callback handling, production performance
or worldwide device support. See [verification status](docs/STATUS.md).

## Local development

Use Flutter **3.35.7** and Java 17. The Android host and dependency lock are committed.

```sh
bash scripts/bootstrap_android.sh
flutter pub get
dart format lib test
bash scripts/check.sh
flutter run
```

For connected builds, follow the dart-define configuration in the setup guide.
No service-role credentials belong in the app. There is no local Flutter SDK in
the editing workspace; actual Flutter checks run in GitHub Actions.

## Test flows

1. Get Started → Home; scroll and test local comments/likes.
2. Create → select bundled sample images → add a local demo post.
3. Buy/Rent → filter, inspect a sample listing and save it.
4. Profile → Saved collection; remove local saved items.
5. Once configured: Profile → Sign in or join → account and private drafts.
6. Create/edit/delete post, sale and rental drafts; test sign-out and restoration.
7. Follow the live acceptance checks in the Supabase setup guide.

## Remaining work

Image picking/compression and validated uploads, quotas, public feed/listings,
server moderation, connected saves/reactions, account deletion, reporting,
release signing, privacy/store requirements and broad device testing remain.
Public publishing is intentionally blocked until server validation exists.
This is not a production launch build.

Bundled photos are illustrative and the logo is an interpreted asset. Home was
reviewed by the user on one device; exact original-reference matching across all
pages and devices has not been verified. See [milestone](docs/NEXT_MILESTONE.md)
and [roadmap](docs/ROADMAP.md).
