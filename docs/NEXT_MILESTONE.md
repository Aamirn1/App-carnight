# Community reliability milestone — 0.7.0

Started the next community milestone with account-scoped photo drafts, persistent
retry IDs and the new user-supplied launcher icon. See ICON_AND_DRAFTS_0.7.md.
Save draft is explicit: save before leaving the composer. Publishing always saves
the exact request first. One photo remains the current cost-controlled limit.

Email templates and the exact app callback are live in Supabase. Fresh email
confirmation/recovery and physical-device acceptance still need checking.

Next gates: deploy and validate the photo service against the isolated app schema;
then moderation and image/account deletion, marketplace inventory bridging,
multi-photo posts and realtime messaging. Website tables must not be assumed to
match mobile tables. No production-ready or live-upload claim is made here.
