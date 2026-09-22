# nestedreader.app — page brief

The one-page marketing site for **Nested**, a Mac app. This file is the source of truth for facts, brand, and constraints. Do not invent features beyond the facts here.

## The product, in facts

- **Nested** is a calm research reader for a folder of Markdown notes. macOS 12 or newer, one universal build (Apple Silicon and Intel). Built with Tauri 2, React and Rust.
- Tagline: **Highlight your understanding.**
- The core loop. Read a page. Select text to ask about it. **Quick Answer** (↵) puts a short answer inline, right under the paragraph. After it closes, the text keeps a dotted underline and hovering it shows the answer again. **New Page** (⌘↵) writes a new page about the selection and opens it beside the one you are reading. **Deep Dive** (⌘⇧↵) writes a longer page in the background and marks it unread for later.
- New pages **nest** under the page they came from. The tree in the sidebar shows the shape of what you have understood so far. A blue dot means unread, a green ring means changes to review.
- **Refine** (⌘R) rewrites a selection, a page, or the whole session. Changes are tinted so you can undo any one of them, and every refine keeps the previous text as a version.
- **Every page is a plain `.md` file in the folder you opened.** Nothing else is required to read your notes elsewhere. Open a folder and every `.md` inside is the corpus, or open a single `.md` and pages you create are saved next to it. Drag a folder or file into the window to open it. Nested can be the default app for Markdown files.
- **Session map** (⌘K) shows the pages as a graph. **Home** lists recent sessions.
- **Bring your own AI.** Settings › AI: OpenAI, Anthropic, Ollama, or any OpenAI-compatible server. API keys live in the macOS Keychain. Or use the ChatGPT plan or Claude plan you already pay for, through the official command-line tool signed in on your Mac. With Ollama nothing leaves the machine.
- The model can read the folder itself while it answers (read-only, never outside the folder), and the page says what it is reading. Context toggles decide what leaves the machine with each request.
- Privacy. No account. No content, file paths, prompts or keys are ever sent anywhere except to the AI provider you chose. (Anonymous usage counts only in builds compiled with an analytics key.)
- Updates. The app checks for a newer version a few seconds after it opens and every few hours; a quiet card at the foot of the window offers **Update and relaunch**.
- Feedback. A quiet **Send feedback** link at the bottom of the sidebar, inside the app.
- Download: `https://nested-feedback.fly.dev/updates/dmg` (always redirects to the newest universal `.dmg`). Current version: 0.2.7. Open the `.dmg`, drag Nested to Applications.
- First launch. Builds are signed and notarized with Apple Developer ID, so a normal double-click open works. Do not mention Open Anyway, Control-click, or Gatekeeper workarounds.
- Maker: **True Frontier** (https://truefrontierapps.com). No pricing exists; do not mention price, "free", or "beta". No email address on the page.
- Shortcuts worth showing if a section wants them: ↵ Quick Answer · ⌘↵ New Page · ⌘⇧↵ Deep Dive · ⌘R Refine · ⌘K Map · ⌘F Find · ⌘B Toggle tree · ⌘O Open.

## Brand

- **The icon** (`assets/icon/`): a cream rounded square with a nest of woven copper strands, slightly tilted. Metaphor: interwoven strands, pages nesting inside pages. Palette from the icon: cream `#F6EFE4`, copper strands from `#6B432D` (dark) through `#A4886F` (mid) to `#CFAF94` (light). `icon-1024.png` is the raw square art (no mask); `icon-1024-squircle.png` and `icon-256-squircle.png` carry the macOS rounded mask, for showing it "as in the Dock".
- **Logos** (`assets/brand/`): `nested-logo.svg` is the wordmark with the nest (903×183, fill `#A4886F`). `nested-logomark.svg` / `-tight.svg` / `-tight-small.svg` are the nest alone. `nested-mark-strokes.svg` is the three-stroke mark the app itself uses (currentColor, 128×128).
- **The app's own tokens** (its light theme): background `#faf9f7`, text `#1e1c19`, muted `#8e887e`, hairline `rgba(30,28,25,.09)`, sidebar `#f2f0ec`, accent green `oklch(0.55 0.1 150)`, highlight yellow `oklch(0.93 0.06 95)`, unread blue `oklch(0.58 0.15 255)`. Dark theme: background `#171614`, text `#e8e4dd`, muted `#7f7a71`, sidebar `#1e1d1a`, accent `oklch(0.76 0.1 150)`, highlight `oklch(0.42 0.07 95)`.
- **Type**: Instrument Sans for UI and Literata for reading, both self-hosted in `assets/fonts/` (400–500 normal; Literata 400 italic). The app sets reading text at 17px Literata on a 33em column. Use these two families and nothing else.
- **Feel**: the app is quiet. Generous whitespace, hairline rules, no cards with heavy shadows, no gradients, no emoji, no stock illustrations. The one warm note is the copper of the icon. The one bright note is the soft yellow highlight, which is the gesture the tagline is about.
- **Screenshots** (`assets/screenshots/`, all 2× pixels): `reading-2x.png` (the whole window, 1280×800 logical, on the page "Why the brain replays the day"), `reading-same-order-2x.png` (another page), `ask-box-2x.png` (a highlighted phrase with the ask box open under it), `quick-answer-2x.png` (the same phrase with its answer card inline).

## The demo video

The page embeds a screen recording of the real app. Contract:

- Files: `demo/demo.webm`, `demo/demo.mp4`, `demo/poster.jpg`. 1280×800 logical (16:10), no audio, about a minute, loops well. Until the real files land, `demo/poster.jpg` is a placeholder screenshot; the page must look finished with just the poster.
- The frames are the bare window content with the window's own rounded corners; the corners are filled with `#faf9f7`. Clip the video with `border-radius` and `overflow: hidden` anyway, and give it a soft, wide, low-opacity shadow or a hairline, not a heavy drop shadow.
- `<video autoplay muted loop playsinline preload="metadata" poster="demo/poster.jpg">` with `<source>` webm then mp4. Under `prefers-reduced-motion: reduce`, do not autoplay: show the poster with a visible play control.
- What the video shows, in order: a page opens; a sentence is highlighted and the ask box appears; a question is typed; the Quick Answer streams in under the paragraph; the answer closes and the dotted underline stays; another phrase is highlighted and ⌘↵ opens a New Page beside; the new page streams in and appears nested in the tree; the session map.

## Page constraints

- One static page: `index.html`, `styles.css`, and at most one small `script.js` (only if it earns its place; the page must read and work without it). No build step, no framework, no CDN, no third-party requests of any kind, no analytics. Served from the repo root on GitHub Pages.
- Sections, in an order that tells the story: hero (tagline, one plain sentence on what it is, the download button, the video); the loop (highlight → ask → answer inline; new pages nest; plain `.md` files); bring your own AI; privacy; download (requirements, updates); footer (True Frontier, feedback lives in the app, version). Merge or reorder if the page reads better, but keep every fact that a visitor needs before downloading.
- Works at 375px with 16px gutters and no horizontal scroll, and at 1600px+ without stretching. Reading measure stays under ~70 characters.
- Honor `prefers-color-scheme: dark` with the app's dark tokens.
- Accessible: real headings, contrast AA, visible focus, alt text that says what the picture shows, the video described.
- No layout shift: images carry width/height, fonts are preloaded with `font-display: swap`.
- `<title>Nested</title>` plus meta description, `og:title`, `og:description`, `og:image` at `assets/og.png` (1200×630, will be produced later), favicon links to `assets/icon/favicon-32.png` and `assets/icon/apple-touch-icon.png`.
- Copy: plain English, short sentences, no hype words (no "seamless", "powerful", "supercharge", "revolutionize", "effortless", "unlock"), no exclamation marks, no rhetorical questions, no em dashes. Write the way the README talks. Every claim must trace to a fact above.
