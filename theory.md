# A theory of the philoserf.com site

## What this system is for

This repository is **a rendering target for a writer's notebook**, not an authoring environment. The world it models has two actors: an author with an Obsidian vault of ~2,400 notes, and a public reader. The site sits between them as a presentation layer. The first thing to internalize is that the author does not write here. The author writes in Obsidian. A plugin (`obsidian-publisher`) periodically dumps a selected subset of notes into `content/posts/` as Hugo-flavoured markdown and pushes the result. The high-frequency commit pattern in the log (`Publish 109 notes from Obsidian`, `Publish 95 notes from Obsidian`, single-post publishes named after the essay) is the signature of this relationship. The repo's role is to receive those drops, render them faithfully, and serve them.

Everything downstream of that observation has consequences. Posts under `content/posts/` are output, not source — direct edits are erased on the next publish. Front matter on posts is not a schema this repo defines; it is whatever the publisher emits, and the layouts must degrade gracefully when fields are absent because nothing in this repo prevents the publisher from changing its mind. Only four files in `content/` are safely editable here: `_index.md`, `about.md`, `now.md`, `uses.md`. Those four — plus `layouts/`, `static/`, `archetypes/`, `hugo.yaml`, `taskfile.yml` — are the actual source of this codebase. Everything else is incoming traffic.

## The organizing ideas

**The site identity is data, and every public artifact is a projection of it.** `hugo.yaml`'s `params` block holds the author's name, email, motto, contact details, social URLs. Five public artifacts derive from that block, all rendered from the home page through custom output formats: the HTML home page, the RSS feed, `llms.txt`, `site.webmanifest`, `vcard.vcf`. None of those non-HTML files exists in `static/`. They are all produced by templates under `layouts/index.<name>.<ext>`, and they all read from `Site.Params`. Change the author's name in one place and every artifact updates. This is why `static/vcard.vcf` does not exist despite the stale `.issues/` file calling it out — that file was the previous arrangement; the current one treats the vCard as a templated projection.

**The front-matter schema is enforced upstream, not here.** Hugo does no validation. The `description.html` partial cascades through `.Description → .Summary → .Site.Params.description`; the `single.html` template guards `<time>` and `datePublished` with `.Date.IsZero`. These are not defensive coding tics, they are the contract: the publisher promises some fields, this repo absorbs whatever arrives. A missing description does not break the build, it falls back to summary, then to the site default. The "schema" lives in the publisher's source code, which is not in this repo.

**The archetype asymmetry is load-bearing.** `archetypes/default.md` scaffolds `lastmod` only. `archetypes/posts.md` scaffolds `date` only. The asymmetry encodes a domain claim: structural pages (about, now, uses) have no publication moment, just a most-recent-edit; posts have a publication moment that is the moment that matters, and `lastmod` falls out of `enableGitInfo: true` automatically. `single.html` keys off `.Date.IsZero` to decide whether to render `<time>` at all, so scaffolding a post with the wrong archetype is silently destructive. A maintainer who flattens these archetypes into a single template will break rendering.

**Two things are explicitly disabled, and that is the design.** `taxonomies: {}` is empty, on purpose, with a comment. There are no tags and no categories on this site, and there will not be unless the theory changes. Similarly, the home page emits `Person` + `WebSite` JSON-LD; posts emit `BlogPosting` with a single `author`. The model is one author, no categorization. A request to add "tags" or "co-authors" is not a small request.

**Strict builds are the integration test.** There is no test suite. There is no link checker. What there is, in both `task check` and the deploy workflow, is `hugo --panicOnWarning`. Recent commits `10b6caa` and `b20b17b` hardened this in CI and locally within days of each other; treat the panic-on-warning flag as the closest thing this repo has to a CI guard. Anything that produces a Hugo warning — a missing shortcode the publisher emitted that this repo doesn't define, a broken cross-reference, a template error — fails the build. The integration test for _content_ correctness is publish-then-look. The integration test for _templating_ correctness is the strict build.

**Conditional asset loading is a real pattern, used twice.** KaTeX loads only when a page or the site sets `Params.math`. Mermaid loads only when `.HasShortcode "mermaid"`. Both are gated in `baseof.html`. This is how the site avoids shipping ~80KB of math typography to every essay that doesn't need it. A new heavy asset added unconditionally to `baseof.html` would violate this pattern.

**Shortcodes come in two flavours with different ownership.** `latin-motto` is local — three lines of HTML, owned by this repo. `callout` and `mermaid` were added in commit `07f92b7 Add callout and mermaid shortcodes from obsidian-publisher` and CLAUDE.md says they are reference templates kept in sync with `../obsidian-publisher/hugo-shortcodes/`. The publisher emits these in essays; if the publisher's emit format changes, these must change with it. Editing `callout.html` or `mermaid.html` without checking the publisher is editing one half of a contract.

## The seams

The publisher → content seam is the most important and the least visible from inside this repo. It is a one-way write. Nothing in this codebase observes it directly; you only see its trace in the commit log. The contract is: the publisher writes markdown with front matter (`title`, `description`, `date`, sometimes `tags`/`aliases`/`series`/`created`) plus shortcode calls (`callout`, `mermaid`, and any others the publisher emits). The site must render whatever arrives. Drift on either side is invisible until a build warning catches it — which is exactly why `--panicOnWarning` matters.

The home page → output formats seam is principled. Adding `application/manifest+json` as a mediaType, defining `manifest` as an output format with `notAlternative: true` (so it doesn't appear as `<link rel="alternate">` in HTML heads), declaring it under `outputs.home`, and providing a template at `layouts/index.manifest.webmanifest` is a four-step recipe. The recipe is the same for `llms.txt` and `vcard.vcf`. A new "the home page also produces X" requirement maps onto these four steps cleanly.

The deploy seam is shallow and worth knowing. Artifact-based GitHub Pages: `actions/upload-pages-artifact` then `actions/deploy-pages`, no `gh-pages` branch. The workflow runs on push to `main`, on manual trigger, and on a daily cron at 08:25 UTC. The cron exists because `enableGitInfo` populates `Lastmod` from git history, and the vCard's `REV:` line and similar timestamps benefit from periodic refreshes even on quiet days — but I'm inferring that from the code; the cron commit (`5e45aa4`) didn't explain it.

The repo configuration itself is templated by the meta-repo `philoserf/.github` via probot/settings (see `.github/settings.yml`'s `_extends`). Repo description, topics, and homepage are managed there, not by clicking around in GitHub. A maintainer who edits the repo settings in GitHub's UI will be overwritten.

## What changes easily, what doesn't

Easy changes: adding a structural page (drop a markdown file under `content/` and put a menu entry in `hugo.yaml`); updating site identity (one block in `hugo.yaml` flows to every artifact); adding a new home-page output format (the four-step recipe above); updating the conditional-asset gates; adding a shortcode the publisher will emit. The site has been deliberately built so that the _interesting_ changes — what the author writes — happen elsewhere, and the local changes are small and boring.

Hard changes, the ones where you should slow down: introducing per-post mutable state in the repo (analytics IDs, view counts, comment threads) will fight the publisher's overwrite; introducing taxonomies will fight the explicit `taxonomies: {}`; introducing a second authoring source alongside the publisher will require deciding what happens when the two collide in `content/posts/`; adding a build step that mutates the published markdown will break the publisher's idempotence assumption. A maintainer who does not understand that `content/posts/` is downstream output will, sooner or later, lose work to a publish.

A maintainer who _does_ understand the theory will look first at `hugo.yaml` for identity, `layouts/_default/` for page kinds, `layouts/index.*` for the multi-format home page, and `archetypes/` to understand the publication-date semantics. A maintainer who doesn't will look at `content/posts/` and conclude the site is a normal Hugo blog where you edit your essays in place.

## Uncertainties and tensions

I'm inferring intent in several places.

The daily cron on the deploy workflow has no commit message explaining its purpose; my reading (refresh `Lastmod` and vCard `REV:`) is plausible but not confirmed.

The `notAlternative: true` flag on the three custom output formats is consistent with "do not advertise these in the HTML head as alternate representations," but I haven't seen a written rationale. I think it's deliberate.

The vCard at `layouts/index.vcard.vcf` publishes a home address, personal mobile, and date of birth. The author has confirmed this is intentional — the vCard is a deliberate, full-fidelity contact card, not an oversight. A code audit that flags it has already been dismissed twice; the decision stands.

CLAUDE.md mentions a divergence between local `task build` (`hugo --minify`) and the deploy workflow (`hugo --gc --minify`) and calls it "harmless." That's plausible, but it does mean strictness is not symmetric across environments. The local `task check` is what catches build warnings; `task build` will not.

Finally, the previous `THEORY.md` was deleted as stale in `be91736`. CLAUDE.md absorbed what was kept. The fact that the author has already gone through one cycle of writing and discarding a theory document is itself a signal: this theory will go stale too. The parts most likely to remain true are the ones rooted in the publisher relationship and the archetype asymmetry. The parts most likely to drift are the specific output formats and shortcodes.
