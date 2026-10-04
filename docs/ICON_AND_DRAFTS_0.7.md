# Cars Night 0.7.0+9 — icon and community reliability

## Changes

- Original uploaded 500×500 PNG preserved in branding/launcher-source.png.
- Five Android launcher density assets updated; adaptive icon uses the same art
  with a gradient background and 21dp inset to protect the central C from masks.
- One explicit local photo draft per account; Save draft, restore and discard.
- Photo size capped at 2 MiB; bounded reads; temporary file flushed then atomically
  renamed. Files reside in the app support directory. No server storage cost.
- Before publication, save exact caption, photo and request UUID. Keep the same
  UUID after timeout/restart and lock edits while the result is uncertain.
- Clear draft after confirmed publication. Discard warns that a pending post may
  already exist. A cleanup failure retains the same UUID for safe reconciliation.

## Verification

Five storage tests cover restart recovery, ownership separation, replacement and
deletion, invalid-write preservation, and corrupt-file handling. All passed in GitHub Actions.

- Tested commit: `7948473b98352587c06ef1518964d47b70a24f5b`.
- [Successful run](https://github.com/Aamirn1/App-carnight/actions/runs/37214653150).
- 39 Flutter tests, 4 media tests, isolated SQL ownership/privacy/quota checks passed.
- Flutter analysis: no issues found.
- Release-mode preview APK: 54.7 MB, development signed.
- [Download APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/37214653150/artifacts/11308510340), expires 18 October 2026.
- Runner-formatted changed source and resolved dependency lock are retained.
- Source artwork matches the attachment byte-for-byte; density sizes and adaptive XML checked.

Physical-device icon/draft checks and live publication retries remain unverified.
No local Flutter SDK is available; Actions runs analyzer, Flutter tests, media
validator tests, isolated SQL tests and builds the development-signed preview APK.

## Device acceptance

Install over the previous APK. Check the launcher on your phone. Sign in, choose
one JPEG, enter caption, Save draft, close/reopen the app and return to Create.
Confirm photo/caption restore. A different account must not see this draft.
Discard should remove the local draft. Unsaved edits are not autosaved.
After live photo service setup, test a lost connection during publication and
retry after restart: only one server post should appear. Never treat a local
storage test as proof of live upload behavior.

## Remaining gates

Live email delivery/phone callbacks, photo service deployment, moderation/deletion,
marketplace bridge, multiple images and realtime messaging remain open. No schema
or website changes were made by this milestone. iOS build/signing is not included.

## Implementation references

- https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
- https://pub.dev/packages/path_provider/versions/2.1.5
- https://pub.dev/documentation/path_provider/latest/path_provider/
