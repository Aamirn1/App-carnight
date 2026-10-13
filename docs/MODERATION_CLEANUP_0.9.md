# Moderation and post cleanup — 0.9.0

## Delivered

Home's own-post menu now offers Delete post with confirmation. Other posts offer
Report post with reason selection. Deleting a post cascades its comments, likes,
saves and media metadata, while a protected outbox retains the image path.

Settings shows Moderation queue only for explicitly assigned moderators. The
server independently verifies this role on every queue/review request. Reviewers
see the report reason, caption and available photos, then dismiss or remove with
a required private audit note. Reports are paged as the oldest 50 outstanding
items; reviewed items leave the queue. Normal users cannot self-assign a role.
No moderator has been appointed by this release.

## Live deployment and verification

- Moderation/cleanup and scheduled worker migrations installed on the existing
  project, using only mobile cn_* objects plus scheduler/Vault infrastructure.
- cn-cleanup-media v1 deployed. Gateway JWT verification is intentionally off
  because the worker uses a separate high-entropy scheduler credential in Vault.
  Every request checks that credential server-side before claiming any work.
- Missing and invalid credentials return 401. Vault-authenticated empty run returns
  204. A harmless cleanup job referencing a nonexistent maintenance path completed
  via the Storage API with HTTP 204 and one attempt. No user content was removed.
- Clients cannot claim cleanup jobs, read worker credentials or assign moderators.
- Guest execute privileges on three existing messaging RPCs were removed after
  detecting hosted grants had drifted from source. Identity checks remain intact.

## Cleanup behavior and limits

The post disappears immediately after the database deletion succeeds. Image
cleanup becomes eligible after 20 minutes, allowing in-flight publishing requests
to finish; the scheduler checks every five minutes and calls the worker only when
work is due. Up to 20 objects are claimed per run. Leases prevent duplicate claims;
failed jobs retry after one hour, up to 20 attempts. Exhausted jobs remain recorded
for operator investigation. The image is removed with the Storage API, never by
SQL deletion of storage.objects. A deleted photo request cannot republish its post.
Upload quotas remain charged after deletion, preserving the pilot budget cap.

Public CDN/device caches or already-downloaded copies can outlive origin deletion.
This is not immediate revocation of publicly shared images. No automated moderator
assignment, AI content scanning, suspension/appeals system or cleanup alert delivery
has been introduced.

## Operator setup

Use the Supabase SQL editor as an authorized project administrator. Copy the exact
user UUID from Authentication > Users, verify the intended account, then run:

```sql
insert into public.cn_moderators(user_id)
values ('REPLACE_WITH_VERIFIED_AUTH_USER_UUID'::uuid)
on conflict do nothing;
```

Reopen Settings in that account to see Moderation queue. Revoke access by deleting
only that UUID from cn_moderators. Client metadata cannot grant moderator access.

Monitor pending and exhausted cleanup work without reading object paths:

```sql
select count(*) filter (where completed_at is null) as pending,
       count(*) filter (where completed_at is null and attempts >= 20) as exhausted
from public.cn_media_cleanup;
```

Security advisors were reviewed: no-policy notices for service-only tables are
intentional; role-checked RPC notices are expected. Existing website
update_updated_at search-path and disabled leaked-password protection findings
remain separate configuration work. See the [Supabase advisor reference](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable)
and [password protection documentation](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

## Remaining account deletion work

Full self-service account deletion is not enabled in this checkpoint. App and
website share Auth; removing that identity revokes access to both. A complete flow
needs explicit user-facing scope, recent reauthentication, session revocation,
website-data mapping, and staged cleanup before deleting Auth. The new outbox
survives account cascades and records unfinished upload paths, but that is only a
foundation, not a completed account deletion feature.

## Acceptance

Automated SQL coverage includes foreign-owner deletion rejection, moderator
self-assignment rejection, unauthorized queue access, review/audit behavior,
deleted-upload retry prevention, grace period, lease exclusion, stale completion,
failed cleanup retry, and account-cascade path retention. Widget tests cover review
note enforcement and cancellation. Phone tests of new menus and a real published
photo's deletion are still required. This remains a development-signed preview.
