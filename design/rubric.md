# Rubric — nestedreader.app landing page arena

Artifact: one static landing page (index.html + styles.css, optional script.js) at the root of a candidate worktree, built from design/brief.md.

Score each criterion 1–5 with one sentence of evidence per candidate. Judge the rendered page (serve the worktree and screenshot at 375, 768, 1280, 1600 and in dark mode), not the source alone.

1. **Brand fit.** Reads as the same hands that made the app and the icon: cream and copper, Literata for reading, Instrument Sans for UI, hairlines, whitespace, the soft yellow highlight as the one bright note. Penalise SaaS-template tells (gradient buttons, heavy card shadows, icon grids, hero blobs).
2. **Message in the first screen.** Without scrolling at 1280 wide, a first-time visitor knows what Nested is, what the highlight gesture does, and where to download. The tagline earns its place instead of decorating.
3. **Craft.** Typographic rhythm, spacing, measure, alignment; the video block sits right (16:10, clipped corners, calm shadow or hairline); hover and focus states; nothing broken at any of the five renders; no horizontal scroll at 375.
4. **Copy honesty and plainness.** Every claim traces to the brief; plain short sentences; none of the banned words, no exclamation marks, no em dashes, no invented features, no price.
5. **Maintainability.** Small readable HTML and CSS a future maintainer can edit in minutes: tokens in :root, no dead rules, version and download link easy to find, no JavaScript needed to read the page.
6. **Accessibility and resilience.** Real heading order, contrast AA, visible focus, alt text that says what the picture shows, reduced-motion handling for the video, dark mode via the app's tokens, fonts preloaded and self-hosted, no third-party requests.

Recommend one base (the candidate a maintainer can extend most easily without breaking its own logic) and name, per losing candidate, the one or two things worth grafting into the base.
