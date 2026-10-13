# philoserf.com

![Status: Active](https://img.shields.io/badge/Status-Active-blue.svg)

Personal essays by Mark Ayers — semi-weekly, on technology, strategy, and personal development. Read them at [philoserf.com](https://philoserf.com/), not here. **Site motto:** COGITA·DISCE·NECTE·FARE (Think, Learn, Connect, Speak).

For a linear tour of the layouts, partials, and build pipeline, see [WALKTHROUGH.md](./WALKTHROUGH.md). For a theory of the codebase in Peter Naur's sense — the publisher relationship, the load-bearing abstractions, the seams, and what kinds of change the system is shaped to accommodate — see [THEORY.md](./THEORY.md).

## What this repo is

The rendering half of a two-repo writing pipeline. The author writes in an Obsidian vault (`../notes`); the `../obsidian-publisher` plugin pushes notes flagged `status: publish` into `content/posts/` here as Hugo markdown. **Posts under `content/posts/` are output, not source — direct edits are overwritten on the next publish.** Only `content/_index.md`, `about.md`, `now.md`, `uses.md`, plus everything under `layouts/`, `static/`, `archetypes/`, `hugo.yaml`, and `Taskfile.yml`, are safely edited in this repo.

## Tasks

```bash
task setup   # install dependencies via Homebrew
task dev     # hugo server -D -F (drafts + future content visible)
task build   # hugo --gc --minify --panicOnWarning (production)
task check   # hugo --renderToMemory --panicOnWarning (the integration test)
task format  # prettier --write .
task links   # lychee over public/ (external links and anchors)
task deploy  # build and deploy by hand; pushes to main deploy on their own
```

Run `task --list` for the rest.

## Conventions

- **No taxonomies.** `taxonomies: {}` in `hugo.yaml` is intentional; the publisher emits `tags` but the site discards them.
- **Templated identity.** Author name, motto, contact details, and vCard fields all live in `hugo.yaml` `params`. Five home-page output formats (`html`, `rss`, `llms`, `manifest`, `vcard`) and `robots.txt` are templated from it — no `vcard.vcf`, `site.webmanifest`, or `llms.txt` under `static/`.
- **Two archetypes, asymmetric on purpose.** `archetypes/default.md` scaffolds `lastmod` only (structural pages); `archetypes/posts.md` scaffolds `date` only (essays).
- **`hugo --panicOnWarning` is the integration test.** There is no test suite. The strict build catches missing shortcodes and broken refs; the rest is caught by visually reviewing published posts.
- **Conditional asset loading.** KaTeX loads when a page sets `math: true`; Mermaid loads when a page uses the `mermaid` shortcode. Don't add unconditional scripts to `baseof.html`.
- **vCard PII is intentional.** `layouts/index.vcard.vcf` includes home address, mobile, and date of birth deliberately.

## Deployment

A Cloudflare Worker serving `public/` as static assets, with Hugo's `404.html` as the not-found page. Workers Builds, Cloudflare's git integration, runs `bunx wrangler deploy` on every push to `main`, and `bunx wrangler versions upload` on other branches. Either one first runs `build.command` from `wrangler.jsonc`: a validate pass over drafts and future-dated posts, then the strict build. `almanac` calls the Worker's deploy hook every day at 05:00 Eastern from `~/.config/refresh.zsh`, so a future-dated post goes live the morning of its date. The build image's Hugo is set by the `HUGO_VERSION` build variable in the dashboard, not by this repo.

### Cloudflare settings

`wrangler.jsonc` holds the Worker, its build and its custom domain. These settings live only in Cloudflare, so restore them by hand if the Worker is ever recreated:

- **Builds connection** (Workers & Pages → `site` → Settings → Builds): GitHub `philoserf/site`, root directory `/`, build command empty, since `build.command` is the build. The Cloudflare GitHub app needs access to this repo.
- **Production branch** `main`, deploy command `bunx wrangler deploy`.
- **Non-production branches** on, deploy command `bunx wrangler versions upload`. They build and validate, and report as the "Workers Builds: site" check on GitHub, but get no preview URL: `preview_urls` is off.
- **Build variable** `HUGO_VERSION=latest` on both, so the build image's Hugo floats.
- **Deploy hook** "almanac daily rebuild" on `main`. Its URL is a secret kept only in `~/.config/site-deploy-hook` (mode 600) on `almanac`, which `refresh.zsh` POSTs. To replace it, create a hook under Settings → Builds → Deploy Hooks, write its URL to that file, and delete the old hook.

On a fresh account, run `task deploy` once to create the Worker and attach the domain, then connect Builds. The domain attaches only when no other DNS record holds the hostname.

The zone serves `/.well-known/security.txt` as a Cloudflare-managed file (Security → Settings); this repo has none.

## License

- **Code / config**: [MIT](./LICENSE).
- **Content**: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) © 2023–2026 Mark Ayers. See [CONTENT-LICENSE.md](./CONTENT-LICENSE.md).
