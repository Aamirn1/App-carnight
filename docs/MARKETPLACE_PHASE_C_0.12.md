# Phase C implementation checkpoint — 0.12.0+14

## Delivered

- Live app Buy/Rent marketplace using cn_listings; country, city, title and category filters, pagination, empty/error/retry states and pull to refresh.
- Listings reuse an owner's validated published photo, avoiding duplicate uploads. Publish retries use the same request ID. Seller can remove an offer. Removing/archiving the supporting post removes/retires the offer.
- Exact integer pricing for USD, PKR, AED, EUR, GBP, SAR, INR, JPY, KWD and BHD. Rental prices are daily asking prices, not reservations or availability guarantees.
- Listing enquiries use the existing consent-based conversations. The server validates the actual seller and published offer.
- Realtime message/conversation INSERT/UPDATE subscriptions invalidate the screen and reload authorized data. Refresh on reconnect and foreground resume; manual refresh remains available. Channels are removed on disposal and conversation session change.
- Private unread markers record exactly the fetched message IDs. A concurrently arriving message is not accidentally marked read. Inbox sorts by latest activity and shows unread badges.
- GitHub Actions defaults to validation only. APK steps require an explicit manual build_apk=true run, deferred until the remaining phases pass.

## Deployment and evidence

Both cn_conversation_read_state and cn_live_marketplace migrations applied on 14 October 2026. Hosted publication contains cn_messages and cn_conversations. Guest execution of cn_inbox is denied. No real messages were sent and no user listings were published during deployment.

Initial validation: https://github.com/Aamirn1/App-carnight/actions/runs/38396654111 — database checks, 53 Flutter tests and 12 backend/media tests passed. APK steps skipped. Four analyzer informational notices were then corrected, with additional narrow-screen theme tests added for final validation.

Database tests cover third-party unread isolation, idempotent reads, later arrivals remaining unread, block filtering, photo ownership, retry mismatch rejection, country/kind/search filters, seller enquiries and retirement of offers with archived photos.

## Remaining work before Phase C acceptance

- Physical two-account realtime/reconnect/unread/enquiry scenarios, live upload/publication and measured transfer/startup performance.
- Saved live listings, listing reporting/moderation, revision-checked editing and rental date enquiries are now implemented and deployed; see MARKET_ACTIONS_0.12.md. Expanded structured specifications remain deferred.
- Public push notifications are not implemented; realtime updates currently require an open app.
- Website seller linking/import is not implemented. The website Listing table was empty at inspection; website User identities are separate from Supabase Auth. Never infer ownership from matching display names. A verified linking workflow and website-side authorization are required before bridging future inventory.
- Publication currently chooses among the latest 20 own published photos. Direct listing photo upload and multi-image galleries are not included in this checkpoint.
- APK remains deferred. This document records implementation progress, not completed public-launch acceptance.

Security advisors retain the earlier reviewed service-only RLS and intentional checked RPC findings. Website search-path and leaked-password protection findings remain release review items, documented in COMMUNITY_PHASE_B_0.11.md.

Expanded validation run 38528616475 found two new narrow-screen test assertions failing and one remaining analyzer notice. The earlier 53-test baseline passed; the expanded 55-test run is being corrected and rerun. No APK was generated.

Performance advisor follow-up: covering indexes for cn_comments.user_id and cn_reports.reporter_id/reported_user_id were added in the deployed market-actions migration. Unused-index notices on this low-traffic project are not evidence that the indexes should be removed.

## Verified final checkpoint

Source `1f9c2a84babc6c376d43f6c031d36bbd7bfb6146` passed https://github.com/Aamirn1/App-carnight/actions/runs/38529480729 on 14 October 2026: **55 Flutter tests, clean static analysis, 12 backend/media tests and database ownership checks**. Both new 320px/1.5× text theme tests passed after using an injected fake repository. The earlier expanded test failures are superseded by this successful run. No APK was built.

The existing 12 fixture renders also passed; populated live-listing visual and physical-device acceptance remain open. Live smoke checks confirmed guest browsing works, guest inbox/read-marker/publication access is denied, and authenticated publication is granted through the ownership-checking RPC.
