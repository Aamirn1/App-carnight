# Cars Night reference analysis

This is the initial reference inventory. Its foundation-status column records the
Phase 1 baseline; see STATUS.md for the current Phase 2 comparison.

Source: user-supplied 1280 × 853 JPEG, included under reference/.
It is a promotional montage containing five narrow phone mockups, not five
full-resolution UI exports. The perspective, compression and small text prevent
reliable extraction of exact fonts, spacing, icon assets or color tokens.

## What the picture communicates

Cars Night combines a car enthusiast social community with a global sale/rental
marketplace. The hero, luxury vehicles and neon skyline establish the brand.
The words Community, Buy & Rent, Premium and Global Reach describe intended
product pillars. The picture's “20+ countries” and premium badges are marketing
concepts, not verified launch coverage or existing entitlements.

Outside the phones, the huge city and reflective road are presentation framing.
Rendering that entire scene behind every page would not reproduce the actual
phone UI and would increase distraction and asset cost.

## Screen inventory and fidelity criteria

| Reference view | Observed composition | Foundation status | Remaining work |
|---|---|---|---|
| Welcome, labelled Splash Screen | Neon skyline and front-facing car above a script wordmark; centered two-line value proposition; Get Started gradient pill and outlined Sign in | Scrollable welcome, fallback wordmark, tagline and actions | Original hero artwork and script logo; exact spacing and button copy after auth exists |
| Home / Social Feed | Compact wordmark; search and notification actions; horizontal circular story/brand rail; avatar, author, time/location, caption, landscape image; social actions; bottom navigation | Static brand rail, sample post layout, local likes/saves, navigation | Original photo assets, header actions, comments, share, real profiles, timestamps, image stories if retained |
| Buy | Back/header control, large heading, short description, search, All/Buy/Rent switch, category circles, stacked photo cards with favorite and price | Separate Buy tab, search, category chips, sample cards and detail route | Exact rail/switch styling, real photographs, advanced filters, real listings and seller contact |
| Rent | Back/header, title, location field, pickup/dropoff controls, category row, compact horizontal vehicle cards, daily prices and ratings | Separate Rent tab, city search, categories and sample daily prices | Date/location fields, compact horizontal cards, availability, quotes; no invented ratings |
| Drawer | Script wordmark, close affordance, avatar/name/email, premium badge, gradient active menu item, Home/Buy/Rent/Plan/Blog/About/Contact, Settings/Logout | Standard Flutter drawer, guest identity, main navigation, pending secondary destinations | Exact active styling, custom close control, actual account and entitlements |

The photo mockups suggest Home, Buy, Create, Rent and Profile bottom navigation.
Create is an action opening a composer rather than a page with its own persistent
tab state. The foundation preserves this distinction.

## Design system

The source uses estimated colors: background #070A1B, cards #14182C, border
#30354B, muted text #B9BED0 and accents #14B5FF → #9058FF → #E52CEB.
These are proposed tokens, not measured original values. Exact asset exports or
an approved visual pass are required to lock them.

Use readable sans-serif text for controls and body copy; reserve script lettering
for the logo. Bundle a licensed logo/font asset rather than downloading a font
at startup. Keep 48 logical-pixel touch areas and support large text, even where
the compressed promotional mockup appears smaller. Preserve safe areas and use
real device status bars rather than painting the pictured “9:41” and notch.

Image corners, borders and restrained gradients are inexpensive starting points.
Avoid constant particles, background video, heavy blur and animated reflections
on ordinary screens. None are necessary to match the reference phone interfaces.

## Screens that must be designed beyond the image

Authentication and recovery; profile editing; image-post creation and preview;
sale/rental listing forms; listing and post details; saved items; comments;
notifications; report/block; account deletion; settings; plan details; blog list
and article; about/contact; terms/privacy; empty, loading, offline and error states.
These can match the visual language, but cannot truthfully be called exact copies
of unseen reference pages.

## Visual acceptance process

1. Use each phone's inner content area, excluding device bezel/presentation labels,
   as the comparison target. Preserve the original reference unchanged.
2. Run actual Flutter screens at 360, 390 and 430 logical-pixel widths plus 320
   for narrow-screen stress testing; include large text and safe-area variants.
3. Compare layout hierarchy, navigation, typography, assets, spacing, color and
   states separately. Record every intentional accessibility adaptation.
4. Capture actual screenshots and inspect side by side. Golden tests should then
   lock reviewed Flutter screenshots, not blindly copy noisy JPEG pixels.
5. Give each screen a status: matched, intentional difference, outstanding or
   unverified. Never report a guessed “100% match” or fabricate screenshots.
