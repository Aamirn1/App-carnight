# Phase A control and launch audit

Reviewed source as part of 0.10.0. This is an implementation inventory, not proof
of end-to-end live functionality. Every row is covered by the Phase D test matrix.

| Screen/control | Current implementation | Remaining launch work |
|---|---|---|
| Welcome / Get Started / Sign in | Navigation to account forms; sample access | Device first-run/callback review |
| Signup / country / city / email confirmation | Supabase account creation and metadata; email notice and mail opening | Fresh email delivery and callback acceptance |
| Sign-in / restart / logout | Supabase session-driven Home navigation | Real-device expiry/offline/restart scenarios |
| Forgot/reset password | Email recovery and password update flow | Real email/deep-link acceptance |
| Home Discover / Following / People | Online feed, paging, following and people search | Real users, pagination/network profiling |
| Stories | Bundled sample photo stories | Real stories deferred; retain clear sample scope |
| Like / comments / delete comment | Supabase writes with ownership/rate controls | Two-account live acceptance |
| Own-post delete | Confirmed database delete and scheduled media cleanup | Real photo removal and cache behaviour on phone |
| Save collections | Demo saved collections; backend schema exists | Complete online saved collections |
| Share | Native share/copy of post text | Public post links |
| Report / block / unblock | User reports/blocks plus post reports | Operator staffing and live abuse scenarios |
| Create / gallery / caption / publish | One compressed JPEG, server validation, quota and durable retry ID | Valid/invalid gallery and interrupted upload phone scenarios |
| Save/discard photo draft | Explicit account-scoped local persistence | Reinstall/sign-out/device permission scenarios |
| Messages / requests / accept / decline / send | Consent-based text threads and retry IDs | Realtime, unread status, notification delivery and reconnect |
| Profile / edit / Posts / Photos / About | Own profile and metadata editing; paged posts | Public profiles and broader sharing |
| Avatar / cover | Bundled artwork or already-published photo selection | Direct profile uploads, public metadata scope |
| Marketplace Buy / Rent / search / filters / dates | Sample inventory, details and local save; independent draft schema | Website inventory bridge and real enquiries/publication |
| Listing form / preview | Private text drafts; sample preview | Photos, pricing/date rules and live publication |
| Appearance Light / Dark / System | Persistent choice; original image wordmark in both modes | Physical-device large-text/contrast review |
| Lower-detail images | Changes decode size, not downloaded bytes | Actual feed thumbnails and bounded disk cache |
| Privacy / Delete account | Accurate testing-build notices | Public policy/support and full account deletion |
| Moderator queue / dismiss / remove | Role-checked review with images and private audit note | Verified operator assignment and live acceptance |
| Notifications | Explicit empty preview | Real delivery and preferences |
| Plan | Explanation/sample page, no purchase | Defer paid plans until entitlements/payments specified |
| Blog / article / About / Contact | Supporting/sample content; contact actions explained | Genuine approved content and support endpoint |

No global compatibility, measured speed, production signing, completed full-app
beta or successful real-user upload is claimed from this audit. Phase A corrected
misleading legacy Settings copy that said no backend/account existed despite the
connected implementation. Theme changes preserve layouts and source artwork.
