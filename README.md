# nestedreader.app

The site for **Nested**, the Mac research reader built in `truefrontier/nested-reader`. One static page, no build step: what is committed is what is served.

## Layout

- `index.html`, `styles.css`: the page. The facts, brand and constraints it follows are in `design/brief.md`; when a fact changes, edit the brief first, then the page.
- `assets/fonts/`: Instrument Sans and Literata, copied from the app so the page and the app set type the same way.
- `assets/icon/`, `assets/brand/`: the icon at web sizes and the logo SVGs. `assets/screenshots/`: real windows of the app at 2×.
- `assets/og.png`: the link preview, rendered from `design/og.html` by `design/og.sh`.
- `demo/`: the demo video and the scripts that make it (below).
- `.github/workflows/pages.yml`: publishes the repo root to GitHub Pages on every push to `main`. `CNAME` pins `nestedreader.app`.

## Update the version or the download

The download button points at `https://nested-feedback.fly.dev/updates/dmg`, which always redirects to the newest universal `.dmg`, so a release needs no change here. The version number is written once in `index.html`; search for it and bump it after `pnpm release` in the app repo.

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

GitHub Pages on the free organisation plan needs the repository to be public. Once it is: Settings › Pages › Source: GitHub Actions, then push to `main`. Point the domain at Pages (A records for `nestedreader.app` to GitHub's four IPs, `www` as a CNAME to `truefrontier.github.io`) and turn on Enforce HTTPS after the certificate arrives.
