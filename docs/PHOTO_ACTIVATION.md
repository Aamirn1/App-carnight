# Photo pilot activation — 4 October 2026 UTC

## Deployed

- Applied existing photo publishing migration to project romhqgmsoabzowwvuvvp.
- Deployed cn-publish-photo version 1 with gateway JWT verification enabled.
- Corrected an over-escaped image-path constraint found in the hosted schema;
  the new migration uses `[.]` so valid JPEG/WebP paths are accepted unambiguously.
- Created cn-media bucket for intentionally public, sanitized JPEG photos.
- Website tables were not changed. Restrictive Storage policies only constrain
  client mutations to cn-media.

## Verified live

- Function is ACTIVE; missing Authorization returns HTTP 401.
- Photo reservations have RLS; clients cannot read them or execute reservation
  and publication functions. Service role can finalize uploads.
- Three restrictive policies deny direct client image insert/update/delete.
- Bucket allows JPEG only and limits each stored image to 524288 bytes.
- Corrected path constraint is installed; existing paths were compatible.

No test user was created, no email was sent, and no user content was published.
A confirmed-user upload, image processing within hosted runtime limits, and
phone retries still require end-to-end acceptance. Source tests previously passed;
this report does not claim a successful live photo publication.

## Test using the existing 0.8 APK

Sign in with a confirmed account, choose Create, select one gallery photo, enter
its caption, and Publish. Check it appears in Home and Profile. If the response
is interrupted, retry the same saved draft; its request ID prevents duplicates.

Pilot limits remain 5 reservations per account per 24 hours, 20 lifetime per
account, 200 across the app. Failed reservations remain charged. This caps stored
image payload at roughly 100 MiB, excluding platform overhead. Public image URLs
can be viewed by anyone with the URL, even if an account is blocked.

Next development gate: moderation and reliable image/account deletion before
expanding storage limits or opening unrestricted registration.
