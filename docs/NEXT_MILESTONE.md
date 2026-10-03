# Current gate: account and Home feed acceptance — 0.6.0

App work covers auth spacing, signup location, confirmation screen/Gmail access,
persistent login routing, gradient sign-in border and the Home-only feed redesign.
See [AUTH_AND_HOME_0.6.md](AUTH_AND_HOME_0.6.md) for the tested build and remaining
hosted email configuration. The public anon key cannot apply admin Auth settings.

Do not claim the live email issue resolved until the redirect allowlist/template
are applied and a fresh confirmation succeeds on the phone. Custom SMTP is required
to control the sender identity. Keep the shared website's correct production URL.

After these checks, continue with real marketplace inventory bridging, moderation
and image/account deletion, durable drafts/retry IDs, multi-photo posts and realtime
messaging. The photo function deployment remains a prerequisite for live uploads.
