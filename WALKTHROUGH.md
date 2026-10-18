# Walkthrough of philoserf.com

## Overview

This repository builds [philoserf.com](https://philoserf.com/), Mark Ayers's essays, as a static Hugo site served by a Cloudflare Worker. There is no theme: every template is in `layouts/`, every stylesheet in `static/`. There is also no application code beyond the eleven lines of `worker.js`.

Two kinds of content pass through it. **Posts** (`content/posts/*.md`) arrive from the `obsidian-publisher` plugin as pull requests and are read-only here. **Structural pages** (`content/*.md`: home, About, Now, Uses, the two book lists) are edited by hand. Many posts are delivered with a future `date`. Hugo leaves them out of the build until that date passes, and a daily rebuild is what makes them appear.

There are three entry points:

1. **A push to any branch.** Cloudflare Workers Builds runs `wrangler.jsonc`'s `build.command`, then `wrangler deploy` on `main` or `wrangler versions upload` elsewhere.
2. **The daily Cron Trigger.** `worker.js`'s `scheduled` handler POSTs the Worker's deploy hook, which starts entry point 1 against `main`.
3. **A request to philoserf.com.** It is served from the built `public/` directory, with `worker.js`'s `fetch` handler as the fallback.

Locally, `Taskfile.yml` wraps Hugo for development (`task dev`, `task check`, `task build`), and `task deploy` runs entry point 1 from a Mac.

For why the system is shaped this way, see [THEORY.md](./THEORY.md). This document follows how it runs.

## Architecture

```text
wrangler.jsonc     the build command, the Worker, its cron and its domain
worker.js          the Worker's only code: cron → deploy hook; fetch → assets
hugo.yaml          site config: dates, identity params, menus, output formats
content/           _index.md + five structural pages (hand-edited)
content/posts/     188 posts (publisher output, read-only)
layouts/
  _default/        baseof.html (the page shell), single.html, list.html
  index.html       the home page
  index.*.{txt,webmanifest,vcf}   extra home-page outputs
  robots.txt, 404.html
  partials/        description, resolve-pagerefs, motto, math, mermaid
  shortcodes/      callout, mermaid (publisher contract), latin-motto (local)
archetypes/        default.md (pages), posts.md (posts)
assets/css/        style.css, callout.css (fingerprinted by Hugo)
static/            _headers, icons, og-image.png
Taskfile.yml       local tasks; Brewfile for the local toolchain
```

Data flows one way. The publisher writes Markdown into `content/posts/`, and a person edits `content/*.md` and `hugo.yaml`. Hugo combines content, config and templates into `public/`. Wrangler uploads `public/` as the Worker's static assets. Nothing at request time reads content or config. The Worker serves files that were fixed at build time, which is why time only moves forward when something triggers a build.

## Core walkthrough

### 1. The build: `wrangler.jsonc`

Every deploy, whether from Workers Builds or `task deploy`, starts with one shell command.

`wrangler.jsonc` — `build`

```jsonc
  "build": {
    "command": "{ [ \"$(git rev-parse --is-shallow-repository)\" = false ] || git fetch --unshallow --quiet; } && hugo --buildFuture -D --renderToMemory --gc --panicOnWarning && rm -rf public && hugo --gc --minify --panicOnWarning",
  },
```

It runs four steps, each gated on the one before by `&&`:

1. **Unshallow.** Workers Builds clones with shallow history. Post dates come from git (section 3), and with one commit visible every post would carry the head commit's date. The brace group fetches full history, and a failed fetch fails the build.
2. **Validate.** `--buildFuture -D` brings future-dated posts and drafts into the build, and `--renderToMemory` writes nothing. A queued post that breaks a template fails the PR that delivers it, not the cron build on its release day.
3. **Clean.** Hugo never deletes stale files from `public/`, so the directory is removed.
4. **Build.** The live page set is rendered, minified, into `public/`.

Both Hugo passes use `--panicOnWarning`, which turns any warning into a failure. The two passes differ by exactly the queued posts. This transcript is from a run on 2026-10-13, filtered to the summary rows:

```text
$ hugo --buildFuture -D --renderToMemory --gc --panicOnWarning
 Pages            │ 203
 Static files     │   8
 Aliases          │   4
$ hugo --renderToMemory --gc --panicOnWarning
 Pages            │ 174
 Static files     │   8
 Aliases          │   4
```

The other 29 pages are posts dated after the build. Hugo takes its version from the Workers Builds variable `HUGO_VERSION=latest`, which is set in the dashboard rather than in this repository. The README's "Cloudflare settings" section lists everything that lives only in Cloudflare.

The rest of `wrangler.jsonc` describes the Worker that deploys the result:

`wrangler.jsonc` — `assets`, `triggers`, `routes`

```jsonc
  "main": "./worker.js",
  "assets": {
    "directory": "./public",
    "binding": "ASSETS",
    "not_found_handling": "404-page",
  },
  // Daily 09:00 UTC (05:00 Eastern in summer, 04:00 in winter): rebuild so
  // future-dated posts go live. DEPLOY_HOOK is a secret: see the README.
  "triggers": { "crons": ["0 9 * * *"] },
  // The custom domain is the only address: no workers.dev, no preview URLs.
  "workers_dev": false,
  "preview_urls": false,
  "routes": [{ "pattern": "philoserf.com", "custom_domain": true }],
```

`assets.directory` uploads `public/` alongside the script. `not_found_handling: "404-page"` makes Hugo's `404.html` the answer for paths with no file.

### 2. The Worker: `worker.js`

`worker.js` — `default`

```js
export default {
  fetch: (request, env) => env.ASSETS.fetch(request),

  async scheduled(controller, env) {
    const response = await fetch(env.DEPLOY_HOOK, { method: "POST" });
    if (!response.ok)
      throw new Error(`deploy hook answered ${response.status}`);
  },
};
```

Requests that match a file in `public/` are served before the script runs. `fetch` handles only the rest, and it hands each one straight back to asset serving, which answers with the 404 page. `scheduled` runs on the cron and POSTs the deploy hook, a Workers Builds URL stored as the secret `DEPLOY_HOOK`. Workers Builds then runs section 1 against `main`. The hook's response says only that the build was accepted. If the build fails, the previous deployment keeps serving, and the failure is visible only in the Workers Builds dashboard.

### 3. Configuration: `hugo.yaml`

Hugo reads `hugo.yaml` before anything else. The top of the file controls dates:

`hugo.yaml` — top level

```yaml
enableGitInfo: true
# A hand-set lastmod beats the git date: structural pages set lastmod when their
# content changes, while posts omit it and fall back to the last commit.
frontmatter:
  lastmod: [lastmod, ":git", date, publishDate]
enableRobotsTXT: true
taxonomies: {} # intentionally empty to disable tags and categories
```

`enableGitInfo` lets `:git`, the date of the last commit that touched a file, stand in for `lastmod`. The publisher strips `lastmod` from every post, so posts always take the git date. Structural pages set `lastmod` by hand, and it comes first in the chain. `date` uses Hugo's default chain, which ends in `lastmod`, so a structural page's `.Date` is its `lastmod`. The templates in section 5 have to allow for that. `taxonomies: {}` turns off tag and category pages.

`params` holds the author's identity, which the templates read from many places: `author`, `email`, `motto`, `description`, `themeColor`, the vCard's `contact` block, and `social`. `params.home` holds the home page's curated lists:

`hugo.yaml` — `params.home`

```yaml
  home:
    headline: "Uncompressed public thinking"
    startHereIntro: "Essays that say what the rest is trying to do."
    featured:
      - pageRef: /posts/agency-without-a-self-or-free-will
      - pageRef: /posts/moral-circles-contract-under-scarcity-and-threat
```

`menus.main` defines the four navigation links: About, Now, Uses, Posts. Each carries a `params.description`, and Posts also carries `llmsSection: writing`, which `llms.txt` reads (section 8). The last three blocks register extra home-page outputs:

`hugo.yaml` — `outputFormats.llms`, `outputs`

```yaml
outputFormats:
  llms:
    name: llms
    mediaType: text/plain
    baseName: llms
    isPlainText: true
    notAlternative: true
```

```yaml
outputs:
  home:
    - html
    - rss
    - llms
    - manifest
    - vcard
```

`manifest` and `vcard` are declared the same way, on custom `mediaTypes` (`application/manifest+json` and `text/vcard`). `notAlternative: true` keeps them out of the `<link rel="alternate">` tags Hugo would otherwise put in the page head.

### 4. Content

A post as the publisher delivers it:

`content/posts/how-business-is-done-as-a-rhetorical-defense.md` — front matter

```markdown
---
title: How business is done as a rhetorical defense
description: Examines the phrase "it's how business is done" as a test for distinguishing fair market conventions from scams, using real estate commissions, Enron, and drug pricing as cases.
date: 2026-10-13
---
```

Every post has those three fields and nothing else, except three that add `math: true`. The publisher strips everything else from the vault note. Hugo's default rule turns the filename into the URL: `/posts/how-business-is-done-as-a-rhetorical-defense/`. The `date` has no time, and `hugo.yaml` sets `timeZone: America/Detroit`, so Hugo reads it as midnight Eastern.

A structural page:

`content/now.md` — front matter

```markdown
---
title: Now
eyebrow: "Currently"
description: "Where I am, what I'm reading, what I'm focused on, and what I'm looking forward to. Updated when reality changes."
lastmod: 2026-10-04
showUpdated: true
aliases:
  - /posts/now/
---
```

`eyebrow` is the small label above the title. `showUpdated` asks `single.html` for an "Updated" line. `aliases` makes Hugo write a redirect page at the old `/posts/now/` URL. Those redirects are the four "Aliases" in the build transcript: one on `_index.md` and three on structural pages.

### 5. The page shell: `layouts/_default/baseof.html`

Every HTML page renders through `baseof.html`. Templates fill its `head`, `main-class` and `main` blocks. The head begins by working out the title and description:

`layouts/_default/baseof.html` — `<head>`

```go-html-template
  {{ $pageTitle := cond .IsHome .Site.Title .Title }}
  <title>{{ $pageTitle }}{{ if not .IsHome }} | {{ .Site.Title }}{{ end }}</title>

  {{ $description := partial "description.html" . }}
  {{ $ogImage := "og-image.png" | absURL }}
  <meta name="description" content="{{ $description }}">
  <meta name="author" content="{{ .Site.Params.author }}">
```

The description comes from a partial that every template shares, so the same text appears in the meta tags, on the home page cards, in the archive rows and in JSON-LD:

`layouts/partials/description.html` — whole file

```go-html-template
{{- $d := or .Description (.Summary | plainify | htmlUnescape | chomp) .Site.Params.description -}}
{{- return ($d | replaceRE "\\s+" " ") -}}
```

`or` returns the first value that isn't empty: the front-matter description, then Hugo's auto-summary as plain text, then the site description. No page renders without one.

Open Graph and article metadata come next:

`layouts/_default/baseof.html` — `<head>`

```go-html-template
  <meta property="og:type" content="{{ if $isPost }}article{{ else }}website{{ end }}">
  <meta property="og:image" content="{{ $ogImage }}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  {{ if and $isPost (not .Date.IsZero) }}
  <meta property="article:published_time" content="{{ .Date.Format "2006-01-02T15:04:05Z07:00" }}">
  {{ if .Lastmod.After .Date }}<meta property="article:modified_time" content="{{ .Lastmod.Format "2006-01-02T15:04:05Z07:00" }}">{{ end }}
  <meta property="article:author" content="{{ .Site.Params.author }}">
  {{ end }}
```

`$isPost`, set earlier in the head as `and .IsPage (eq .Section "posts")`, is how templates recognize a post. Structural pages have a `.Date` that is really their `lastmod` (section 3), so they and the `/posts/` archive get `og:type` `website` and no `article:*` metas. `article:modified_time` appears only when a post changed after its publish date: one delivered ahead of its date has a `Lastmod` (the delivery commit) before its `Date`.

`theme-color` metas read `params.themeColor.light` and `.dark`. They must match `--background-color` in `assets/css/style.css`, and the stylesheet says so:

`assets/css/style.css` — `:root`

```css
  /* Color — alpine: snow, slate, and denim. The background hexes are
     mirrored outside CSS via params.themeColor in hugo.yaml (theme-color
     metas, webmanifest) — keep them in sync when retinting. */
```

The head closes by loading stylesheets and scripts, three of them only when needed:

`layouts/_default/baseof.html` — `<head>`

```go-html-template
  {{ $style := resources.Get "css/style.css" | minify | fingerprint }}
  <link rel="stylesheet" href="{{ $style.RelPermalink }}" integrity="{{ $style.Data.Integrity }}">
  {{ if .HasShortcode "callout" }}{{ $callout := resources.Get "css/callout.css" | minify | fingerprint }}<link rel="stylesheet" href="{{ $callout.RelPermalink }}" integrity="{{ $callout.Data.Integrity }}">{{ end }}
  {{ partial "math.html" . }}
  {{ partial "mermaid.html" . }}

  {{ block "head" . }}{{ end }}
```

Section 9 covers those partials. `{{ block "head" . }}` is where `single.html` and `index.html` add JSON-LD. The body is a nav built from `menus.main`, the `main` element, and a footer:

`layouts/_default/baseof.html` — `<body>`

```go-html-template
  <main id="main" class="{{ block "main-class" . }}prose{{ end }}">{{ block "main" . }}{{ end }}</main>
```

The class defaults to `prose`. The home page overrides it with `home-main` and the archive with `archive`, and `style.css` sets each layout's width and grid from that class. The footer prints `© {since}–{current year}`, the license, and an RSS link.

### 6. Posts and structural pages: `layouts/_default/single.html`

Every regular page, post or structural, renders through `single.html`. Its `head` block builds JSON-LD:

`layouts/_default/single.html` — `define "head"`

```go-html-template
{{ $isPost := and .IsPage (eq .Section "posts") }}
{{ $type := cond $isPost "BlogPosting" "WebPage" }}
{{ $desc := partial "description.html" . }}
{{ $author := dict "@type" "Person" "name" .Site.Params.author "email" .Site.Params.email }}
{{ $publisher := dict "@type" "Person" "name" .Site.Params.author }}
```

```go-html-template
{{ if and $isPost (not .Date.IsZero) }}{{ $jsonld = merge $jsonld (dict "datePublished" (.Date.Format "2006-01-02")) }}{{ end }}
{{ if and (not .Lastmod.IsZero) (or (not $isPost) (.Lastmod.After .Date)) }}{{ $jsonld = merge $jsonld (dict "dateModified" (.Lastmod.Format "2006-01-02")) }}{{ end }}
<script type="application/ld+json">{{ $jsonld | jsonify (dict "indent" "  ") | safeJS }}</script>
```

Dates are added only when present, using `merge`. Only posts get `datePublished`. A structural page always gets `dateModified`, since its `lastmod` is set by hand; a post gets it only when `Lastmod` is after `Date`, for the same reason as `article:modified_time`.

The `main` block draws the article header differently for each kind of page:

`layouts/_default/single.html` — `define "main"`

```go-html-template
      {{ if eq .Section "posts" }}<p class="eyebrow">Post</p>{{ else }}{{ with .Params.eyebrow }}<p class="eyebrow">{{ . }}</p>{{ end }}{{ end }}
      <h1>{{ .Title }}</h1>
      {{ with .Description }}<p class="deck">{{ . }}</p>{{ end }}
      {{ if eq .Section "posts" }}
        {{ if not .Date.IsZero }}<time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "January 2, 2006" }}</time>{{ end }}
      {{ else if and .Params.showUpdated (not .Lastmod.IsZero) }}
        {{/* Structural pages have no publish date; Hugo's date falls back to lastmod, so opt in to an "Updated" line instead */}}
        <time datetime="{{ .Lastmod.Format "2006-01-02" }}">Updated {{ .Lastmod.Format "January 2, 2006" }}</time>
      {{ end }}
```

A post gets a fixed "Post" eyebrow and its publish date. A structural page gets its own `eyebrow` and, if it sets `showUpdated`, an "Updated" date. Below the content, posts get a "Continue reading" link to `/posts/`.

### 7. The home page and the archive

`layouts/index.html` adds two JSON-LD objects, `WebSite` and `Person`, then works out which posts to show:

`layouts/index.html` — `define "main"`

```go-html-template
{{ $posts := where .Site.RegularPages "Section" "posts" }}
{{ $posts = $posts.ByDate.Reverse }}
{{ $featured := slice }}
{{ with .Site.Params.home.featured }}
  {{ $featured = partial "resolve-pagerefs.html" (dict "refs" . "what" "featured") }}
{{ else }}
  {{ range first 1 $posts }}
    {{ $featured = $featured | append (dict "page" . "note" .Description) }}
  {{ end }}
{{ end }}
{{ $featuredLinks := slice }}
{{ range $featured }}{{ $featuredLinks = $featuredLinks | append .page.RelPermalink }}{{ end }}
{{ $recent := where $posts "RelPermalink" "not in" $featuredLinks | first 4 }}
```

Featured posts come from `params.home.featured`, or the newest post when that list is empty. Recent is the four newest posts that aren't featured, so no title appears twice. "Start here" resolves `params.home.startHere` through the same partial:

`layouts/partials/resolve-pagerefs.html` — whole file, after its comment

```go-html-template
{{- $what := .what -}}
{{- $resolved := slice -}}
{{- range .refs -}}
  {{- $page := site.GetPage .pageRef -}}
  {{- if not $page }}{{ errorf "homepage %s page not found: %s" $what .pageRef }}{{ end -}}
  {{- $resolved = $resolved | append (dict "page" $page "note" (.note | default (partial "description.html" $page))) -}}
{{- end -}}
{{- return $resolved -}}
```

`errorf` fails the build on a ref that doesn't resolve. That covers a post that was renamed or deleted. It also covers a post whose date hasn't arrived: the live pass of `build.command` leaves that post out, so `GetPage` finds nothing, even though the validate pass found it. An entry may carry its own `note`. None does today, so every card uses the post's description.

The page ends with a motto section that renders `partials/motto.html`.

`layouts/_default/list.html` renders `/posts/`. It is the only list page, because `posts` is the only section and taxonomies are off:

`layouts/_default/list.html` — `define "main"`

```go-html-template
{{ $pages := .Pages.ByDate.Reverse }}
{{ $months := $pages.GroupByDate "2006-01" }}
  <p class="eyebrow">Published Monday, Wednesday, and Friday</p>
  <h1>Posts</h1>
```

A navigation strip groups months under years and links to `#month-YYYY-MM` anchors. One `<section>` per month then lists each post's day, title and description. There is no pagination: every live post is on one page. The heading and the publishing-schedule line are hard-coded, so this template is the posts archive under the default name.

`layouts/404.html` fills `main` with a short message and links to home and posts. `not_found_handling` in `wrangler.jsonc` serves it.

### 8. The other home-page outputs

Each format listed under `outputs.home` renders the home page through its own template. All four of these files draw on `params`, so a change to identity in `hugo.yaml` updates every one of them.

`layouts/index.llms.txt` lists the menu, then the latest posts:

`layouts/index.llms.txt` — Writing section

```go-text-template
## Writing

{{- range .Site.Menus.main }}
{{- if eq .Params.llmsSection "writing" }}
- [{{ .Name }}]({{ .URL | absURL }}): {{ .Params.description }}
{{- end }}
{{- end }}
{{- range first 20 (where .Site.RegularPages "Section" "posts") }}
- [{{ .Title }}]({{ .Permalink }}){{ with .Date }} — {{ .Format "2006-01-02" }}{{ end }}
{{- end }}
```

Menu entries without `llmsSection: writing` go under "Pages" instead, and "Feeds" points at `index.xml` and `sitemap.xml`.

`layouts/index.manifest.webmanifest` builds a `dict` and passes it to `jsonify`, writing `site.webmanifest` with the three Android icons and `themeColor.light`. `layouts/index.vcard.vcf` writes a vCard 3.0 from `params.contact`, `params.social` and the motto:

`layouts/index.vcard.vcf` — top and tail

```go-text-template
{{- /* REV uses build time: vcard fields come from site config, which
     .Site.Lastmod (content-derived) does not track. */ -}}
{{- $c := .Site.Params.contact -}}
{{- $s := .Site.Params.social -}}
{{- $a := $c.address -}}
```

```go-text-template
NOTE:{{ .Site.Params.motto }}
REV:{{ now.UTC.Format "20060102T150405Z" }}
```

The card includes a real home address, phone number and birthday on purpose. Because of the daily rebuild, `REV` changes every day.

`layouts/robots.txt` is rendered because `enableRobotsTXT: true`:

`layouts/robots.txt` — whole file

```go-text-template
User-agent: *
Content-signal: search=yes, ai-input=yes, ai-train=yes, use=full
Allow: /

Sitemap: {{ "sitemap.xml" | absURL }}
```

The RSS feed (`index.xml`) and `sitemap.xml` have their own templates, `layouts/index.rss.xml` and `layouts/sitemap.xml`, each Hugo's built-in one narrowed. The feed lists posts only. A sitemap `<lastmod>` is the later of `Lastmod` and `Date`, so a queued post is never dated before it was published.

### 9. Shortcodes and assets that load on demand

Three shortcodes exist. `callout` and `mermaid` are copied from the publisher's reference templates in `obsidian-publisher/hugo-shortcodes/`, because the publisher writes `{{< callout … >}}` for Obsidian callouts and `{{< mermaid >}}` for Mermaid code blocks. No post uses either today. Without these templates, a note containing one would fail the build.

`layouts/shortcodes/callout.html` — after its comment

```go-html-template
{{- $type := lower (.Get 0) -}}
{{- $title := "" -}}
{{- if gt (len .Params) 1 -}}
  {{- $title = .Get 1 -}}
{{- end -}}
<div class="callout callout-{{ $type }}">
  {{- with $title }}<div class="callout-title">{{ . }}</div>{{ end -}}
  <div class="callout-body">
    {{ .Inner | markdownify }}
  </div>
</div>
```

The callout type arrives exactly as Obsidian spells it and becomes a `callout-<type>` class. `assets/css/callout.css` colors those classes, in light and dark, and `baseof.html` loads it only when the page uses the shortcode. `layouts/shortcodes/mermaid.html` HTML-escapes its body into a `<pre class="mermaid">`, and this partial loads the library:

`layouts/partials/mermaid.html` — whole file

```go-html-template
{{- if .HasShortcode "mermaid" -}}
<script defer src="https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.min.js" integrity="sha384-T/0lMUdJpd2S1ZHtRiofG3htU3xPCrFVeAQ1UUE2TJwlEJSV5NUwn30kP28n238E" crossorigin="anonymous" onload="mermaid.initialize({ startOnLoad: true, theme: 'default' });"></script>
{{- end -}}
```

The version is pinned with an SRI hash, so updating Mermaid means recomputing `integrity`. `layouts/partials/math.html` follows the same pattern for KaTeX 0.16.11 (stylesheet, script, auto-render with `$…$` and `$$…$$` delimiters):

`layouts/partials/math.html` — guard

```go-html-template
{{- if .Params.math -}}
```

The three posts with `math: true` load it, and no other page does.

The third shortcode, `latin-motto`, belongs to this site. About uses it, and it wraps the shared partial:

`layouts/partials/motto.html` — whole file

```go-html-template
{{- /* The Latin motto, sourced from params.motto so the homepage, the
     latin-motto shortcode, and the vCard share one copy. */ -}}
<p>{{ site.Params.motto }}</p>
```

### 10. Archetypes

`hugo new` scaffolds front matter from `archetypes/`. Pages get `lastmod`, posts get `date`:

`archetypes/default.md` — whole file

```markdown
---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
lastmod: {{ now.Format "2006-01-02" }}
draft: true
---
```

`archetypes/posts.md` is the same with `date:` in place of `lastmod:`. In practice only `default.md` sees use, through `task new -- <page>.md`. Posts come from the publisher, and `task new:post` would write into the directory the publisher owns.

### 11. Local tasks: `Taskfile.yml`

`task dev` runs `hugo server -D -F`, which includes drafts and future posts. `task check` is the strict check:

`Taskfile.yml` — `check`

```yaml
  check:
    desc: Run build.command's validate and strict passes in memory
    deps: [setup]
    cmds:
      # The two Hugo passes of wrangler.jsonc's build.command, without writing public/.
      - hugo --buildFuture -D --renderToMemory --gc --panicOnWarning
      - hugo --gc --minify --renderToMemory --panicOnWarning
```

Those are the two Hugo passes from `build.command`, writing nothing, so a queued post that breaks a template fails here before it fails a deploy. `task build` runs the live pass into `public/`, clearing it first:

`Taskfile.yml` — `build`

```yaml
  build:
    desc: Build site for production
    deps: [setup]
    cmds:
      # No sources/generates: the output also depends on the clock (future-dated
      # posts) and git history (enableGitInfo). rm -rf because Hugo never prunes public/.
      - rm -rf public
      - hugo --gc --minify --panicOnWarning
```

Most tasks depend on `setup`, which runs `brew bundle` against the repo's `Brewfile` (Hugo, Task, Prettier, gh, the image tools, lychee), and is skipped while the Brewfile's checksum is unchanged. `task links` runs lychee over the HTML in `public/`, checking external links and `#fragment` anchors, and expects `task build` to have run first. `task deploy` loads a Cloudflare API token from the macOS keychain if one is there, then runs `bunx wrangler deploy`, which runs `build.command` before uploading. `task format` runs Prettier. `.prettierignore` excludes `layouts/` and `archetypes/` (Prettier can't parse Hugo templates) and `content/posts/` (publisher output). `task optimize-images` compresses PNGs and JPEGs under `static/`.
