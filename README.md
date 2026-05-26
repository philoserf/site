# philoserf.com

Personal essays by Mark Ayers — semi-weekly, on technology, strategy, and personal development. Read them at [philoserf.com](https://philoserf.com/), not here. **Site motto:** COGITA·DISCE·NECTE·ENUNTIA (Think, Learn, Connect, Articulate).

For a linear tour of the layouts, partials, and build pipeline, see [walkthrough.md](./walkthrough.md). For a theory of the codebase in Peter Naur's sense — the publisher relationship, the load-bearing abstractions, the seams, and what kinds of change the system is shaped to accommodate — see [theory.md](./theory.md).

## What this repo is

The rendering half of a two-repo writing pipeline. The author writes in an Obsidian vault (`../notes`); the `../obsidian-publisher` plugin pushes notes flagged `status: publish` into `content/posts/` here as Hugo markdown. **Posts under `content/posts/` are output, not source — direct edits are overwritten on the next publish.** Only `content/_index.md`, `about.md`, `now.md`, `uses.md`, plus everything under `layouts/`, `static/`, `archetypes/`, `hugo.yaml`, and `Taskfile.yml`, are safely edited in this repo.

## Tasks

```bash
task setup   # install dependencies via Homebrew
task dev     # hugo server -D -F (drafts + future content visible)
task build   # hugo --minify (production)
task check   # hugo --renderToMemory --panicOnWarning (the integration test)
task format  # prettier --write .
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

GitHub Pages, artifact-based, via `.github/workflows/deploy.yml`. Triggered on push to `main`, manual dispatch, and daily at 08:25 UTC. The deploy build is stricter than the PR build — see `theory.md` for the implications.

## License

- **Code / config**: [MIT](./LICENSE).
- **Content**: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) © 2023–2026 Mark Ayers. See [CONTENT-LICENSE.md](./CONTENT-LICENSE.md).
