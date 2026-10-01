# Cars Night — Phase 2 visual prototype source

**Version 0.2.0. Source authored; not compiled, executed or visually verified.**

This continues the Flutter foundation. It is not a production application or a
running preview. No backend, real authentication, public posts, seller messaging,
bookings or payments are connected.

## Added in this milestone

- Reference-inspired welcome with bundled neon artwork and script wordmark.
- Refined photo feed, sample photo stories, search, local comments and likes/saves.
- Buy cards, compact Rent cards, city/category filters and empty-state reset.
- Rental date picker and a calendar-day sample estimate in listing details.
- Image-only demo composer; local posts can be deleted from the post menu.
- Saved collection, guest profile and lazily constructed main tabs.
- Sign-in, signup, recovery, listing-form preview, settings, notifications,
  plan, blog/article, about and contact layouts.
- Five bundled assets totaling 556,369 bytes. Four compressed WebP images and
  one transparent PNG wordmark. No external image or font requests.
- Seventeen authored tests in total. **Not executed.**

Images and car offers are illustrative. The logo is an AI-generated interpretation,
not the original artwork. No exact reference match has been verified.

## Run in a Flutter-equipped environment

Install a current stable Flutter SDK from https://docs.flutter.dev/install and
Android tooling. iOS requires macOS/Xcode. Pin the actual installed SDK version
before team development and commit its generated pubspec.lock.

From this directory:

```sh
bash scripts/bootstrap.sh
flutter doctor -v
flutter pub get
dart format lib test
bash scripts/check.sh
flutter run
```

Bootstrap generates Android/iOS hosts in a temporary folder and copies them
without replacing lib/test. It refuses to overwrite existing native directories.
The com.example application identity is development-only. Native SDK minimums,
signing, store identities and final platform configuration remain release work.

check.sh requires an installed SDK, checks formatting, runs the analyzer and
executes tests. On the current workspace it exits 2 with:

```
BLOCKED: Flutter SDK is not installed.
```

## Review flows

1. Get Started → Home → open a sample story; like/save a post; add a demo comment.
2. Create → enter caption → choose 1–4 sample images → Add to demo feed.
3. Buy → search → empty results → Reset filters → open a listing → save it.
4. Rent → change city → select dates → open a car → inspect sample estimate.
5. Profile → Saved collection → remove items and check the empty state.
6. Drawer → Settings → lower-detail image switch; explore supporting pages.
7. Exit demo → Get Started; verify all session changes have reset.

The composer uses bundled samples, not a device photo picker. Sign-in/contact
forms explicitly report that services are unavailable; they do not claim success.
Listing forms preview details but do not publish or persist. Rental dates never
claim inventory availability. The image-detail preference affects decode size,
not network transfer; all current imagery is local.

## Next gate

Run formatter/analyzer/tests on a real SDK, fix findings, then capture actual
Flutter screens at 320/360/390/430 logical-pixel widths with large-text variants.
Review against reference/cars-night-reference.jpeg. Only then approve Phase 2
and begin connected-service integration. Read docs/STATUS.md for evidence and
known gaps, and docs/ROADMAP.md for the remaining phases.
