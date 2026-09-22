# nestedreader.app

The site for **Nested**, the Mac research reader built in `truefrontier/nested-reader`. One static page, no build step: what is committed is what is served.

## Layout

- `index.html`, `styles.css`: the page. The facts, brand and constraints it follows are in `design/brief.md`; when a fact changes, edit the brief first, then the page.
- `assets/fonts/`: Instrument Sans and Literata, copied from the app so the page and the app set type the same way.
- `assets/icon/`, `assets/brand/`: the icon at web sizes and the logo SVGs. `assets/screenshots/`: real windows of the app at 2×.
- `assets/og.png`: the link preview, rendered from `design/og.html` by `design/og.sh`.
- `demo/`: the demo video and the scripts that make it (below).
- `design/publish.mjs`: publishes the page to its here.now site, which serves `nestedreader.app`.

## Update the version or the download

Neither needs a hand after a release. The download button points at `https://nested-feedback.fly.dev/updates/dmg`, which always redirects to the newest universal `.dmg`, so it never changes. The version in the footer keeps itself current: `.github/workflows/version.yml` asks the update relay for the newest release every six hours, writes it into the `<span data-version>` in `index.html`, commits that to `main`, and republishes the page. When the version has not moved it does nothing; when the relay has no version, or the page has no `<span data-version>`, it fails the run rather than publishing something wrong.

The one thing it needs is the here.now key as a repository secret named `HERENOW_API_KEY`, the same key that sits in `~/.herenow/credentials`:

```bash
gh secret set HERENOW_API_KEY < ~/.herenow/credentials
gh workflow run version   # run it now instead of waiting for the schedule
```

## Remake the demo video

The video is a screen recording of the installed app driven by a script, so it can be redone after the app changes.

```bash
demo/record.sh launch   # opens a fresh copy of demo/corpus in Nested, light theme, pinned window
demo/record.sh run      # waits for an idle Mac, then records demo/raw.mp4 with the gestures in demo/script.sh
demo/record.sh quit     # quits Nested and puts your own settings back
demo/cut.sh             # raw.mp4 → demo.mp4, demo.webm, poster.jpg (cuts the waits, fills the corners)
```

Needs `/Applications/Nested.app`, `ffmpeg`, `cliclick`, ImageMagick, Screen Recording permission for the terminal, and `claude` signed in (the recording uses the Claude plan provider, so the answers on screen are real). Leave the mouse and keyboard alone while it runs; `record.sh run` aborts if another app is in front. Coordinates in `demo/script.sh` are window points and assume the pinned 1280×800 window.

## Publish

The site is hosted on [here.now](https://here.now) as `nimble-ledger-acgn.here.now`, with `nestedreader.app` pointed at it through Cloudflare. Publishing is one command:

```bash
node design/publish.mjs            # what the page references, plus robots.txt and sitemap.xml
node design/publish.mjs --dry-run  # list the files and stop
```

It needs the here.now API key in `~/.herenow/credentials`. Each run stages a new version from the current live one and makes it live in one step; here.now keeps the earlier versions, so a bad publish can be restored from the dashboard.
