# Cars Night — Flutter community app

**Version 0.8.0 — redesigned Profile, light mode and compact Marketplace.** Cars Night is a social app for car lovers,
with a marketplace as one destination. The approved dark/neon visual style remains.

Navigation: **Home / Messages / Create / Market / Profile**. Market opens Marketplace (Buy/Rent).

[Photo phase setup and limits](docs/PHOTO_SETUP.md).
The welcome image now starts at the top, including behind the status bar.

## Implemented in this increment

- Cover/overlapping avatar, profile details, Posts/Photos/About tabs and account actions.
- Settings: persistent Light, Dark and System appearance with theme-aware surfaces.
- Buy and Rent search directly under the subtitle, then a single scrollable filter row.

[Profile/theme reference analysis and verification](docs/PROFILE_THEME_0.8.md).


- User-supplied gradient C launcher icon, with Android adaptive/density variants.
- Save, restore and discard an account-scoped photo draft on the device.
- Persist the exact publication request before sending; retry after restart without changing its ID.

[Icon and draft milestone report](docs/ICON_AND_DRAFTS_0.7.md).


- Persistent session routing: signed-in users open Home; signed-out users see Welcome.
- Country/city signup fields with location defaults for Marketplace browsing.
- Dedicated email confirmation screen, Open Gmail and verified-code fallback.
- Home-only post structure, full uncropped media, stories above refined feed tabs.
- Branded confirmation email template and exact hosted Auth configuration guide.

[Account/email setup and verification report](docs/AUTH_AND_HOME_0.6.md).
Branded email templates and the mobile callback are configured in Supabase with
the existing Resend SMTP. See [live setup status](docs/RESEND_EMAIL_SETUP.md).
Fresh email delivery and physical-device callback checks remain open.


- One-photo JPEG composer, caption/preview, bounded upload and duplicate-safe
  publication through a protected Edge Function. **Deploy the function and apply
  the photo migration before live use.** See [photo setup](docs/PHOTO_SETUP.md).

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

The exact app callback is now allowed; the website Site URL is preserved.
Verify fresh email delivery and phone callbacks with dedicated test accounts.
The supplied anon key is a public client credential; never embed a service-role key.

## Test APK and source

[Download version 0.8.0 APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/37234218245/artifacts/11315306646).
Verified: 43 functional Flutter tests, 6 rendered previews, 4 media tests, isolated
SQL checks, clean analysis and a successful 54.8 MB APK.
[Reference analysis and full report](docs/PROFILE_THEME_0.8.md).

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

Signed-in Create now supports one public JPEG photo per post after server setup.
Photos are re-encoded on the server and limited to 512 KiB. The pilot reserves at
most 100 MiB across 200 uploads, with 5 new reservations per user per 24 hours and
20 per user overall. This limits stored media, not total project cost.

Live deployment and device gallery/upload acceptance tests remain pending.
Realtime/push messaging, unread counts, public share links, connected saved
collections, website inventory bridging, moderation/takedown tools, account
deletion, multi-photo posts and production signing remain unfinished.
Threads refresh manually. No videos or chat attachments are supported.

Home was previously reviewed on one physical phone. The new pages still need actual
device screenshot comparison, performance checks and live two-account tests after
SQL installation. No claim of production readiness or worldwide speed/device
coverage is made by a successful CI build.

Read [product and budget decisions](docs/SOCIAL_PRODUCT.md) and the
[current milestone](docs/NEXT_MILESTONE.md) for rationale and remaining phases.
