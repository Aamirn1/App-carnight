# Install and test Cars Night

1. Open the repository's Actions tab and the successful **Build Android test APK** run.
2. Under Artifacts, download **CarsNight-test-APK** (GitHub sign-in may be required).
3. Extract the ZIP on your Android phone or computer.
4. Open **CarsNight-preview.apk**. Allow installation from the app opening the APK
   if Android asks, then install it.

This is a release-mode build signed with the generated development key, intended
only for testing. It is not Play Store signed. The application ID is
`com.carsnight.preview.cars_night`. A later CI build may have a different development
key; if Android refuses an update, uninstall this preview before installing it.
Uninstalling or exiting the demo loses all local session data.

## What to check

- Welcome artwork, logo, Get Started and back navigation.
- Home scrolling, story images, likes, saves and demo comments.
- Create a demo post using the bundled sample images.
- Buy search/category filters and Reset filters after an empty result.
- Rent city/date controls, listing details and the sample estimate.
- Profile → Saved collection; remove a saved item.
- Drawer pages and larger system font sizes.

Account services, uploads, bookings, payments and seller enquiries are not connected.
All sample posts and changes are in memory and reset when the demo is exited.
Generated photos are illustrative, not actual seller inventory.

Report the phone model, Android version, screen name, reproduction steps and a
screenshot for each issue. Build success does not certify device performance or
visual fidelity to the reference.

## Rebuild

Go to **Actions → Build Android test APK → Run workflow → main**.
Pushes to main also trigger a build. Artifacts expire after 14 days.
The workflow needs no personal access token secret. It uses Flutter 3.35.7,
Java 17 and read-only repository permissions.
