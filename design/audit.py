"""Static SEO and accessibility checks for the page, run before a publish. Standard library only, no network.

    python3 design/audit.py      # prints the findings; exits 1 on any FAIL, WARN does not fail

Covers the head tags, ids and in-page links, local files the page points at, alt text, heading order,
landmarks, JSON-LD, robots.txt and the sitemap. Colour contrast and screen-reader output are not checked here.
"""
import sys, os, re, json, html.parser, xml.etree.ElementTree as ET
root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(os.path.join(root, "index.html"), encoding="utf-8").read()
fails, warns = [], []
class P(html.parser.HTMLParser):
    def __init__(s):
        super().__init__(); s.tags=[]; s.ids=[]; s.heads=[]; s.cur=None; s.title=""; s.intitle=False; s.ld=[]; s.inld=False; s.buf=""
    def handle_starttag(s, t, a):
        a=dict(a); s.tags.append((t,a,s.getpos()[0]))
        if "id" in a: s.ids.append(a["id"])
        if t in ("h1","h2","h3","h4","h5","h6"): s.cur=[t,"",s.getpos()[0]]
        if t=="title": s.intitle=True
        if t=="script" and a.get("type")=="application/ld+json": s.inld=True; s.buf=""
    def handle_endtag(s, t):
        if s.cur and t==s.cur[0]: s.heads.append(tuple(s.cur)); s.cur=None
        if t=="title": s.intitle=False
        if t=="script" and s.inld: s.ld.append(s.buf); s.inld=False
    def handle_data(s, d):
        if s.cur: s.cur[1]+=d
        if s.intitle: s.title+=d
        if s.inld: s.buf+=d
p=P(); p.feed(src)
meta={ (a.get("name") or a.get("property")): a.get("content") for t,a,_ in p.tags if t=="meta" and (a.get("name") or a.get("property"))}
def chk(ok, msg, warn=False): (None if ok else (warns if warn else fails).append(msg))
# head
chk(p.title.strip(), "no <title>"); chk(len(p.title)<=60, f"title {len(p.title)} chars > 60", True)
d=meta.get("description") or ""; chk(d, "no meta description"); chk(len(d)<=160, f"meta description {len(d)} chars > 160", True)
for k in ("og:title","og:description","og:image","og:url","og:type","og:image:alt","twitter:card"): chk(meta.get(k), f"missing {k}", k=="og:image:alt")
canon=[a.get("href") for t,a,_ in p.tags if t=="link" and a.get("rel")=="canonical"]; chk(len(canon)==1, f"canonical count {len(canon)}")
chk(meta.get("og:url")==(canon or [None])[0], "og:url != canonical")
html_tag=[a for t,a,_ in p.tags if t=="html"]; chk(html_tag and html_tag[0].get("lang"), "no <html lang>")
vp=meta.get("viewport",""); chk("user-scalable=no" not in vp and "maximum-scale=1" not in vp, "viewport blocks zoom")
# ids
dups={i for i in p.ids if p.ids.count(i)>1}; chk(not dups, f"duplicate ids {dups}")
for t,a,ln in p.tags:
    for attr in ("aria-describedby","aria-labelledby","aria-controls","for"):
        for ref in (a.get(attr) or "").split():
            chk(ref in p.ids, f"line {ln}: {attr}={ref} has no target")
    h=a.get("href") or ""
    if h.startswith("#") and len(h)>1: chk(h[1:] in p.ids, f"line {ln}: href {h} has no target")
    for attr in ("href","src","poster"):
        u=a.get(attr)
        if not u or re.match(r"^([a-z]+:|//|#|data:)", u, re.I): continue
        u=u.replace("./","",1).split("#")[0].split("?")[0]
        if u and not u.endswith("/"): chk(os.path.isfile(os.path.join(root,u)), f"line {ln}: {attr}={u} missing on disk")
    if t=="img": chk("alt" in a, f"line {ln}: img without alt"); chk(a.get("width") and a.get("height"), f"line {ln}: img without width/height", True)
    chk(int(a.get("tabindex") or 0)<=0, f"line {ln}: positive tabindex changes the focus order")
    if t=="a" and a.get("target")=="_blank": chk("noopener" in (a.get("rel") or ""), f"line {ln}: target=_blank without noopener")
    if t in ("video",) and "autoplay" in a: chk("muted" in a, f"line {ln}: autoplay video not muted")
# shortcut keys: the symbol is hidden from screen readers and a spoken name sits beside it
for m in re.finditer(r"<kbd>(.*?)</kbd>", src, re.S):
    k=m.group(1); chk(re.fullmatch(r'<span aria-hidden="true">[^<]+</span><span class="sr">[^<]+</span>', k), f"<kbd> without a spoken name: {k[:40]}")
# headings
levels=[int(h[0][1]) for h in p.heads]; chk(levels.count(1)==1, f"h1 count {levels.count(1)}")
for (a_,b_) in zip(levels, levels[1:]): chk(b_<=a_+1, f"heading skips h{a_}->h{b_}")
# landmarks
names=[t for t,_,_ in p.tags]
for lm in ("header","nav","main","footer"): chk(lm in names, f"no <{lm}>")
chk(names.count("main")==1, "main count != 1")
chk(any(t=="a" and (a.get("href") or "")=="#main" for t,a,_ in p.tags), "no skip link", True)
# JSON-LD
for blk in p.ld:
    try: j=json.loads(blk)
    except Exception as e: fails.append(f"JSON-LD does not parse: {e}"); continue
    g=j.get("@graph",[j]); types=[n.get("@type") for n in g]
    sa=[n for n in g if n.get("@type")=="SoftwareApplication"]
    for n in sa:
        for k in ("name","operatingSystem","applicationCategory","offers"): chk(n.get(k), f"SoftwareApplication missing {k}")
        chk(n.get("image") or n.get("screenshot"), "SoftwareApplication has no image/screenshot", True)
# robots + sitemap
rb=open(os.path.join(root,"robots.txt")).read(); chk("Sitemap:" in rb, "robots.txt has no Sitemap line"); chk(not re.search(r"^Disallow:\s*/\s*$", rb, re.M), "robots disallows all")
sm=ET.parse(os.path.join(root,"sitemap.xml")).getroot(); locs=[e.text for e in sm.iter("{http://www.sitemaps.org/schemas/sitemap/0.9}loc")]
chk(canon and canon[0] in locs, "canonical not in sitemap")
print(f"title: {p.title!r} ({len(p.title)})\ndescription: {len(d)} chars\nheadings: " + " | ".join(f"{h[0]}:{h[1].strip()}" for h in p.heads))
for w in warns: print("WARN", w)
for f in fails: print("FAIL", f)
print(f"{len(fails)} fail, {len(warns)} warn"); sys.exit(1 if fails else 0)
