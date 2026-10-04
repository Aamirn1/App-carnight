# Current acceptance — Profile, themes and Marketplace 0.8.0

The profile redesign, persistent appearance choice and compact Buy/Rent filters
are built and checked. See PROFILE_THEME_0.8.md for the APK and visual report.
Next, validate on the user's phone: appearance after restart, profile saves with
the live backend, actual follower/post counts and horizontal filter interactions.
New profile metadata is owner-facing; public profile sharing and direct avatar
uploads remain future work. No shared website schema was changed.

# Community reliability milestone — 0.7.0

Started the next community milestone with account-scoped photo drafts, persistent
retry IDs and the new user-supplied launcher icon. See ICON_AND_DRAFTS_0.7.md.
Save draft is explicit: save before leaving the composer. Publishing always saves
the exact request first. One photo remains the current cost-controlled limit.

Email templates and the exact app callback are live in Supabase. Fresh email
confirmation/recovery and physical-device acceptance still need checking.

Photo service deployed; permissions and unauthenticated rejection verified.
Next gates: confirmed-user phone upload/retry acceptance, then moderation and
image/account deletion, marketplace inventory bridging,
multi-photo posts and realtime messaging. Website tables must not be assumed to
match mobile tables. No production-ready or live-upload claim is made here.
