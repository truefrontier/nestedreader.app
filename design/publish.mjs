// Publishes the page to its here.now site. The file set is what index.html and styles.css
// reference, plus the page itself, robots.txt and sitemap.xml, so nothing stale rides along.
//
//   node design/publish.mjs            # publish to the slug below
//   node design/publish.mjs --dry-run  # list the files and stop
//
// Needs the here.now API key in ~/.herenow/credentials (one line, mode 0600).
import { createHash } from "node:crypto";
import { readFileSync, existsSync, statSync } from "node:fs";
import { join, dirname, resolve, extname } from "node:path";
import { fileURLToPath } from "node:url";

const SLUG = "aware-tassel-9yy6";
const HOST = "https://here.now";
const SITE = "https://nestedreader.app";
const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const CLIENT = "claude-code/nestedreader-app-publish";
const TYPES = {
  ".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".png": "image/png", ".jpg": "image/jpeg", ".webp": "image/webp", ".svg": "image/svg+xml", ".ico": "image/x-icon",
  ".woff2": "font/woff2", ".mp4": "video/mp4", ".webm": "video/webm", ".txt": "text/plain; charset=utf-8",
  ".xml": "application/xml; charset=utf-8", ".json": "application/json",
};

// Every local path the page reaches for: href/src attributes and CSS url() calls, relative or on the site's own host.
function referenced(text) {
  const out = new Set();
  const re = /(?:href|src|content)="([^"]+)"|url\("?([^")]+)"?\)/g;
  for (const m of text.matchAll(re)) {
    let u = m[1] ?? m[2];
    if (!u || u.startsWith("#") || u.startsWith("data:") || u.startsWith("mailto:")) continue;
    if (u.startsWith(SITE + "/")) u = u.slice(SITE.length + 1);
    if (/^[a-z]+:/i.test(u) || u.startsWith("//")) continue;
    u = u.replace(/^\.\//, "").split("#")[0].split("?")[0];
    if (u && !u.endsWith("/")) out.add(u);
  }
  return out;
}
const files = new Set([
  "index.html", "styles.css", "script.js", "robots.txt", "sitemap.xml",
  // script.js swaps these in for dark mode, so the page never names them.
  "demo/demo-dark.webm", "demo/demo-dark.mp4", "demo/poster-dark.jpg",
]);
for (const p of referenced(readFileSync(join(ROOT, "index.html"), "utf8"))) files.add(p);
for (const p of referenced(readFileSync(join(ROOT, "styles.css"), "utf8"))) files.add(p);
const manifest = [...files].filter((p) => existsSync(join(ROOT, p)) && statSync(join(ROOT, p)).isFile()).sort().map((path) => {
  const bytes = readFileSync(join(ROOT, path));
  return { path, size: bytes.length, contentType: TYPES[extname(path)] ?? "application/octet-stream", hash: createHash("sha256").update(bytes).digest("hex"), bytes };
});
const total = manifest.reduce((n, f) => n + f.size, 0);
console.log(`${manifest.length} files, ${(total / 1e6).toFixed(1)} MB`);
for (const f of manifest) console.log(`  ${f.path} (${f.size})`);
if (process.argv.includes("--dry-run")) process.exit(0);

const key = readFileSync(join(process.env.HOME, ".herenow/credentials"), "utf8").trim();
const headers = { Authorization: `Bearer ${key}`, "X-HereNow-Client": CLIENT, "Content-Type": "application/json" };
async function api(method, path, body) {
  const res = await fetch(HOST + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status} ${JSON.stringify(json).slice(0, 400)}`);
  return json;
}

const current = await api("GET", `/api/v1/publish/${SLUG}`);
console.log(`live version ${current.currentVersionId} (${current.currentVersionSource}, ${current.currentVersionCreatedAt})`);
const description = "Nested is a calm research reader for a folder of Markdown notes on your Mac. Highlight a phrase and ask about it.";
const staged = await api("PUT", `/api/v1/publish/${SLUG}`, {
  files: manifest.map(({ path, size, contentType, hash }) => ({ path, size, contentType, hash })),
  baseVersionId: current.currentVersionId,
  displayName: "Nested",
  displayDescription: description,
  viewer: { title: "Nested", description, ogImagePath: "assets/og.png" },
});
const { versionId, uploads, skipped = [] } = staged.upload;
console.log(`staged version ${versionId}: ${uploads.length} to upload, ${skipped.length} unchanged`);
for (const target of uploads) {
  const f = manifest.find((x) => x.path === target.path);
  const res = await fetch(target.url, { method: target.method, headers: target.headers, body: f.bytes });
  if (!res.ok) throw new Error(`upload ${target.path} → ${res.status} ${await res.text()}`);
  process.stdout.write(".");
}
console.log("");
const done = await api("POST", `/api/v1/publish/${SLUG}/finalize`, { versionId });
console.log(`live: ${done.siteUrl} version ${done.currentVersionId}${done.unchanged ? " (unchanged)" : ""}`);
for (const u of done.urls ?? []) console.log(`  ${u.kind}: ${u.url}`);
