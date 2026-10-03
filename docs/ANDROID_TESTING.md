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

## Account and Home checks for 0.6.0

- Cold launch after sign-in goes to Home; sign-out returns to Welcome and clears private routes.
- Signup requires a country and city. Submission opens Check your email and hides the form.
- Open Gmail works, with browser fallback when Gmail is not installed.
- After [hosted Auth setup](AUTH_AND_HOME_0.6.md), verify a fresh link/code; reject a wrong/expired code.
- Stories scroll above the compact Discover/Following/add-person controls.
- Scroll through complete photos and their separate count/action rows; review large text.
- Marketplace defaults to the signup location; Reset filters restores all locations.

## What to check

After installing the social SQL and configuring auth redirects:

- Register/confirm/sign in using dedicated test accounts; test password recovery.
- Open Find car lovers, follow the second account, and request a conversation.
- Verify messages cannot be sent until the recipient accepts.
- Refresh the thread after sending; realtime/push delivery is not implemented yet.
- Retry a failed send, block/unblock, report, and sign out; private history must hide.
- After [photo setup](PHOTO_SETUP.md), open Create, choose a JPEG and add a caption.
- Publish and check Discover from a second account. Retry on the same composer
  after a network failure; verify there is only one post.
- Try a corrupt/oversized/non-JPEG image; verify rejection without publication.
- Check the welcome image starts at the top with no black spacer above it.
- Review button access with large text and the device keyboard open.

Sample-mode review:

- Welcome artwork, logo, Get Started and back navigation.
- Home scrolling, story images, likes, saves and demo comments.
- Create a demo post using the bundled sample images.
- Marketplace → Buy search/category filters and Reset filters after an empty result.
- Marketplace → Rent city/date controls, listing details and the sample estimate.
- Profile → Saved collection; remove a saved item.
- Drawer pages and larger system font sizes.

Account and private text-draft screens require a configured public key and server
schema; see [Supabase setup](SUPABASE_SETUP.md). This build has not been verified
against the live project. Photo uploads/publication require the new migration and function deployment.
Bookings, payments and live seller inventory integration remain unavailable.
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
