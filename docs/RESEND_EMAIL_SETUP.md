# Cars Night — Resend and Supabase email setup

## Verified scope

The existing published Resend template `untitled-template` was retrieved through
Resend's API. Its sender is `Cars Night<cars@carsnight.com>` and its HTML uses
Supabase's `{{ .ConfirmationURL }}` and `{{ .Token }}` placeholders. Its variables
list is empty. An exact export is saved as
[confirmation template](../supabase/templates/confirm_signup_resend_export.html).
The sender address is configured in that template. Live Supabase SMTP is enabled
with sender name Cars Night, host `smtp.resend.com`, and port `465`. The dashboard
redacts its sender address and username; domain verification was not checked.

Resend SMTP is a delivery service. It does not automatically select a template
saved in Resend. For the current integration, use Supabase to render the HTML and
Resend SMTP to deliver it. This avoids a new server function and preserves all
existing website and app authentication email types.

## Live activation — 2026-10-04

Saved and reopened all three branded Supabase templates: Confirm signup, Reset
password, and Password changed. The password-changed notification is enabled.
The existing Resend SMTP credentials were preserved. Supabase renders the
templates and Resend delivers the emails; no Send Email Hook was added.

Saved the explicitly approved redirect `com.carsnight.preview://auth-callback/`
and verified it appears in the redirect list (one URL). The existing Site URL
remains `https://www.carsnight.com/`. No live email delivery or phone callback
test has been performed.

## Configuration reference

In Supabase Authentication → Email:

1. Under SMTP Settings, check that the sender name is Cars Night and the sender
   address is on your verified Resend domain. The observed template uses
   `cars@carsnight.com`. Resend SMTP uses host `smtp.resend.com`, port `465`,
   username `resend`, and your Resend key as the password. Do not put the key in
   Flutter, public config or GitHub source.
2. Under Confirm signup, use subject `Confirm your Cars Night account` and paste
   the exported confirmation template. Keep its Supabase placeholders intact.
   The existing repository's `confirm_signup.html` provides a solid cyan wordmark
   fallback if your mail client cannot render the exported gradient text.
3. Under Reset password, use subject `Reset your Cars Night password` and paste
   [reset_password.html](../supabase/templates/reset_password.html).
4. Enable the **Password changed** security notification, use subject
   `Your Cars Night password was changed`, and paste
   [password_changed.html](../supabase/templates/password_changed.html).
   This notification has no reset token or one-click reset link: it is sent after
   a successful password update and directs the user to the app if unexpected.
5. Keep the exact allowed app redirect `com.carsnight.preview://auth-callback/`.
   Preserve the website's redirects and correct production Site URL. SMTP changes
   alone do not fix a localhost fallback.

These settings have been applied through the authorized Supabase dashboard.
No new APK or SQL table is needed for template changes; the current app already requests password recovery with the app callback
and handles the password recovery event.

## Templates stored in Resend

Matching reset and password-changed templates have also been created and published in Resend;
see [template IDs/status](../supabase/templates/resend/templates.json).
The Resend reset version uses the declared variable `RESET_URL` with syntax
`{{{RESET_URL}}}`. The Supabase version uses `{{ .ConfirmationURL }}` instead.
Do not paste Resend variable syntax into Supabase.

To reference Resend template IDs dynamically, a Supabase Send Email Hook would
need to verify webhook signatures and supply the actual secure URLs/tokens to
Resend. This replaces built-in email sending for the project and must handle all
used auth types. No hook has been deployed or enabled; the existing SMTP route
is the recommended setup for this stage. The original Resend signup template is
unchanged and is not ready for direct template-ID sending with its current
Supabase-only placeholders.

## Acceptance

Use a dedicated account to request signup and recovery after activation. Check
that fresh links open the installed app, recovery opens the new-password form,
expired/used links fail, and the password-changed notification arrives only after
a successful update. Check the existing website flow too. Do not send production
test mail to arbitrary users. No real auth email was sent during this work.

References:
- https://resend.com/docs/send-with-supabase-smtp
- https://supabase.com/docs/guides/auth/auth-email-templates
- https://supabase.com/docs/guides/auth/auth-hooks/send-email-hook
- https://resend.com/docs/api-reference/templates/create-template
