import { existsSync, mkdirSync, readdirSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";

const [url, outDir] = process.argv.slice(2);
if (!url || !outDir) { console.error("usage: node design/shots.mjs <url> <outDir>"); process.exit(2); }

function findPuppeteer() {
  if (process.env.PUPPETEER_CORE) return process.env.PUPPETEER_CORE;
  const cache = join(process.env.HOME, ".claude/plugins/cache/claude-plugins-official/chrome-devtools-mcp");
  if (!existsSync(cache)) return null;
  const versions = readdirSync(cache).sort().reverse();
  for (const v of versions) {
    const p = join(cache, v, "node_modules/puppeteer-core");
    if (existsSync(p)) return p;
  }
  return null;
}
const pp = findPuppeteer();
if (!pp) { console.error("puppeteer-core not found; set PUPPETEER_CORE"); process.exit(2); }
const puppeteer = createRequire(import.meta.url)(pp);

mkdirSync(outDir, { recursive: true });
const browser = await puppeteer.launch({
  executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  headless: true,
  userDataDir: `/tmp/chrome-shots-${process.pid}`,
  args: ["--hide-scrollbars"],
});
const page = await browser.newPage();
const runs = [
  [375, "light"], [768, "light"], [1280, "light"], [1600, "light"],
  [375, "dark"], [1280, "dark"],
];
let bad = 0;
for (const [width, scheme] of runs) {
  await page.setViewport({ width, height: 900, deviceScaleFactor: 1 });
  await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: scheme }]);
  await page.goto(url, { waitUntil: "networkidle0" });
  await page.evaluate(() => document.fonts.ready);
  const m = await page.evaluate(() => {
    const doc = document.documentElement;
    const wide = [...document.querySelectorAll("body *")]
      .filter((el) => el.getBoundingClientRect().right > innerWidth + 1)
      .slice(0, 5)
      .map((el) => el.tagName.toLowerCase() + (el.className ? "." + String(el.className).split(" ")[0] : ""));
    return { inner: innerWidth, scroll: doc.scrollWidth, height: doc.scrollHeight, wide };
  });
  const file = join(outDir, `${width}-${scheme}.png`);
  await page.screenshot({ path: file, fullPage: true });
  const ok = m.scroll <= m.inner;
  if (!ok) bad++;
  console.log(`${String(width).padStart(4)} ${scheme.padEnd(5)} inner=${m.inner} scroll=${m.scroll} height=${m.height} ${ok ? "ok" : "OVERFLOW " + m.wide.join(",")}`);
}
await page.setViewport({ width: 1280, height: 900, deviceScaleFactor: 1 });
await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }, { name: "prefers-reduced-motion", value: "reduce" }]);
await page.goto(url, { waitUntil: "networkidle0" });
const rm = await page.evaluate(() => {
  const v = document.querySelector("video");
  return v ? { autoplay: v.hasAttribute("autoplay"), controls: v.hasAttribute("controls"), paused: v.paused } : null;
});
console.log(`reduced-motion video: ${JSON.stringify(rm)}`);
await browser.close();
process.exit(bad ? 1 : 0);
