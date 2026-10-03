# Current setup: social-first app

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


## Copy and run the SQL

1. Open your Supabase project, then **SQL Editor → New query**.
2. If you have never installed the mobile schema, open
   [the complete SQL file](../supabase/SETUP_SOCIAL.sql), choose **Raw**, and copy
   everything from `begin;` through the final `commit;` into the editor.
3. Run it once. The script creates 14 app tables plus access rules, indexes and
   functions. Keep the existing website tables and auth settings.
4. Add the Android callback under Authentication → URL Configuration → Redirect URLs:
   `com.carsnight.preview://auth-callback/`.
5. Reopen the app and tap **Try again**. The live feed starts empty; public image
   publishing is a later feature.

To check for an earlier mobile installation before choosing a script, run this
read-only query:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and left(table_name, 3) = 'cn_'
order by table_name;
```

No rows: use the full first-install script. Only the five original tables
(`cn_profiles`, `cn_posts`, `cn_listings`, `cn_saved_posts`, `cn_saved_listings`):
use only `202610020002_social.sql`. If other cn_* tables exist, check migration
history first; do not delete tables or bypass errors.
