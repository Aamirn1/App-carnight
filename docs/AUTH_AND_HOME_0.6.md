# Version 0.6.0 — account flow and Home feed

## Changes

- Added 24 px of space between auth introductions and the first field.
- Signup requires a searchable country selection and city. Country uses an ISO
  two-letter code. Both are stored in the Supabase user's account metadata and
  restored with the account; they are not copied into public social profiles.
- Marketplace defaults to the account country/city. Country selection, city
  search and Reset filters allow browsing elsewhere. The current inventory is
  still explicitly demo content; the website Listing bridge remains pending.
- A successful signup replaces the form with Check your email, Open Gmail,
  verification-code entry and an Already confirmed? Sign in action. Existing
  account responses remain intentionally non-enumerating.
- Sign-in and restored sessions open Home. The navigator is reset on identity
  changes so Back cannot reopen a logged-out account's private pages. A loading
  screen waits for local session restoration rather than briefly showing Welcome.
  Local session persistence is handled by the existing Supabase Flutter SDK.
- Sign-out returns to Welcome. Password recovery retains its separate flow.
- Welcome Sign in uses a gradient border with the existing dark interior.
- Home stories precede compact Discover/Following controls and the add-person
  action. The whole header scrolls with posts. Home posts use full-width media,
  uncropped photo fitting, caption expansion, a count row and labelled actions.
  Other post detail/profile/search layouts remain unchanged. Stories are still
  labelled sample stories, not live user stories. Share sends text through the
  Android share sheet; public post links remain a separate feature.

## Required Supabase configuration — cannot be set with the public anon key

The screenshot shows an actual redirect to localhost:3000. The app already sends
`com.carsnight.preview://auth-callback/` as emailRedirectTo, so check the hosted
allowlist and email template. A missing allowed redirect falls back to Site URL.
The APK cannot change your project's hosted Auth settings or SMTP sender identity.
No project admin connection or SMTP credentials are available in this session.

1. Open Authentication → URL Configuration in project
   `romhqgmsoabzowwvuvvp`.
2. Add exactly `com.carsnight.preview://auth-callback/` to **Redirect URLs**.
   Keep existing website redirects. Replace a localhost **Site URL** with the
   real production Cars Night website URL, preserving the website's auth route.
   Do not invent a domain or replace the shared website URL with an app-only URL.
3. Open Authentication → Email Templates → **Confirm signup**.
   Subject: `Confirm your Cars Night account`.
   Copy the complete [confirm_signup.html](../supabase/templates/confirm_signup.html)
   into the template body. Keep `{{ .ConfirmationURL }}` and `{{ .Token }}` intact.
   This template keeps both website and app confirmation links working, using
   the redirect requested by each client. Do not hardcode localhost or SiteURL
   as the confirmation button's link.
4. To replace the **Supabase sender name/address**, configure custom SMTP using
   a mailbox/domain you control and sender name **Cars Night**. The HTML template
   changes the message body, not its From address. Keep provider credentials in
   Supabase's SMTP settings only. Domain verification/SPF/DKIM depend on that provider.
5. Send a new test signup after saving. Old emails contain their original URLs;
   changing configuration does not rewrite them. Never disable email confirmation
   to work around a bad redirect.

Once allowed, the confirmation link should return to the installed Android app
and establish a verified session. Code verification also checks the real token
with Supabase, then opens the authenticated app; it does not display fabricated
success. If the email client blocks app links, use the code in the new template.
Test on the phone with Gmail, app closed and app already running. The code must
fail for a wrong/expired token. Gmail may open in the browser if its app is absent.

No live email was sent, SMTP sender changed, template applied, or hosted allowlist
edited by this code update. Those settings require project-admin access. Until
these steps are applied, the live localhost/email-branding issues remain blocked.

No additional SQL migration is needed for the country/city fields in this release.
They are account metadata, not an authorization boundary. Existing social/photo
SQL setup remains necessary for those features.

## Acceptance and remaining gates

Verified on 3 October 2026 with source `70b5dfd8b1fe9c7c41e87ac16aff3e955c793ef0`:

- [Successful Actions run](https://github.com/Aamirn1/App-carnight/actions/runs/37135401543).
- Dart analysis: **No issues found**.
- **34 Flutter tests passed**, including restored-session routing, sign-in navigation,
  signup confirmation/location and Marketplace reset/filter behavior.
- **4 media validator tests passed** and isolated PostgreSQL ownership, privacy,
  publication and quota checks passed.
- Android release-mode preview APK built successfully: **54.0 MB**, development signed.
- [Download version 0.6.0 APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/37135401543/artifacts/11278522898).
  Extract CarsNight-preview.apk. Available until 17 October 2026.
- Runner-formatted Dart and the resolved dependency lock are retained in the repo.

No physical-device screenshot, native Gmail launch, real email confirmation or live
photo upload was performed in this verification. The automated session tests use
repository fakes; they do not establish live email delivery. Hosted settings above
must be applied before the localhost issue can be considered resolved.


Check: returning-user launch; sign-in → Home; sign-out → Welcome; signup location
selection and validation; confirmation-only screen after successful submission;
Gmail launch; real confirmation link/code; repeated login/logout; large text and
narrow screens; scrolling past stories to a complete uncropped post and actions.
Marketplace with a location lacking demo offers should show no results, not silently
show cars from another country. Reset allows all countries.

The previous photo publishing migration and Edge Function deployment are still
required: [photo setup](PHOTO_SETUP.md). Complete the live auth/email acceptance
checks before calling this phase complete or advancing to a public release.

## Official references

- https://supabase.com/docs/guides/auth/redirect-urls
- https://supabase.com/docs/guides/auth/auth-email-templates
- https://supabase.com/docs/reference/dart/auth-verifyotp
