# Pre-launch Phase A — 0.10.0

## Changes

- The light theme now renders the original wordmark asset. Cars ink is black;
  Night retains its original cyan/blue/purple/magenta gradient, original script
  lettering and alpha silhouette. The underlying PNG has not been edited.
- The light rendering is decoded once and cached for the app lifetime. Near-white
  edge pixels are treated with the lettering so they do not leave pale flecks.
- Light-mode gradient button, Create and Find car lovers foregrounds use black
  for readable contrast. Dark-theme artwork and layouts remain the same.
- Selected drawer icons remain cyan on their existing dark gradient background.
- Outdated Settings statements about absent accounts/backend were replaced with
  accurate testing-build privacy/deletion notices and version information.

## Consolidated work

PRELAUNCH_PHASES.md defines four larger phases, A through D, and a complete test
matrix. FEATURE_AUDIT.md records each area as implemented, sample or unfinished.
The original roadmap is historical; the consolidated plan is the active sequence.

## Verification scope

The initial rendered logo exposed pale edge flecks; the neutral-ink tolerance was
corrected and the build rerun. Unit checks cover near-white and translucent edges;
a widget test loads the real asset and checks preserved alpha/gradient pixels,
original dimensions and image-based rendering rather than replacement text.
Design renders include both logo modes, profiles, Buy and Rent in both themes.

All eight final renders were inspected: the light logo has clean black Cars
lettering and the same Night gradient; Profile, Buy and Rent retain their layouts
and readable theme colours. The release-mode development APK built successfully (55.0 MB).

Tested source: a483b15ee01a7e61282842bf0606929815b82eb1.
[Successful build](https://github.com/Aamirn1/App-carnight/actions/runs/38372182151).
47 functional Flutter tests, 8 rendered preview checks, 4 media tests and all SQL
ownership/moderation/cleanup tests passed. Analysis had no errors or warnings;
two unnecessary-import informational notes were removed in the final source
cleanup without changing behaviour. Runner formatting and the resolved lock are
preserved. The formatter now removes these imports on subsequent runs.

[Download APK](https://github.com/Aamirn1/App-carnight/actions/runs/38372182151/artifacts/11800267028).
[Rendered preview ZIP](https://github.com/Aamirn1/App-carnight/actions/runs/38372182151/artifacts/11799417490).
Artifacts are retained for 14 days from this run; rerun Actions after expiry. Device testing, real account/email and
upload scenarios, full account deletion, live inventory, realtime notifications
and release signing are not claimed complete by this UI checkpoint.
