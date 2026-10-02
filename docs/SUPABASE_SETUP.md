# Current setup: social-first version 0.4.0

The supplied public anon key is now in `config/supabase.public.json` and used by
GitHub Actions unless overridden by repository variables. This is intentionally
public client configuration, not an administrative credential.

The last successful read-only connection checks reached Auth and the existing
Listing endpoint; the mobile tables were missing at that check. Review and run [`../supabase/SETUP_SOCIAL.sql`](../supabase/SETUP_SOCIAL.sql)
in the project SQL Editor once. It installs the mobile + social schema in a single
transaction without changing the website Listing table. Add the auth redirect
`com.carsnight.preview://auth-callback/` while retaining the website's existing URL.

Read [SOCIAL_PRODUCT.md](SOCIAL_PRODUCT.md) for exact implemented/unfinished flows,
architecture, privacy rules, budget rationale and live verification requirements.
Local builds can use `--dart-define-from-file=config/supabase.public.json`.

## Existing installation

- If no cn_* tables have been installed, use the full SETUP_SOCIAL.sql bundle.
- If only the 0.3.0 mobile tables exist, run
  `supabase/migrations/202610020002_social.sql` after reviewing the existing schema.
- If the social tables/functions already exist, do not rerun CREATE statements;
  reconcile migration history first. Both scripts fail transactionally on conflicts.

No website rows or auth system were migrated. Please supply a schema-only export
of the existing Listing table and its seller/user relations for the next bridge.
Do not include customer rows, passwords or private credentials.

