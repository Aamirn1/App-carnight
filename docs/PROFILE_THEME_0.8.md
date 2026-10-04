# Cars Night 0.8.0 — profile, appearance and marketplace layout

## Reference analysis and adaptation

| Reference option or region | Cars Night implementation |
|---|---|
| Full-width cover with camera action | Car cover, editable from bundled illustrations or own loaded published photos |
| Large overlapping circular portrait and camera | Bordered avatar overlapping cover, same functional photo chooser |
| Back/search/more | Existing application navigation/search, profile settings shortcut |
| Name, verification and account dropdown | Actual account name; no invented badge or account switcher |
| Followers, following, posts | Real counts when queries succeed; unknown shown as dash, never fabricated |
| Bio with see more | Editable bio limited to 160 characters |
| Occupation, location and personal details | Car enthusiast, city and dream car in About |
| Mutual friends | Find car lovers action; no invented mutual connections |
| Dashboard/Create | Edit profile/Create plus Account; no fake professional dashboard |
| All/Reels/Photos/More | Posts/Photos/About, matching image-only scope |
| Personal details pencil | Edit details form |

Online name synchronizes to the existing cn_profiles display_name and Auth metadata.
Bio, dream car and photo choices use account metadata for the owner's profile;
public sharing of these new fields is not implemented. No schema or permission
changes are required. Existing published photos already have server validation.
The chooser does not upload arbitrary files: use Create to publish a new photo.
Preview profile changes are session-only and labelled. Saved collection remains
the existing sample saved collection; no fictional dashboard metrics are shown.

## Appearance

Settings offers Light, Dark and System. Dark remains the default. The preference
is saved on-device before applying; startup restores it. Theme changes preserve
navigation and account session. Cards, text, inputs, navigation, dialogs and
welcome gradients adapt. The light wordmark uses readable styled text instead
of white lettering on white. Original dark branding is preserved.

## Marketplace

Both Buy and Rent put search directly below the introductory subtitle. Country,
city, category, dates (Rent only), and Reset occupy one horizontally scrollable
row. Filters keep their original behavior and location defaults. Explicit sample
inventory labels remain. Horizontal scrolling protects touch targets and avoids
wrapping controls into several rows on smaller phones.

## Verification

CI analyzer, tests, renders and APK results pending. Flutter previews cover the
three redesigned pages in both themes; these are widget-test renders using the
runner font, not physical-phone screenshots. Live account updates/counts and
physical-phone visual acceptance still require end-to-end testing.

Official references consulted:
- https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html
- https://pub.dev/packages/shared_preferences/versions/2.5.5
- https://supabase.com/docs/reference/dart/auth-updateuser
- https://supabase.com/docs/reference/dart/select
