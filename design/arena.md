# How the page was chosen

Three candidates built the page from the same brief (`design/brief.md`) in separate worktrees, one each on Claude Opus 5, Claude Fable 5.1 and Claude Sonnet 5. A fourth agent on Opus judged them read-only against `design/rubric.md`, and a panel of three non-Anthropic models reviewed the pick. The branches `arena/c1`, `arena/c2` and `arena/c3` hold the candidates.

## Base

Candidate 2 (Fable). It is set like a page in the app: the app's 33em Literata column, its light and dark tokens, the loop drawn in HTML from the same fonts and tokens, a hover peek that works on focus too, and the smallest stylesheet. It stops the video for readers who asked for less motion and adds a pause control for everyone else.

## The judge

Scores out of 30: candidate 2 at 29, candidate 1 at 26, candidate 3 at 19. Candidate 2 led on brand fit, the first screen, craft and accessibility, and has the smallest surface: two classes carry the layout and theming is two blocks. The judge and the panel agreed on the base.

## Grafts

- From candidate 1 (Opus): the privacy heading "What leaves your Mac", and the requirements line as plain text under the download button instead of a second line inside it.
- From candidate 3 (Sonnet): a shorter hero lede. Taken as a trim of the base's lede, not a replacement.
- From candidate 1, on the judge's suggestion: the tree and the folder side by side with the same six names, so "every page is a plain file" is seen rather than read. The two sections that held them became one.

## Rejected

- Candidate 1's left-axis layout with an interactive `<details>` Quick Answer. It moves the highlight off the tagline and breaks the reading column. The judge also suggested the `<details>` for the dotted-underline demo, on the grounds that a hover peek does nothing on a phone; a tap test on an emulated iPhone showed the phrase takes focus on tap and the answer shows, so the base's peek stays.
- Candidate 3's second `<video>` toggled by CSS for reduced motion. The hidden copy keeps autoplaying.
- Candidate 3's relative `og:image` URL and contractions in the copy.

## Fixed in the base

Both figures highlighted "same order" while the typed question was about the replay sentence. The highlight now covers "This replay is thought to move fragile memories into the cortex", the sentence the demo video asks about.

## Verified

`design/shots.mjs` on the integrated page: no horizontal overflow at 375, 768, 1280 or 1600 in light or dark mode; under reduced motion the video has no autoplay, shows controls and is paused. A probe in headless Chrome: the webm plays, the pause control appears, the peek shows on focus and on hover and hides on Escape, and every request is same-origin.
