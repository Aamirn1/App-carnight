> Phase C checkpoint: live app marketplace and realtime/unread messaging implemented; schema deployed. See [MARKETPLACE_PHASE_C_0.12.md](MARKETPLACE_PHASE_C_0.12.md). Acceptance and remaining feature work are explicitly open. APK builds deferred at the user’s request.

> Latest checkpoint: **0.11.0+13 — Phase B implementation deployed; device acceptance pending.** See [COMMUNITY_PHASE_B_0.11.md](COMMUNITY_PHASE_B_0.11.md) for features, test evidence, APK and remaining gates. This supersedes older statements below about missing deletion, member profiles, saved feeds and thumbnails. Website login is separate; app deletion does not remove website records.

# Consolidated pre-launch work

Follow PRELAUNCH_PHASES.md (A–D) in order. Phase A restores the original brand in
light mode, fixes gradient control contrast and records all feature/launch gaps
in FEATURE_AUDIT.md. Phase A automated checks and the 0.10.0 APK passed; see UI_PHASE_A_0.10.md.
Phase B is next: complete account lifecycle, community safety and media efficiency.

# Current checkpoint — Moderation and post cleanup 0.9.0

Post deletion, report review and scheduled image cleanup are implemented and
deployed. See MODERATION_CLEANUP_0.9.md. Moderator role assignment and physical
phone acceptance remain open. Full self-service account deletion is the next
unfinished part of this milestone; shared website identity/data must be handled
explicitly. Then proceed to feed thumbnails/caching and live inventory bridging.

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
