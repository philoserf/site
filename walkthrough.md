# philoserf/site — Infrastructure Walkthrough

*2026-03-01T02:56:21Z by Showboat 0.6.1*
<!-- showboat-id: e44db3f6-1910-4d2d-8795-20aaf9fce895 -->

This walkthrough covers the infrastructure, configuration, and tooling for
[philoserf.com](https://philoserf.com/) — a Hugo-based personal site deployed
to GitHub Pages. Content files (`content/`) are excluded; the focus is on
how the site is built, styled, deployed, and maintained.

## 1. Project Layout

The top-level tree shows a clean Hugo project with Task-based automation,
GitHub Actions CI/CD, and a git-submodule theme.

```bash
find . -maxdepth 2 \( -path ./themes -o -path ./content -o -path ./public -o -path ./resources -o -path ./.git -o -path ./static/fonts -o -path ./static/images \) -prune -o -print | sort
```

```output
.
./.editorconfig
./.github
./.github/dependabot.yml
./.github/settings.yml
./.github/workflows
./.gitignore
./.gitmodules
./.nojekyll
./.prettierignore
./.vscode
./.vscode/extensions.json
./.vscode/settings.json
./.yamllint
./AGENTS.md
./archetypes
./archetypes/default.md
./assets
./assets/scss
./Brewfile
./CLAUDE.md
./CONTENT-LICENSE.md
./CONTRIBUTING.md
./DEVELOPMENT.md
./hugo.yaml
./layouts
./layouts/partials
./LICENSE
./README.md
./static
./static/CNAME
./static/favicon.ico
./static/humans.txt
./static/robots.txt
./static/site.webmanifest
./static/vcard.vcf
./taskfile.yml
./walkthrough.md
```

Key directories:

- **archetypes/** — Hugo content template for `hugo new`
- **assets/scss/** — Custom font overrides compiled by Hugo Pipes
- **layouts/partials/** — HTML partial overriding the theme's `<head>`
- **static/** — Files copied verbatim into the built site
- **themes/hugo-coder/** — Theme (git submodule, excluded from tree)
- **.github/** — CI/CD workflows, Dependabot, repo settings

---

## 2. Hugo Configuration — `hugo.yaml`

This is the single source of truth for site identity, navigation, taxonomy,
and rendering behavior.

```bash
cat -n hugo.yaml
```

```output
     1	title: Mark Ayers
     2	baseURL: https://philoserf.com/
     3	copyright: Mark Ayers
     4	theme: hugo-coder
     5	
     6	params:
     7	  author: Mark Ayers
     8	  since: 2005
     9	  info: |
    10	    COGITA·DISCE·NECTE·ENUNTIA
    11	  description: >-
    12	    Personal digital presence of Mark Ayers – former US Army Ranger,
    13	    technologist, and interdisciplinary thinker. Exploring intersections of
    14	    technology, strategy, and personal development through semi-weekly essays
    15	    and structured content. Guided by the philosophy of deep thinking,
    16	    continuous learning, connection-making, and clear articulation. A minimalist
    17	    digital space featuring professional journey, current projects, and
    18	    technical preferences shaped by military discipline and cross-domain
    19	    expertise.
    20	  license:
    21	    '<a href="https://creativecommons.org/licenses/by-nc-sa/4.0/">CC BY-NC-SA
    22	    4.0</a>'
    23	  keywords: >-
    24	    cogita, disce, necte, enuntia, interdisciplinary thinking, technology
    25	    strategy, personal development, military background, minimalism,
    26	    intellectual essays
    27	  avatarURL: /images/avatar.jpeg
    28	  colorScheme: auto
    29	  social:
    30	    - name: GitHub
    31	      icon: "fa-brands fa-github"
    32	      url: https://github.com/philoserf/
    33	    - name: Mastodon
    34	      icon: "fa-brands fa-mastodon"
    35	      url: https://pkm.social/@philoserf
    36	    - name: Bluesky
    37	      icon: "fa-brands fa-bluesky"
    38	      url: https://philoserf.bsky.social
    39	  customSCSS:
    40	    - scss/custom-fonts.scss
    41	
    42	markup:
    43	  goldmark:
    44	    renderer:
    45	      unsafe: true # Allow inline HTML
    46	
    47	menus:
    48	  main:
    49	    - name: "About"
    50	      url: "posts/about/"
    51	      weight: 1
    52	    - name: "Now"
    53	      url: "posts/now/"
    54	      weight: 2
    55	    - name: "Uses"
    56	      url: "posts/uses/"
    57	      weight: 3
    58	    - name: "Posts"
    59	      url: "posts/"
    60	      weight: 90
    61	
    62	taxonomies:
    63	  tag: tags
```

Things to note:

- **`colorScheme: auto`** (line 28) — the hugo-coder theme reads this and
  renders CSS that follows the user's OS light/dark preference.
- **`unsafe: true`** (line 45) — Goldmark's HTML sanitizer is disabled so
  the author can embed raw HTML in markdown (e.g. `<p class="latin-motto">`).
  Acceptable because all content is first-party.
- **`customSCSS`** (line 39-40) — hugo-coder supports loading project-local
  SCSS files through Hugo Pipes. This is how the site overrides theme fonts
  without forking the theme.
- **`license`** (line 20-22) — renders a CC BY-NC-SA 4.0 link in the site
  footer. This conflicts with `CONTENT-LICENSE.md` which declares "All rights
  reserved" (see [Concerns](#10-concerns--standards-adherence)).
- The navigation menu (lines 47-60) surfaces three special pages (About, Now,
  Uses) before the general post listing.

---

## 3. Build System — `taskfile.yml` + `Brewfile`

All development commands are orchestrated through
[Task](https://taskfile.dev), a Go-based task runner. Dependencies are
managed via Homebrew.

```bash
cat -n taskfile.yml
```

```output
     1	# https://taskfile.dev
     2	version: "3"
     3	
     4	tasks:
     5	  default:
     6	    desc: Build the Hugo site (default task)
     7	    deps: [build]
     8	
     9	  bootstrap:
    10	    desc: Install all required dependencies via Homebrew
    11	    sources: [Brewfile]
    12	    generates: [Brewfile.lock.json]
    13	    cmds:
    14	      - brew bundle
    15	
    16	  update:
    17	    desc: Update hugo-coder theme to latest version
    18	    cmds:
    19	      - git submodule update --remote --merge
    20	
    21	  fix:
    22	    desc: Auto-fix formatting with Prettier
    23	    deps: [bootstrap]
    24	    cmds:
    25	      - prettier --write --list-different --ignore-unknown .
    26	
    27	  build:
    28	    desc: Build Hugo site including drafts and future posts
    29	    deps: [bootstrap]
    30	    sources:
    31	      [
    32	        hugo.yaml,
    33	        content/**/*,
    34	        static/**/*,
    35	        layouts/**/*,
    36	        assets/**/*,
    37	        archetypes/**/*,
    38	      ]
    39	    generates: [public/**/*]
    40	    cmds:
    41	      - hugo --cleanDestinationDir --buildFuture --buildDrafts --buildExpired
    42	
    43	  serve:
    44	    desc: Start local development server with live reload
    45	    deps: [bootstrap]
    46	    cmds:
    47	      - hugo server --buildDrafts --buildFuture --buildExpired
    48	        --disableFastRender --navigateToChanged
    49	
    50	  optimize-images:
    51	    desc: Optimize images in static/images directory
    52	    deps: [bootstrap]
    53	    cmds:
    54	      - |
    55	        echo "🖼️  Optimizing PNG images..."
    56	        find static/images -name "*.png" -exec pngquant --force --ext .png --quality=65-80 {} \;
    57	        echo "🖼️  Optimizing JPEG images..."
    58	        find static/images \( -name "*.jpg" -o -name "*.jpeg" \) -exec mogrify -strip -interlace Plane -quality 85 {} \;
    59	        echo "✅ Image optimization complete!"
    60	
    61	  commit:
    62	    desc: Interactive commit workflow (requires non-main branch)
    63	    deps: [bootstrap, build]
    64	    interactive: true
    65	    cmds:
    66	      - test "$(git rev-parse --abbrev-ref HEAD)" != "main"
    67	      - git add -p
    68	      - git diff --name-only
    69	      - read -rp "Control-C to abort, Enter to continue." _
    70	      - read -rp "Commit message? " COMMIT_MESSAGE && git commit -m
    71	        "${COMMIT_MESSAGE}"
    72	      - git push
```

The `build` task (line 27) uses Task's `sources`/`generates` feature for
incremental builds — it only rebuilds when input files are newer than
`public/**/*`.

The `commit` task (line 61) enforces a branch-protection workflow:

1. Fails immediately if on `main` (line 66)
2. Interactively stages hunks with `git add -p`
3. Shows what's staged, asks for a commit message, then pushes

Note that the `commit` task auto-pushes on line 72. This is by design but
worth knowing — there is no separate "push" confirmation step.

The Brewfile lists every tool the project needs:

```bash
cat -n Brewfile
```

```output
     1	brew "gh"
     2	brew "go-task"
     3	brew "hugo"
     4	brew "imagemagick"
     5	brew "pngquant"
     6	brew "prettier"
```

Six tools, all installed via Homebrew. `imagemagick` provides `mogrify`
for JPEG optimization; `pngquant` handles PNGs. Prettier is installed
as a Homebrew formula rather than via npm — no `node_modules/` anywhere.

---

## 4. Theme & Font Customization

The site uses the [hugo-coder](https://github.com/luizdepra/hugo-coder)
theme pulled in as a git submodule.

```bash
cat -n .gitmodules
```

```output
     1	[submodule "themes/hugo-coder"]
     2		path = themes/hugo-coder
     3		url = https://github.com/luizdepra/hugo-coder.git
```

The theme is not forked or modified. All customization happens through two
override mechanisms Hugo provides:

1. **Layout partials** — the theme's `head/extensions.html` hook is
   overridden by the project's own partial to inject Google Fonts.
2. **Custom SCSS** — hugo-coder's `customSCSS` parameter loads
   project-local stylesheets via Hugo Pipes.

### Font loading — `layouts/partials/head/extensions.html`

```bash
cat -n layouts/partials/head/extensions.html
```

```output
     1	<!-- Load Inter font from Google Fonts -->
     2	<link rel="preconnect" href="https://fonts.googleapis.com">
     3	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
     4	<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
```

The `<link rel="preconnect">` tags (lines 2-3) establish early TCP/TLS
connections to Google Fonts, reducing latency when the CSS file request
arrives on line 4. Inter is loaded in three weights: 400 (body), 600
(semibold), and 700 (bold).

### Font application — `assets/scss/custom-fonts.scss`

```bash
cat -n assets/scss/custom-fonts.scss
```

```output
     1	// Custom font overrides for philoserf/site
     2	// Override theme font variables to prioritize Inter and Menlo
     3	
     4	// Import EB Garamond for the params.info motto
     5	@import url('https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400..800;1,400..800&display=swap');
     6	
     7	// Inter is loaded via <link> in layouts/partials/head/extensions.html
     8	$font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", Helvetica, sans-serif;
     9	$code-font-family: "Menlo", "Monaco", "Consolas", "Liberation Mono", "SFMono-Regular", monospace;
    10	
    11	// Apply to all text elements
    12	body {
    13	  font-family: $font-family;
    14	}
    15	
    16	// Apply to all code elements
    17	pre, code, kbd, samp {
    18	  font-family: $code-font-family;
    19	}
    20	
    21	// Ensure headings use the base font
    22	h1, h2, h3, h4, h5, h6 {
    23	  font-family: $font-family;
    24	}
    25	
    26	// Apply EB Garamond to the params.info motto on home page
    27	.about h2 {
    28	  font-family: "EB Garamond", serif;
    29	}
    30	
    31	// Apply EB Garamond to Latin mottos on about page
    32	.latin-motto {
    33	  font-family: "EB Garamond", serif;
    34	}
```

Two fonts, two loading strategies:

| Font | Purpose | Loaded via |
|------|---------|------------|
| Inter | Body text, headings | `<link>` in HTML partial |
| EB Garamond | Latin motto accents | `@import` in SCSS |

The SCSS file overrides hugo-coder's `$font-family` and `$code-font-family`
variables (lines 8-9). Hugo Pipes compiles this into the theme's CSS bundle
at build time — no separate stylesheet request.

The `.about h2` selector (line 27) targets the motto displayed on the home
page. `.latin-motto` (line 32) is a class applied manually in the about
page's markdown via raw HTML (enabled by `unsafe: true` in hugo.yaml).

---

## 5. Content Archetype — `archetypes/default.md`

When you run `hugo new content/posts/my-post.md`, Hugo stamps out a file
from this template.

```bash
cat -n archetypes/default.md
```

```output
     1	---
     2	title: "{{ replace .Name "-" " " | title }}"
     3	date: {{ .Date }}
     4	lastmod: {{ .Date }}
     5	description: ""
     6	tags:
     7	  -
     8	publish: false
     9	---
    10	
```

**Bug (issue #548):** Line 8 uses `publish: false`, but Hugo does not
recognize a `publish` frontmatter field. The standard Hugo field is
`draft: true`. Posts created from this archetype will appear to be
"unpublished" in the frontmatter, but Hugo will render and deploy them
anyway because it ignores unrecognized keys. The `--buildDrafts` flag in
`task build` only affects the `draft` field.

---

## 6. CI/CD Pipeline

### Deployment — `.github/workflows/deploy.yml`

```bash
cat -n .github/workflows/deploy.yml
```

```output
     1	name: deploy
     2	
     3	on:
     4	  workflow_dispatch: null
     5	  push:
     6	    branches: [main]
     7	  schedule:
     8	    - cron: "25 15 * * *"
     9	
    10	permissions:
    11	  contents: read
    12	  pages: write
    13	  id-token: write
    14	
    15	concurrency:
    16	  group: pages
    17	  cancel-in-progress: false
    18	
    19	defaults:
    20	  run:
    21	    shell: bash
    22	
    23	jobs:
    24	  build:
    25	    if: github.repository == 'philoserf/site'
    26	    runs-on: ubuntu-latest
    27	    steps:
    28	      - uses: actions/checkout@v6
    29	        with:
    30	          fetch-depth: 0
    31	          submodules: true
    32	      - uses: actions/configure-pages@v5
    33	        id: pages
    34	      - uses: peaceiris/actions-hugo@v3
    35	        with:
    36	          extended: true
    37	      - run: hugo --gc --minify
    38	      - uses: actions/upload-pages-artifact@v4
    39	        with:
    40	          path: ./public
    41	
    42	  deploy:
    43	    runs-on: ubuntu-latest
    44	    needs: build
    45	    environment:
    46	      name: github-pages
    47	      url: ${{ steps.deployment.outputs.page_url }}
    48	    steps:
    49	      - uses: actions/deploy-pages@v4
    50	        id: deployment
```

The pipeline has two jobs connected by `needs: build` (line 44):

**Build job:**
- Checks out full history (`fetch-depth: 0`) plus the theme submodule
  (line 31). Full history is needed for Hugo's `.GitInfo` feature (last
  modified dates from git).
- Installs Hugo Extended (line 36) — required because the theme uses SCSS
  which needs the extended build with libsass.
- Runs a production build: `hugo --gc --minify` (line 37). Unlike the local
  `task build`, this omits `--buildDrafts`, `--buildFuture`, and
  `--buildExpired` — so only published, current, non-expired content ships.
- Uploads `./public` as a Pages artifact.

**Deploy job:**
- Uses OIDC token authentication (`id-token: write`) — no long-lived PAT
  secrets needed.
- The `if: github.repository == 'philoserf/site'` guard (line 25) prevents
  forks from accidentally deploying.

**Triggers** (lines 3-8):
- Push to `main` — normal deployment path
- Manual dispatch — for ad-hoc deploys
- Daily cron at 15:25 UTC — ensures scheduled/expiring posts go live even
  without a code push

### Claude Code integration — `.github/workflows/claude.yml`

```bash
cat -n .github/workflows/claude.yml
```

```output
     1	name: Claude Code
     2	
     3	on:
     4	  issue_comment:
     5	    types: [created]
     6	  pull_request_review_comment:
     7	    types: [created]
     8	  pull_request_review:
     9	    types: [submitted]
    10	  issues:
    11	    types: [opened, assigned]
    12	
    13	jobs:
    14	  claude:
    15	    # Run only when a comment or PR/issue body contains @claude
    16	    if: |
    17	      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
    18	      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
    19	      (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
    20	      (github.event_name == 'issues' && (contains(github.event.issue.body, '@claude') || contains(github.event.issue.title, '@claude')))
    21	    runs-on: ubuntu-latest
    22	    permissions:
    23	      contents: write
    24	      pull-requests: write
    25	      issues: write
    26	      id-token: write
    27	      actions: read
    28	
    29	    steps:
    30	      - name: Checkout repository
    31	        uses: actions/checkout@v6
    32	        with:
    33	          fetch-depth: 1
    34	
    35	      - name: Run Claude Code
    36	        id: claude
    37	        uses: anthropics/claude-code-action@v1
    38	        with:
    39	          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

This workflow enables `@claude` mentions in issues and PRs to invoke
Claude Code. It has broad write permissions (lines 23-27) because the
agent may need to push commits, comment on PRs, or update issues. A
shallow checkout (`fetch-depth: 1`) is sufficient since the agent doesn't
need git history.

### Dependency automation — `.github/dependabot.yml`

```bash
cat -n .github/dependabot.yml
```

```output
     1	version: 2
     2	updates:
     3	  - package-ecosystem: "github-actions"
     4	    directory: "/"
     5	    schedule:
     6	      interval: "weekly"
     7	  - package-ecosystem: "gitsubmodule"
     8	    directory: "/"
     9	    schedule:
    10	      interval: "weekly"
```

Two Dependabot ecosystems run weekly:

1. **github-actions** — bumps action versions in workflow files (e.g.
   `actions/checkout@v5` → `@v6`)
2. **gitsubmodule** — bumps the hugo-coder theme to its latest commit

Both open PRs automatically, which then trigger the deploy workflow for
preview.

### Repository settings — `.github/settings.yml`

```bash
cat -n .github/settings.yml
```

```output
     1	_extends: .github
     2	
     3	repository:
     4	  name: site
     5	  description: "My personal website"
     6	  homepage: https://philoserf.com/
     7	  topics:
     8	    - personal-website
```

This is consumed by the
[probot/settings](https://github.com/probot/settings) app (or a similar
org-level `.github` repo). The `_extends: .github` line (line 1) inherits
defaults from the org's `.github` repository template.

---

## 7. Static Assets

Files in `static/` are copied verbatim into the site root at build time.

### Domain — `static/CNAME`

```bash
cat static/CNAME
```

```output
philoserf.com
```

GitHub Pages reads this file to configure the custom domain. DNS must have
a CNAME or A record pointing to GitHub's servers.

### SEO — `static/robots.txt`

```bash
cat static/robots.txt && echo
```

```output
User-agent: *
Allow: /

Sitemap: https://philoserf.com/sitemap.xml
```

Wide open — all crawlers are allowed everywhere. The sitemap reference
points to Hugo's auto-generated `sitemap.xml`.

### Site metadata — `static/humans.txt`

```bash
cat -n static/humans.txt
```

```output
     1	Last update: 2025-12-10
     2	
     3	/* TEAM */
     4	writer: Mark Ayers
     5	editor: Mark Ayers
     6	publisher: Mark Ayers
     7	email: mark@philoserf.com
     8	site: https://philoserf.com/
     9	location: Greater Grand Rapids, Michigan, USA
    10	
    11	/* SITE */
    12	hosting: GitHub Pages
    13	construction: Hugo
    14	theme: Coder
```

The [humanstxt.org](http://humanstxt.org/) convention. The "Last update"
date on line 1 is manually maintained and currently stale (issue #554).

### PWA manifest — `static/site.webmanifest`

```bash
cat -n static/site.webmanifest
```

```output
     1	{
     2	  "name": "Mark Ayers",
     3	  "short_name": "Mark Ayers",
     4	  "description": "Personal digital presence of Mark Ayers – former US Army Ranger, technologist, and interdisciplinary thinker. Exploring intersections of technology, strategy, and personal development.",
     5	  "icons": [
     6	    {
     7	      "src": "/images/android-chrome-144x144.png",
     8	      "sizes": "144x144",
     9	      "type": "image/png"
    10	    },
    11	    {
    12	      "src": "/images/android-chrome-192x192.png",
    13	      "sizes": "192x192",
    14	      "type": "image/png"
    15	    },
    16	    {
    17	      "src": "/images/android-chrome-512x512.png",
    18	      "sizes": "512x512",
    19	      "type": "image/png"
    20	    },
    21	    {
    22	      "src": "/images/android-chrome-144x144.png",
    23	      "sizes": "144x144",
    24	      "type": "image/png",
    25	      "purpose": "maskable"
    26	    }
    27	  ],
    28	  "theme_color": "#ffffff",
    29	  "background_color": "#ffffff",
    30	  "display": "standalone",
    31	  "start_url": "/",
    32	  "scope": "/"
    33	}
```

The manifest enables "Add to Home Screen" on mobile. The fourth icon entry
(lines 21-26) duplicates the 144x144 source but with `"purpose": "maskable"`
for Android adaptive icons.

**Concern (issue #553):** `theme_color` and `background_color` are both
hardcoded to white (`#ffffff`), but the site uses `colorScheme: auto`.
Users in dark mode will see a white title bar and splash screen in the PWA.

### Contact card — `static/vcard.vcf`

```bash
cat -n static/vcard.vcf
```

```output
     1	BEGIN:VCARD
     2	VERSION:3.0
     3	FN:Mark Ayers
     4	N:Ayers;Mark;;;
     5	NICKNAME:philoserf
     6	BDAY:19620704
     7	LANG:en-US
     8	
     9	EMAIL;TYPE=INTERNET:mark@philoserf.com
    10	TEL;TYPE=CELL:+12062804061
    11	ADR;TYPE=HOME:;;160 Rollingwood Dr;Rockford;MI;49341;United States
    12	TZ:America/Detroit
    13	
    14	URL:https://philoserf.com/
    15	X-SOCIALPROFILE;type=github:https://github.com/philoserf
    16	X-SOCIALPROFILE;type=mastodon:https://pkm.social/@philoserf
    17	X-SOCIALPROFILE;type=bluesky:https://philoserf.bsky.social/
    18	
    19	PHOTO;VALUE=URI:https://philoserf.com/images/avatar.jpeg
    20	SOURCE:https://philoserf.com/vcard.vcf
    21	NOTE:COGITA·DISCE·NECTE·ENUNTIA
    22	REV:20251119T120000Z
    23	END:VCARD
```

A vCard 3.0 contact card available at `philoserf.com/vcard.vcf`. Includes
physical address, phone, social profiles, and the site motto. The
`SOURCE` field (line 20) is self-referential — vCard readers can refresh
from the canonical URL.

### Jekyll bypass — `.nojekyll`

```bash
wc -c .nojekyll
```

```output
       0 .nojekyll
```

An empty file. Its presence tells GitHub Pages to skip Jekyll processing
and serve the pre-built Hugo output as-is. Without it, GitHub Pages would
try to run Jekyll on the `public/` directory and potentially break paths
that start with underscores.

---

## 8. Editor & Quality Tooling

### `.editorconfig`

```bash
cat -n .editorconfig
```

```output
     1	root = true
     2	
     3	[*]
     4	charset = utf-8
     5	end_of_line = lf
     6	insert_final_newline = true
     7	trim_trailing_whitespace = true
     8	
     9	[*.{md,markdown}]
    10	indent_style = space
    11	indent_size = 2
    12	max_line_length = off
    13	
    14	[*.{yaml,yml}]
    15	indent_style = space
    16	indent_size = 2
    17	
    18	[*.go]
    19	indent_style = tab
```

The `root = true` marker (line 1) prevents editors from searching parent
directories for additional `.editorconfig` files. The Go section (lines
18-19) exists because Hugo's extended build occasionally touches Go files
in the module cache.

### `.prettierignore`

```bash
cat -n .prettierignore
```

```output
     1	public/
     2	resources/
     3	archetypes/
     4	layouts/
     5	assets/scss/
     6	themes/
```

Prettier is told to skip:
- **public/, resources/** — generated output
- **themes/** — third-party code
- **archetypes/** — Hugo Go templates with `{{ }}` syntax that Prettier
  would mangle
- **layouts/** — same reason (Go HTML templates)
- **assets/scss/** — SCSS processed by Hugo Pipes; Prettier could alter
  whitespace that affects compilation

The `task fix` command runs `prettier --write --ignore-unknown .` which
respects this ignore list.

### `.yamllint`

```bash
cat -n .yamllint
```

```output
     1	extends: default
     2	
     3	ignore: |
     4	  node_modules/
     5	  resources/
     6	  public/
     7	  .github/workflows/build.yml
     8	  .github/workflows/codeql-analysis.yml
     9	
    10	yaml-files:
    11	  - "*.yaml"
    12	  - "*.yml"
    13	  - ".yamllint"
    14	
    15	rules:
    16	  line-length: disable
    17	  braces:
    18	    max-spaces-inside: 1
    19	  indentation:
    20	    spaces: consistent
    21	  document-start: disable
```

The ignore list (lines 3-8) references two workflow files that no longer
exist: `build.yml` and `codeql-analysis.yml`. These are harmless stale
entries — yamllint will simply skip them — but they indicate the config
hasn't been updated since those workflows were removed.

### VS Code workspace — `.vscode/`

```bash
cat -n .vscode/settings.json
```

```output
     1	{
     2	  "editor.formatOnSave": true,
     3	  "editor.defaultFormatter": "esbenp.prettier-vscode",
     4	  "files.insertFinalNewline": true,
     5	  "files.trimTrailingWhitespace": true,
     6	  "[markdown]": {
     7	    "editor.defaultFormatter": "esbenp.prettier-vscode",
     8	    "editor.wordWrap": "on",
     9	    "editor.quickSuggestions": {
    10	      "comments": "off",
    11	      "strings": "off",
    12	      "other": "off"
    13	    }
    14	  },
    15	  "[yaml]": {
    16	    "editor.defaultFormatter": "esbenp.prettier-vscode",
    17	    "editor.insertSpaces": true,
    18	    "editor.tabSize": 2
    19	  },
    20	  "[json]": {
    21	    "editor.defaultFormatter": "esbenp.prettier-vscode"
    22	  },
    23	  "files.associations": {
    24	    "*.md": "markdown",
    25	    "CLAUDE.md": "markdown",
    26	    "CONTRIBUTING.md": "markdown",
    27	    "DEVELOPMENT.md": "markdown"
    28	  },
    29	  "markdownlint.config": {
    30	    "extends": ".markdownlint.json"
    31	  },
    32	  "search.exclude": {
    33	    "**/public": true,
    34	    "**/resources": true,
    35	    "**/themes": true,
    36	    "**/.git": true,
    37	    "**/node_modules": true
    38	  },
    39	  "files.exclude": {
    40	    "**/.DS_Store": true,
    41	    "**/Thumbs.db": true
    42	  },
    43	  "hugo.server.renderStaticToDisk": false
    44	}
```

```bash
cat -n .vscode/extensions.json
```

```output
     1	{
     2	  "recommendations": [
     3	    "esbenp.prettier-vscode",
     4	    "davidanson.vscode-markdownlint",
     5	    "budparr.language-hugo-vscode",
     6	    "redhat.vscode-yaml",
     7	    "editorconfig.editorconfig"
     8	  ]
     9	}
```

The VS Code config references `.markdownlint.json` on line 30 of
`settings.json`, but this file does not exist in the project (issue #550).
The markdownlint extension will fall back to its default rules, which is
fine — but the explicit `extends` reference is misleading.

The `files.associations` block (lines 23-28) maps known markdown files to
the markdown language mode. Lines 24-27 are redundant since VS Code
already recognizes `.md` files as markdown, but they're harmless.

---

## 9. Documentation Files

### `README.md` — project overview

```bash
sed -n "33,45p" README.md | cat -n
```

```output
     1	All development uses Task for command orchestration:
     2	
     3	- `task build` - Build the Hugo site
     4	- `task serve` - Start local development server with live reload
     5	- `task fix` - Auto-fix formatting with Prettier and markdownlint
     6	- `task validate-content` - Validate frontmatter completeness
     7	- `task validate` - Run all validation checks
     8	- `task optimize-images` - Optimize images in static/images
     9	- `task update` - Update hugo-coder theme to latest version
    10	- `task bootstrap` - Install tools via Homebrew
    11	- `task commit` - Interactive commit workflow (non-main branches only)
    12	
    13	Run `task --list` to see all available tasks with descriptions.
```

**Concern (issue #549):** Lines 6-7 document `task validate-content` and
`task validate` which do not exist in `taskfile.yml`. Line 5 claims
`task fix` runs markdownlint, but the actual task only runs Prettier.
CONTRIBUTING.md and DEVELOPMENT.md repeat these phantom references.

### Licensing — `LICENSE` + `CONTENT-LICENSE.md`

```bash
head -5 LICENSE
```

```output
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
```

```bash
cat -n CONTENT-LICENSE.md
```

```output
     1	# Content License
     2	
     3	This section applies only to written content and media assets; it does not apply to source code, templates, or configuration files.
     4	
     5	Copyright © 2023–2025 by Mark Ayers. All rights reserved.
     6	
     7	Unless otherwise noted:
     8	
     9	- You may not reproduce, redistribute, or create derivative works of the written content and media assets without prior written permission from the copyright holder.
    10	- Forks of this repository for contribution purposes may host unmodified copies on GitHub; any other republication or distribution is prohibited without permission.
    11	
    12	For questions about permissions, please contact the author.
```

**Concern (issue #551):** The site footer (rendered from `hugo.yaml`
line 21) displays a link to **CC BY-NC-SA 4.0**, but `CONTENT-LICENSE.md`
says **"All rights reserved"** with no reuse permitted. These are
contradictory — CC BY-NC-SA 4.0 allows sharing and adaptation under
certain conditions; "All rights reserved" denies both. Additionally, the
copyright year range says 2023–2025 but it is now 2026.

### Agent instructions — `CLAUDE.md` / `AGENTS.md`

```bash
diff CLAUDE.md AGENTS.md; echo "Exit: $?"
```

```output
Exit: 0
```

```bash
wc -l CLAUDE.md
```

```output
      49 CLAUDE.md
```

`CLAUDE.md` and `AGENTS.md` are byte-identical (49 lines, zero diff).
Both provide a concise briefing for AI agents. Unlike the README,
CONTRIBUTING, and DEVELOPMENT docs, these files accurately list only the
tasks that actually exist in `taskfile.yml`.

The `CLAUDE.md` heading says "# AGENTS.md" which is slightly odd but
functionally irrelevant — Claude Code reads the file for project context
regardless of its internal heading.

---

## 10. Concerns & Standards Adherence

A summary of issues found during this walkthrough, with references to
GitHub issues where they've been filed.

### Bugs

| Issue | Description |
|-------|-------------|
| [#548](https://github.com/philoserf/site/issues/548) | Archetype uses `publish: false` instead of Hugo's `draft: true`. New posts created with `hugo new` will be deployed immediately. |
| [#551](https://github.com/philoserf/site/issues/551) | Site footer says CC BY-NC-SA 4.0; `CONTENT-LICENSE.md` says "All rights reserved". Contradictory licensing. Copyright year range also stale (ends 2025). |

### Documentation drift

| Issue | Description |
|-------|-------------|
| [#549](https://github.com/philoserf/site/issues/549) | README, CONTRIBUTING, and DEVELOPMENT reference `task validate-content`, `task validate`, and markdownlint integration — none of which exist. |
| [#550](https://github.com/philoserf/site/issues/550) | DEVELOPMENT.md has wrong path, wrong post count, references 3 missing config files, claims no custom layouts exist (one does), and has a stale "Last Updated" date. |
| [#552](https://github.com/philoserf/site/issues/552) | Pre-commit hook is documented with troubleshooting instructions but does not exist in `.git/hooks/`. |

### Minor issues

| Issue | Description |
|-------|-------------|
| [#553](https://github.com/philoserf/site/issues/553) | PWA manifest hardcodes `theme_color: #ffffff` while the site respects dark mode via `colorScheme: auto`. |
| [#554](https://github.com/philoserf/site/issues/554) | `humans.txt` shows "Last update: 2025-12-10" — stale. |

### Additional observations (not filed as issues)

- **`.yamllint` ignore list** references two deleted workflow files
  (`build.yml`, `codeql-analysis.yml`). Harmless but indicates config
  staleness.
- **`.vscode/settings.json`** references `.markdownlint.json` via
  `extends` — the file doesn't exist. The extension falls back to
  defaults silently.
- **`CLAUDE.md` heading** says "# AGENTS.md" — cosmetic only.
- **No `.prettierrc`** config file exists. Prettier runs with its
  defaults, which is fine — but DEVELOPMENT.md documents specific
  Prettier settings (prose wrap 80, no semicolons, double quotes, ES5
  trailing commas) that only apply if configured.

### Standards adherence

The project follows Hugo community conventions well:

- Standard directory structure (`content/`, `static/`, `layouts/`,
  `assets/`, `archetypes/`, `themes/`)
- Theme as a git submodule (not vendored or forked)
- Customization via layout overrides and SCSS variables rather than
  theme modification
- `.nojekyll` for GitHub Pages
- `CNAME` in `static/` for custom domain
- Proper `robots.txt` and `sitemap.xml` references
- EditorConfig for cross-editor consistency
- Dependabot for automated dependency updates
- OIDC authentication in CI (no long-lived tokens)

The main deviation from community best practices is the documentation
drift — the README, CONTRIBUTING, and DEVELOPMENT files describe a more
featureful project than what actually exists (validation tasks,
markdownlint config, pre-commit hooks). This creates confusion for
contributors who follow the documented workflow.

