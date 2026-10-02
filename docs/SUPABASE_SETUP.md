# Current setup: social-first version 0.4.0

The supplied public anon key is now in `config/supabase.public.json` and used by
GitHub Actions unless overridden by repository variables. This is intentionally
public client configuration, not an administrative credential.

Connection checks succeeded for Auth and the existing Listing endpoint. The
mobile tables are missing. Review and run [`../supabase/SETUP_SOCIAL.sql`](../supabase/SETUP_SOCIAL.sql)
in the project SQL Editor once. It installs the mobile + social schema in a single
transaction without changing the website Listing table. Add the auth redirect
`com.carsnight.preview://auth-callback/` while retaining the website's existing URL.

Read [SOCIAL_PRODUCT.md](SOCIAL_PRODUCT.md) for exact implemented/unfinished flows,
architecture, privacy rules, budget rationale and live verification requirements.
Local builds can use `--dart-define-from-file=config/supabase.public.json`.

---

## Historical 0.3.0 setup notes (superseded where different)

# Flutter + existing Supabase project

Target: https://romhqgmsoabzowwvuvvp.supabase.co

The supplied Next.js example contains a placeholder key, not usable credentials.
Flutter uses `supabase_flutter`, not npm, Next.js middleware or cookie helpers.
The SDK owns session persistence and token refresh. No backend configuration was
applied remotely in this increment. No real account, email or draft was tested.

## Complete the connection

1. In the project's Connect panel/API settings, copy the **publishable key**
   (`sb_publishable_...`) or legacy **anon** key. Never use a secret/service-role key.
2. In GitHub repository Settings > Secrets and variables > Actions > Variables,
   set `SUPABASE_PUBLISHABLE_KEY`. Optionally set `SUPABASE_URL`; the provided
   project URL is already the build default. The public key is embedded in the
   APK by design; database policies, not key secrecy, protect users' data.
3. Inspect the existing project's schema and back it up before applying new SQL.
   Review and run ONLY `supabase/migrations/202610020001_mobile_content.sql` in
   Supabase SQL Editor. It creates `cn_profiles`, `cn_posts`, `cn_listings`,
   `cn_saved_posts`, and `cn_saved_listings`, with RLS. It does not alter website
   tables or auth triggers. If any `cn_*` names already exist, stop and reconcile
   them first. This migration is transactional and intentionally not silently
   idempotent: a name conflict must fail rather than reuse unknown tables.
   Do NOT apply the older unprefixed 202610010001 migration to the shared website
   database. Do NOT apply any SQL in `supabase/tests` to a real project.
4. In Authentication URL configuration, add this exact additional redirect:
   `com.carsnight.preview://auth-callback/`
   Keep the website's Site URL and existing redirects unchanged. Email/password
   auth must be enabled; confirmation/reset emails need working delivery. The
   preview Android app has the matching callback intent filter. Use the same
   phone for requesting and opening PKCE confirmation/recovery links.
5. Run the GitHub Actions `Build Android test APK` workflow again and download
   `CarsNight-test-APK`. Configuration is compiled in; existing APKs do not change.

For a local Flutter build, pass `--dart-define=SUPABASE_URL=...` and
`--dart-define=SUPABASE_PUBLISHABLE_KEY=...`, or a JSON dart-define file. Do not put
credentials into Dart source or commit configuration files. Missing configuration
keeps the sample app available and disables account submission. Invalid/private
keys are rejected before initialization. The key-shape check is not proof that
Supabase recognizes a key; only a live test establishes that.

## Implemented paths

- Profile > Sign in or join: email signup, sign-in, reset email, password update.
- Profile > Account and private drafts: sign-out, paged post/sale/rental drafts,
  create/edit/delete with ownership constraints and recoverable error messages.
- Prices in this increment use the offered two-decimal currencies and integer
  minor units; this is not a complete worldwide currency implementation.
- Auth users are shared with the website; mobile content is isolated in `cn_*`
  tables. Existing website content is not automatically imported or displayed.
- Profile names currently come from auth metadata. The `cn_profiles` and saved
  tables are prepared but not wired into the demo UI.
- Home, Buy, Rent, likes, comments, bookmarks and image composer still use sample
  data/local memory. Drafts save text only. Images, public publication, moderation,
  quotas, account deletion and live marketplace/feed integration remain unfinished.

## Live acceptance checks still required

Use dedicated test accounts: sign up and confirm; restart and check restoration;
sign out; sign in again; request and complete password reset on the same device;
create/edit/delete one post, sale and rental draft; restart and confirm persistence;
verify a second account cannot read/change the first account's drafts; test airplane
mode and retry; verify the website's existing login and content still work.

CI runs isolated PostgreSQL ownership tests, Flutter widget/unit tests and mocked
HTTP adapter tests. These do not verify this project's email, real tokens, RLS
installation, storage, callback handling on a device or production performance.
