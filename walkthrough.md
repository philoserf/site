# philoserf.com Walkthrough

_2026-05-26T15:24:18Z by Showboat 0.6.1_
<!-- showboat-id: 2898901e-8ca2-42a3-9921-bfd6d7e0bd85 -->

## Overview

`philoserf.com` is Mark Ayers' personal site — semi-weekly essays on technology, strategy, and personal development. The stack is intentionally small:

- **Hugo Extended** generates the site (no theme, hand-rolled `layouts/`).
- **Task** drives every build, dev, and check command.
- **GitHub Actions** publishes to GitHub Pages on push to `main` and once a day.
- Most posts under `content/posts/` are _output_ — written in an Obsidian vault and emitted by the `obsidian-publisher` plugin. Only `content/_index.md`, `about.md`, `now.md`, and `uses.md` are safely edited here.

This walkthrough follows the build outward: config → task runner → layouts → partials → custom output formats → shortcodes → archetypes → deploy.

## Repository layout

The tree below shows just the source-of-truth directories. `public/` and `resources/` are gitignored build outputs.

```bash
find . -maxdepth 2 -type d -not -path './.git*' -not -path './public*' -not -path './resources*' -not -path './node_modules*' -not -path './.task*' -not -path './.issues*' | sort
```

```output
.
./archetypes
./content
./content/posts
./layouts
./layouts/_default
./layouts/partials
./layouts/shortcodes
./static
```

## Configuration: `hugo.yaml`

The config does three load-bearing things:

1. **Site identity & params** — author, email, motto, contact details used by the vCard and JSON-LD generators.
2. **Taxonomies disabled** — `taxonomies: {}` explicitly turns off tags/categories.
3. **Custom output formats** — the homepage renders five outputs: `html`, `rss`, `llms`, `manifest`, `vcard`. Each non-HTML format has its own template under `layouts/index.<name>.<ext>`.

`enableGitInfo: true` makes `.Lastmod` fall back to git commit date — so posts can omit `lastmod` without losing the modified-time metadata.

```bash
sed -n '1,12p' hugo.yaml
```

```output
baseURL: https://philoserf.com/
locale: en-us
title: Mark Ayers
enableGitInfo: true
enableRobotsTXT: true
taxonomies: {} # intentionally empty to disable tags and categories
params:
  author: "Mark Ayers"
  since: 2005
  description: "Personal digital presence of Mark Ayers — semi-weekly essays on technology, strategy, and personal development."
  email: "mark@philoserf.com"
  motto: "COGITA·DISCE·NECTE·ENUNTIA"
```

```bash
sed -n '59,91p' hugo.yaml
```

```output
mediaTypes:
  application/manifest+json:
    suffixes: [webmanifest]
  text/vcard:
    suffixes: [vcf]

outputFormats:
  llms:
    name: llms
    mediaType: text/plain
    baseName: llms
    isPlainText: true
    notAlternative: true
  manifest:
    name: manifest
    mediaType: application/manifest+json
    baseName: site
    isPlainText: true
    notAlternative: true
  vcard:
    name: vcard
    mediaType: text/vcard
    baseName: vcard
    isPlainText: true
    notAlternative: true

outputs:
  home:
    - html
    - rss
    - llms
    - manifest
    - vcard
```

## Task runner: `taskfile.yml`

Every command goes through Task. Three to watch:

- `task dev` — `hugo server -D -F --disableFastRender` (drafts on, future content on).
- `task build` — production minified build with `HUGO_ENV=production`.
- `task check` — `hugo --renderToMemory --panicOnWarning`. This is the **only enforced quality gate** locally: any Hugo warning (missing ref, undefined shortcode, template error) aborts the build.

The `check` task and the deploy workflow both use `--panicOnWarning`. Local `task build` does not — it's optimized for speed, so silence in `task build` does not imply a clean ship.

```bash
sed -n '24,55p' taskfile.yml
```

```output
  dev:
    desc: Start development server with draft and future content
    deps: [setup]
    cmds:
      - hugo server -D -F --disableFastRender --baseURL http://localhost:1313/

  build:
    desc: Build site for production
    deps: [setup]
    sources:
      - hugo.yaml
      - content/**/*
      - static/**/*
      - layouts/**/*
      - archetypes/**/*
    generates:
      - public/**/*
    cmds:
      - hugo --minify
    env:
      HUGO_ENV: production

  clean:
    desc: Clean up generated files
    cmds:
      - rm -rf public resources

  check:
    desc: Check content and links
    deps: [setup]
    cmds:
      - hugo --renderToMemory --panicOnWarning
```

## Layouts: the base template

Hugo resolves templates by section + kind. Every HTML page extends `layouts/_default/baseof.html`, which defines two blocks (`head` and `main`) for child templates to override.

The base template handles:

- **Document head** — title, canonical, OpenGraph, Twitter card, theme-color (light + dark), favicon, PWA manifest link, RSS alternate link.
- **Conditional assets** — KaTeX loads only when `.Params.math` is set (via `partials/math.html`). Mermaid loads only when a page contains a `mermaid` shortcode (`{{ if .HasShortcode "mermaid" }}`). This is the conditional-load pattern worth remembering.
- **Skip link + primary nav** — built from `.Site.Menus.main`, with an `active` class via `.IsMenuCurrent` / `.HasMenuCurrent`.
- **Footer** — copyright range built from `Site.Params.since` to the current year.

```bash
sed -n '1,12p' layouts/_default/baseof.html
```

```output
<!DOCTYPE html>
<html lang="{{ .Site.Language.Locale | default "en" }}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} | {{ .Site.Title }}{{ end }}</title>

  {{ $description := partial "description.html" . }}
  <meta name="description" content="{{ $description }}">
  <meta name="author" content="{{ .Site.Params.author }}">

  <link rel="canonical" href="{{ .Permalink }}">
```

```bash
sed -n '44,52p' layouts/_default/baseof.html
```

```output
  <link rel="stylesheet" href="{{ "style.css" | relURL }}">
  <link rel="stylesheet" href="{{ "callout.css" | relURL }}">
  {{ partial "math.html" . }}
  {{ if .HasShortcode "mermaid" }}<script type="module" src="{{ "mermaid.js" | relURL }}"></script>{{ end }}

  {{ block "head" . }}{{ end }}
</head>
<body>
  <a class="skip-link" href="#main">Skip to content</a>
```

## Layouts: page kinds

Three templates fill in `baseof.html`'s blocks.

### `_default/single.html` — individual page or post

Defines both blocks. `head` emits JSON-LD: `BlogPosting` when the section is `posts`, otherwise `WebPage`. `main` renders the article with title, optional `<time>`, and content.

```bash
sed -n '1,21p' layouts/_default/single.html
```

```output
{{ define "head" }}
{{ $type := cond (eq .Section "posts") "BlogPosting" "WebPage" }}
{{ $desc := partial "description.html" . }}
{{ $author := dict "@type" "Person" "name" .Site.Params.author "email" .Site.Params.email }}
{{ $publisher := dict "@type" "Person" "name" .Site.Params.author }}
{{ $jsonld := dict
  "@context" "https://schema.org"
  "@type" $type
  "headline" .Title
  "name" .Title
  "url" .Permalink
  "mainEntityOfPage" .Permalink
  "description" $desc
  "author" $author
  "publisher" $publisher
  "inLanguage" (.Site.Language.Locale | default "en")
}}
{{ if not .Date.IsZero }}{{ $jsonld = merge $jsonld (dict "datePublished" (.Date.Format "2006-01-02")) }}{{ end }}
{{ if not .Lastmod.IsZero }}{{ $jsonld = merge $jsonld (dict "dateModified" (.Lastmod.Format "2006-01-02")) }}{{ end }}
<script type="application/ld+json">{{ $jsonld | jsonify (dict "indent" "  ") | safeJS }}</script>
{{ end }}
```

### `_default/list.html` — section index (e.g. `/posts/`)

Paginated post list. Each item shows the date and title; pagination is delegated to a partial.

```bash
cat layouts/_default/list.html
```

```output
{{ define "main" }}
<main id="main">
  <h1>{{ .Title }}</h1>
  {{ if .Content }}<div class="list-intro">{{ .Content }}</div>{{ end }}
  <ul class="posts">
    {{ range .Paginator.Pages }}
    <li>
      <time class="date" datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "January 2, 2006" }}</time>
      <a class="title" href="{{ .RelPermalink }}">{{ .Title }}</a>
    </li>
    {{ end }}
  </ul>
  {{ partial "pagination.html" . }}
</main>
{{ end }}
```

### `layouts/index.html` — the home page

Different schema.org payload: a `Person` document **and** a `WebSite` document, both as JSON-LD. The `main` block just renders the homepage markdown.

```bash
cat layouts/index.html
```

```output
{{ define "head" }}
{{ $desc := partial "description.html" . }}
{{ $person := dict
  "@context" "https://schema.org"
  "@type" "Person"
  "name" .Site.Params.author
  "email" .Site.Params.email
  "url" .Site.Home.Permalink
}}
{{ $website := dict
  "@context" "https://schema.org"
  "@type" "WebSite"
  "name" .Site.Title
  "url" .Site.Home.Permalink
  "description" $desc
  "inLanguage" (.Site.Language.Locale | default "en")
  "author" (dict "@type" "Person" "name" .Site.Params.author)
}}
<script type="application/ld+json">{{ $website | jsonify (dict "indent" "  ") | safeJS }}</script>
<script type="application/ld+json">{{ $person | jsonify (dict "indent" "  ") | safeJS }}</script>
{{ end }}

{{ define "main" }}
<main id="main">
  <div class="homepage-content">{{ .Content }}</div>
</main>
{{ end }}
```

## Partials

Three tiny partials carry a lot of weight.

### `description.html` — the meta-description fallback chain

Used by every page for `<meta name="description">` and JSON-LD `description`. Cascades through three sources and squashes whitespace.

```bash
cat layouts/partials/description.html
```

```output
{{- $d := or .Description (.Summary | plainify | htmlUnescape | chomp) .Site.Params.description -}}
{{- return ($d | replaceRE "\\s+" " ") -}}
```

### `math.html` — opt-in KaTeX

Loads KaTeX + auto-render only when `.Params.math` (per-page) or `.Site.Params.math` (site-wide) is set. Avoids loading ~80KB on every page.

```bash
cat layouts/partials/math.html
```

```output
{{- if or .Params.math .Site.Params.math -}}
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css" integrity="sha384-nB0miv6/jRmo5UMMR1wu3Gz6NLsoTkbqJghGIsx//Rlm+ZU03BU6SQNC66uf4l5+" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js" integrity="sha384-7zkQWkzuo3B5mTepMUcHkMB5jZaolc2xDwL6VFqjFALcbeS9Ggm/Yr2r3Dy4lfFg" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js" integrity="sha384-43gviWU0YVjaDtb/GhzOouOXtZMP/7XUzwPTstBeZFe/+rCMvRwr4yROQP43s0Xk" crossorigin="anonymous" onload="renderMathInElement(document.body, {delimiters: [{left: '$$', right: '$$', display: true}, {left: '$', right: '$', display: false}, {left: '\\(', right: '\\)', display: false}, {left: '\\[', right: '\\]', display: true}]});"></script>
{{- end -}}
```

### `pagination.html` — sliding window

Implements a 2-wide window around the current page (`max = 5`). Edge cases for first/last pages collapse the window; `«` and `»` First/Last jumps appear only when not already on those pages.

```bash
sed -n '1,16p' layouts/partials/pagination.html
```

```output
{{- $p := .Paginator -}}
{{- $window := 2 -}}
{{- $max := add (mul $window 2) 1 -}}
{{- $start := 1 -}}
{{- $end := $p.TotalPages -}}
{{- if gt $p.TotalPages $max -}}
  {{- if le $p.PageNumber (add $window 1) -}}
    {{- $end = $max -}}
  {{- else if ge $p.PageNumber (sub $p.TotalPages $window) -}}
    {{- $start = add (sub $p.TotalPages $max) 1 -}}
  {{- else -}}
    {{- $start = sub $p.PageNumber $window -}}
    {{- $end = add $p.PageNumber $window -}}
  {{- end -}}
{{- end -}}
{{- if gt $p.TotalPages 1 -}}
```

## Custom output formats from the home page

Four text/JSON deliverables are generated by templating the **home page** under different output formats — they live in `layouts/`, not `static/`. Adding a new one means a new `mediaType`/`outputFormat`/`outputs.home` entry plus a `layouts/index.<name>.<ext>` template.

### `index.llms.txt` — LLM-friendly site index

A minimal markdown index served at `/llms.txt`. Splits the main menu into navigation pages vs. the writing section via `llmsSection: writing` in the menu params, then lists the most recent 20 posts.

```bash
cat layouts/index.llms.txt
```

```output
# {{ .Site.Title }}

> {{ .Site.Params.description }}

Author: {{ .Site.Params.author }} ({{ .Site.Params.email }})
Base URL: {{ .Site.BaseURL }}

## Pages

{{- range .Site.Menus.main }}
{{- if ne .Params.llmsSection "writing" }}
- [{{ .Name }}]({{ .URL | absURL }}): {{ .Params.description }}
{{- end }}
{{- end }}

## Writing

{{- range .Site.Menus.main }}
{{- if eq .Params.llmsSection "writing" }}
- [{{ .Name }}]({{ .URL | absURL }}): {{ .Params.description }}
{{- end }}
{{- end }}
{{- range first 20 (where .Site.RegularPages "Section" "posts") }}
- [{{ .Title }}]({{ .Permalink }}){{ with .Date }} — {{ .Format "2006-01-02" }}{{ end }}
{{- end }}

## Feeds

- [RSS]({{ "index.xml" | absURL }}): Main feed
- [Sitemap]({{ "sitemap.xml" | absURL }}): All URLs
```

### `index.vcard.vcf` — downloadable contact card

VCard 3.0, populated from `Site.Params.contact` and `Site.Params.social`. The `REV:` line is set to the current build time so caches see fresh revisions.

> **Note:** there is an open issue (`.issues/vcard-exposes-home-address-and-phone.md`) flagging that this exposes home address and personal phone publicly.

```bash
sed -n '1,26p' layouts/index.vcard.vcf
```

```output
{{- $c := .Site.Params.contact -}}
{{- $s := .Site.Params.social -}}
{{- $a := $c.address -}}
BEGIN:VCARD
VERSION:3.0
FN:{{ .Site.Params.author }}
N:{{ $c.familyName }};{{ $c.givenName }};;;
NICKNAME:{{ .Site.Params.nickname }}
BDAY:{{ $c.birthday }}
LANG:{{ .Site.Language.Locale | default "en" }}

EMAIL;TYPE=INTERNET:{{ .Site.Params.email }}
TEL;TYPE=CELL:{{ $c.phone }}
ADR;TYPE=HOME:;;{{ $a.street }};{{ $a.city }};{{ $a.region }};{{ $a.postalCode }};{{ $a.country }}
TZ:{{ $c.timezone }}

URL:{{ .Site.BaseURL }}
X-SOCIALPROFILE;type=github:{{ $s.github }}
X-SOCIALPROFILE;type=mastodon:{{ $s.mastodon }}
X-SOCIALPROFILE;type=bluesky:{{ $s.bluesky }}

PHOTO;VALUE=URI:{{ "apple-touch-icon.png" | absURL }}
SOURCE:{{ "vcard.vcf" | absURL }}
NOTE:{{ .Site.Params.motto }}
REV:{{ now.Format "20060102T150405Z" }}
END:VCARD
```

### `index.manifest.webmanifest` — PWA manifest

Builds the manifest as a Go `dict`, then `jsonify`s it. Cleaner than hand-writing JSON in a template.

```bash
cat layouts/index.manifest.webmanifest
```

```output
{{- $manifest := dict
  "name" .Site.Title
  "short_name" .Site.Title
  "description" .Site.Params.description
  "icons" (slice
    (dict "src" "/android-chrome-144x144.png" "sizes" "144x144" "type" "image/png" "purpose" "any maskable")
    (dict "src" "/android-chrome-192x192.png" "sizes" "192x192" "type" "image/png")
    (dict "src" "/android-chrome-512x512.png" "sizes" "512x512" "type" "image/png")
  )
  "background_color" "#ffffff"
  "theme_color" "#ffffff"
  "display" "standalone"
  "start_url" "/"
  "scope" "/"
-}}
{{- $manifest | jsonify (dict "indent" "  ") -}}
```

### `robots.txt`

Not a home-page output format — `enableRobotsTXT: true` in `hugo.yaml` activates Hugo's built-in robots-template lookup, and this file is what it finds.

```bash
cat layouts/robots.txt
```

```output
User-agent: *
Allow: /

Sitemap: {{ "sitemap.xml" | absURL }}
```

## Shortcodes

Three shortcodes under `layouts/shortcodes/`. The latter two are kept in sync with reference templates from the `obsidian-publisher` project.

### `latin-motto` — site mottos

Pure HTML, no parameters. Used on the home page and About page.

```bash
cat layouts/shortcodes/latin-motto.html
```

```output
<div class="latin-motto">
  <p>HOMO·HOMINIS·ESSE</p>
  <p>COGITA·DISCE·NECTE·ENUNTIA</p>
  <p>PERCIPE·STRUE·EFFICE</p>
</div>
```

### `callout` — Obsidian-style admonition

Two positional args — type and optional title — plus inner markdown. The publisher emits this on every Obsidian callout.

```bash
cat layouts/shortcodes/callout.html
```

```output
{{/*
  Callout shortcode. Receives the Obsidian callout type verbatim as the
  first positional arg, and an optional title as the second. Usage:
    {{< callout note "Heads up" >}} body {{< /callout >}}
    {{< callout tldr >}} body {{< /callout >}}
*/}}
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

### `mermaid` — diagrams

Emits a `<pre class="mermaid">` block. The actual rendering happens in `static/mermaid.js`, which is loaded conditionally from `baseof.html` only when `.HasShortcode "mermaid"` is true.

```bash
cat layouts/shortcodes/mermaid.html
```

```output
{{/*
  Mermaid shortcode. Renders inner content as a <pre class="mermaid">
  block. Pair with mermaid.js which initializes Mermaid on page load.
*/}}
<pre class="mermaid">{{ .Inner | htmlEscape }}</pre>
```

```bash
cat static/mermaid.js
```

```output
// Pinned to a specific version for reproducible builds.
// To update: change the version number below and re-deploy.
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.esm.min.mjs";

mermaid.initialize({ startOnLoad: true, theme: "default" });
```

## Archetypes — the load-bearing asymmetry

`task new -- about.md` and `task new:post -- some-title` scaffold front matter from `archetypes/`. The asymmetry between the two is intentional:

- **`default.md`** — `lastmod` only. Structural pages don't have a publication date.
- **`posts.md`** — `date` only. Posts get a publication date; `lastmod` is supplied by `enableGitInfo`.

`single.html` uses `.Date.IsZero` to decide whether to render the `<time>` element and `datePublished` JSON-LD field. If you scaffold a post with the wrong archetype, the date silently disappears from the rendered HTML.

```bash
cat archetypes/default.md
```

```output
---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
lastmod: {{ now.Format "2006-01-02" }}
draft: true
---
```

```bash
cat archetypes/posts.md
```

```output
---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: {{ now.Format "2006-01-02" }}
draft: true
---
```

## Content

Two kinds of content live in `content/`:

- **Structural pages** — `_index.md`, `about.md`, `now.md`, `uses.md`. Safe to edit here.
- **Posts** — everything under `content/posts/`. These are emitted by the `obsidian-publisher` plugin from the notes vault and **overwritten on the next publish**. Editing a post directly is a footgun.

Post count today:

```bash
ls content/posts/*.md | wc -l | tr -d ' '
```

```output
110
```

Sample post front matter — shows the implicit schema (title, description, date) the publisher emits:

```bash
sed -n '1,5p' content/posts/galpins-3-5-training-rule.md
```

```output
---
title: Galpin's 3-5 Training Rule
description: Andy Galpin's 3-5 Rule structures strength workouts around sets, reps, days, and rest all within the 3-5 range.
date: 2023-02-01
---
```

## Deployment: `.github/workflows/deploy.yml`

Build triggers: push to `main`, manual `workflow_dispatch`, and a daily cron at 08:25 UTC (which lets `enableGitInfo`-driven `lastmod` and timestamped outputs like the vCard `REV:` field stay fresh even without commits).

Two key differences vs. local builds:

- The workflow runs `hugo --gc --minify --panicOnWarning` — strict mode. `task build` locally runs `hugo --minify` only.
- `actions/checkout` uses `fetch-depth: 0` so `enableGitInfo` can populate every page's `.Lastmod` from the actual commit history.

Deploy uses the artifact-based Pages flow (`upload-pages-artifact` + `deploy-pages`). No `gh-pages` branch.

```bash
sed -n '1,36p' .github/workflows/deploy.yml
```

```output
name: deploy

on:
  workflow_dispatch:
  push:
    branches: [main]
  schedule:
    - cron: "25 8 * * *"

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages

jobs:
  build:
    if: github.repository == 'philoserf/site'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0 # full history so enableGitInfo populates accurate Lastmod
      - uses: actions/configure-pages@v6
        id: pages
      - uses: peaceiris/actions-hugo@v3 # unpinned: tracks latest like Homebrew
        with:
          extended: true
      - run: hugo --gc --minify --panicOnWarning
        env:
          HUGO_ENV: production
      - uses: actions/upload-pages-artifact@v5
        with:
          path: ./public
```

## Putting it together — request lifecycle

For `https://philoserf.com/posts/some-essay/`:

1. Hugo classifies the page: section `posts`, kind `page`.
2. Resolves the template: `layouts/_default/single.html`.
3. `single.html` extends `baseof.html`. Base template emits `<head>` with metadata derived from `partials/description.html` and conditionally loads KaTeX (if `Params.math`) or Mermaid (if the page uses the shortcode).
4. `single.html`'s `head` block injects a `BlogPosting` JSON-LD blob.
5. `single.html`'s `main` block renders the article: title, `<time>` (because `date` is set), then `.Content`.
6. The Obsidian-published markdown is rendered, with any `callout`/`mermaid` shortcodes expanded.

For the home page, the path is `layouts/index.html` (HTML output) plus four sibling templates rendering `llms.txt`, `site.webmanifest`, `vcard.vcf`, and `index.xml` (RSS, Hugo built-in).

## Where to look next

- `CLAUDE.md` — author-facing notes on the project, including the Obsidian publisher relationship and the implicit front-matter schema.
- `.issues/` — local issue tracker (gitignored). Currently flags inconsistent layouts/partials dir naming, off-by-one in series partial maxitems, vCard PII exposure, and an unpinned deploy action.
- `../NEXT.md` — workspace backlog. No row for `site` at the moment.
