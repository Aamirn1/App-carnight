# Next functional milestone: connected-services foundation

The user approved the Home-screen appearance on 1 October 2026. Preserve its
layout, colors and imagery. The selected bottom-navigation icon now explicitly
uses cyan, fixing the black-on-purple contrast seen on the phone.

The user calls the next milestone “Phase 2”. The original detailed roadmap called
backend integration Phase 3; these refer to the same next functional work here.
The visual prototype exists, and Home has been reviewed on one real device.
Other screens and supported devices still need visual review.

## Implemented in this increment

- Explicit selected/unselected navigation icon colors and a regression test.
- Provider-independent account, post-pagination and image-upload interfaces.
- Supabase-compatible PostgreSQL migration for profiles, post/listing drafts and
  private saved collections, with row-level ownership policies and query indexes.
- Privileged publication boundary: mobile users cannot mark drafts published.
  The eventual server must validate media and perform moderation before publication.
- An isolated PostgreSQL CI job checks the migration and ownership rules before
  the Android build is allowed to run. This is not a deployment to a live project.

## Not connected yet

No backend project has been created or configured. Repository interfaces have no
production adapters yet. The existing auth forms and demo feed remain explicitly
in demo mode. The migration does not implement image storage, image processing,
real sign-in/recovery, account deletion, reports, quotas or live feeds. Those are
remaining work, not completed features.

Supabase is the proposed backend target for this schema; no plan or purchase has
been selected. To connect it, a Supabase project URL and public publishable key
will be needed. Server/service-role keys must never be committed or embedded in
Flutter. Project setup must also establish region, actual budget and email setup.

## Safe migration workflow

Review supabase/migrations/202610010001_initial_content.sql in a new development
Supabase project before applying. It creates new tables and does not drop existing
data. Do not apply it to an unrelated or existing production database. NEVER apply
supabase/tests/bootstrap.sql to Supabase; it is a disposable CI-only auth fixture.

Publishing requires a future restricted server operation. Do not relax the RLS
publication policies just to make client posts appear live. Storage buckets and
media approvals remain closed until the image validation pipeline is implemented.

The PostgreSQL tests validate table constraints and role-scoped authorization;
they do not verify Supabase auth, token validation, storage or production networking.
