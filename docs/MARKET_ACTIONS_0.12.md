# Marketplace actions checkpoint

## Implemented

Saved cars are account-owned and available through the Saved cars filter on Buy and Rent. Archived, removed or blocked offers no longer appear in the saved results.

Sellers can edit title, description, city and price. Currency, country, category and photo stay fixed in this editor. The server checks seller identity, published status and expected revision, preventing silent overwrites of a newer edit. The form preserves text after a failed save.

Listing reports enter the role-checked moderation queue with offer title and supporting image. A moderator's removal archives the offer and records a private audit note; it does not remove the associated social photo. User role metadata never assigns moderator authority.

Renters can choose 1–365 days, with pickup no more than 730 days ahead. Requested dates appear in the seller conversation. Enquiries retain a retry ID, are limited to 20/day/account and respect consent, decline and blocking. Dates are requests, not reservations, quotes or availability guarantees. The latest five enquiries appear in a conversation.

Three indexes cover previously unindexed comments/reports owner relationships. No website data or seller identities are changed.

## Verification and deployment

Initial implementation passed run 38530689116: 56 Flutter tests, clean static analysis, database ownership checks and 12 backend/media tests. APK steps skipped.

Automatic deployment review rejected the initial rental-enquiry read policy because its participant isolation depended on the conversation table's RLS. The unapplied migration was strengthened with explicit participant and block predicates before retrying. The strengthened migration deployed successfully on 14 October 2026. Live policy metadata confirms explicit requester/recipient and block predicates. Guests cannot execute rental requests and clients cannot directly insert enquiry records. Guest marketplace browsing still works.

Final source `82e6e8301272d0e47013fedf003ccc474bf02921` passed [validation run 38566327435](https://github.com/Aamirn1/App-carnight/actions/runs/38566327435): 56 Flutter tests, clean static analysis, database checks and 12 backend/media tests. No APK was generated.

## Remaining pre-launch gates

Physical two-account saved/edit/report/date/reconnect tests, populated-listing visual review, performance/transfer measurements, moderator assignment, push notifications and full app beta remain open. Website seller linking requires a verified identity flow; the website inventory was empty at inspection. Direct listing uploads and expanded structured specifications remain outside this checkpoint.

No APK will be generated until the remaining phases meet the user's requested completion checkpoint.
