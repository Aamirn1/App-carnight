# Version 0.4.1 — navigation and launcher update

Source commit: `54a1fb4e6c94541c4cdd84a552b3dcdd96691a9f`.

## Changes based on the supplied phone screenshot

- Use **Market** in the bottom bar, retaining **Marketplace** as the page title
  and Buy/Rent destinations. Compact consistent 11-point labels avoid the long
  Marketplace label breaking into two lines; selected labels use cyan.
- Discover/Following uses the existing purple surface and cyan selection, with
  no checkmark changing chip width.
- Group the unavailable-feed message, sample-feed button and retry into one card.
  An unavailable backend is still reported honestly; sample content is opt-in.
- Use the supplied CN/car artwork for Android launcher icons at all five legacy
  densities and an adaptive icon with white background and safe inset.
  Artwork and gradients are preserved; no generated replacement logo.

## Verification

[Successful Actions run](https://github.com/Aamirn1/App-carnight/actions/runs/37116568180).
Flutter analysis passed, 29 tests passed, and PostgreSQL privacy/ownership checks
passed. Android APK built successfully, approximately 53.1 MB, development signed.
[Download APK ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/37116568180/artifacts/11272031512).

No new device screenshot was captured here. Please check the installed icon,
Market label and setup card on the same phone. Android launchers can cache icons;
remove/re-add the shortcut if necessary. Development signing may require
uninstalling the previous preview, which clears its local data/session.

## Database activation

See [step-by-step SQL setup](SUPABASE_SETUP.md).
[Complete first-install SQL](../supabase/SETUP_SOCIAL.sql) creates 14 cn_* tables,
indexes, row-level access rules and RPCs. No live SQL was executed in this update.
Only install the appropriate migration for the existing schema. Public image
upload/publication and realtime messaging remain unfinished.
