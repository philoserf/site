# A Theory of philoserf/site

## What this system is for

This is a publishing apparatus for one person's thinking. Mark Ayers writes essays in Obsidian, and this repository turns those essays into a public website at philoserf.com. The domain is personal authorship — not blogging in the WordPress sense, where the infrastructure mediates a social experience, but closer to a monograph series: finished pieces go in, a rendered site comes out, and the machinery stays out of the way.

The core entity is the **post** — a markdown file with YAML front matter, living in `content/posts/`. There are no other content types. There is no `content/pages/` directory, no shortcode library, no data files. Everything — the About page, the Now page, the Uses page, the essays, the fiction, the reading lists, the life-progress calendar — is a post. Hugo's taxonomy system provides tags and series as the only structural relationships between posts. The navigation menu (`About`, `Now`, `Uses`, `Posts`) is hardcoded in `hugo.yaml`; it points to specific posts, not to generated section pages. The site has no categories. This is a deliberate override of Hugo's defaults (the `taxonomies` block explicitly suppresses the default `categories` taxonomy).

The content divides into roughly four kinds, though the system makes no formal distinction between them:

1. **Structural pages** — About, Now, Uses — that describe the author and are updated in place. These are the ones with aliases (e.g., `/about` redirects to `/posts/about/`).
2. **Framework essays** — the Think/Do/Be and Sleep/Move/Eat/Grow/Play/Share sequences — which are the closest thing to load-bearing architecture in the content. These use Hugo's `series` taxonomy and `ref` shortcodes to form deliberate internal link networks. They are the only content that cross-references other content by design.
3. **Standalone essays** — philosophical, cultural, literary, and technical pieces published on a roughly semi-weekly cadence. These have tags but no `ref` links. They are independent.
4. **Reference posts** — reading lists, the calendar, the life-progress chart — which are maintained as living documents and serve as personal databases more than arguments.

## The organizing ideas

**The theme is borrowed; the site is owned.** The hugo-coder theme (a git submodule, not a fork) provides all base layouts, CSS, and HTML structure. The site overrides it in exactly three places: font loading (`extensions.html` preloads Inter), icon metadata (`custom-icons.html` for favicons and manifest), and a series navigation partial (`series.html` that renders "See also" links on series-tagged posts). Plus one SCSS file that replaces the theme's font stack with self-hosted Inter (body) and EB Garamond (Latin mottos). That's it. Three HTML partials, one SCSS file, and `hugo.yaml`. Every other aspect of layout and behavior comes from the theme. A maintainer's first instinct should be to check what the theme already provides before adding anything to `layouts/`.

**The content is authored elsewhere.** The CLAUDE.md says it plainly: "Content is authored in Obsidian; this repo handles build and deployment only." The commit history confirms this — the dominant commit pattern is `Publish: <title>` or `Publish N notes from Obsidian`, which means content arrives as finished markdown, pushed in bulk. The repo is a deployment target, not an editing environment. The VS Code settings exist for occasional direct edits, not as the primary authoring workflow. This is why there are no draft-stage conventions, no content templates, no editorial workflow in the repo — those live in the Obsidian vault.

**Future-dated posts are scheduled content, not broken data.** Several posts have `date` values in the future (e.g., `identity-as-self-narrative.md` is dated 2026-04-11, `a-canticle-for-leibowitz-legacy-and-endurance.md` is dated 2026-04-16). The local build includes future posts (`--buildFuture`), but production does not (`hugo --gc --minify` with no future flag). Combined with the daily deploy schedule (cron at 15:25 UTC), this creates a scheduled-publishing mechanism: write the post now, set the date to when you want it visible, and the daily build will pick it up automatically. This is the most subtle design decision in the system and the easiest to break �� anyone who adds `--buildFuture` to the deploy workflow, or who doesn't understand why the local dev server shows more posts than production, will disrupt the publishing schedule.

**The Latin mottos are identity, not decoration.** Three Latin phrases appear throughout the site: HOMO·HOMINIS·ESSE ("to be a human being among human beings"), COGITA·DISCE·NECTE·ENUNTIA ("Think, Learn, Connect, Articulate"), and PERCIPE·STRUE·EFFICE ("Perceive, Build, Execute"). They appear on the homepage, the About page, the vCard NOTE field, and as the organizational metaphor that names the personal frameworks. EB Garamond is loaded specifically to render them. Recent commits show careful attention to getting the typography right (removing zero-width spaces, replacing words in the motto). These phrases are not taglines; they are the conceptual vocabulary that organizes the author's thinking. The two framework series (TDB and SMEGPS) are the mottos expressed as essay sequences.

**The `series` taxonomy does real structural work.** Three series exist: `books` (Now, Books I have read, Books I may read), `tdb` (Think, Do, Be, and their parent essay Think Do Be), and `smegps` (Sleep, Move, Eat, Grow, Play, Share, and their parent essay). The series partial generates "See also" navigation between members of a series. This is the only automated cross-referencing on the site. The parent essays (Think Do Be, Sleep Move Eat Grow Play & Share) also contain explicit `ref` shortcode links to their children, creating two layers of navigation: the automated series partial and the handwritten prose links. The relationship between parent and child posts in these frameworks is the tightest coupling in the content — renaming or removing one would break both the partial and the shortcode links.

## The seams

**Site meets theme** at the four override files. This boundary is principled: the site only overrides what the theme cannot configure through `hugo.yaml` params. But there is a visible inconsistency — `extensions.html` lives at `layouts/partials/head/` (the legacy path) while the other two partials live at `layouts/_partials/` (the newer convention). The `.issues` directory documents this as a known problem. Hugo resolves both, but a future edit could create conflicting partials with the same name in different trees without warning.

**Site meets the outside world** at three points: GitHub Pages (the deploy workflow), the Obsidian vault (content arrives as finished markdown), and the vCard/humans.txt/robots.txt static files that expose metadata to scrapers. The deploy workflow is the most sensitive — it has `pages: write` and `id-token: write` permissions and uses a floating tag for a third-party Hugo action. The `.issues` directory flags this too.

**Content meets publication** at the front matter. Every post requires `title`, `description`, `tags`, `date`, and `lastmod`. Some have `aliases` (for URL redirects), `series` (for the taxonomy), and `created` (for when the post was first written, distinct from its publication date). The `created` field appears on only three posts and is not used by any template — it is Obsidian metadata leaking into the repo, carried along because it does no harm. This is the thinnest part of the theory: the front matter schema is implicit, enforced by convention and the Obsidian workflow rather than by Hugo archetypes or any validation. A post missing `description` or `tags` would build but produce a degraded page.

**Automation meets the repo** via Dependabot (weekly checks for GitHub Actions and submodule updates), two Claude Code workflows (interactive `@claude` mentions and automated PR reviews), and the daily deploy cron. These are loosely coupled — the Claude workflows have read-only permissions and cannot merge or deploy.

## What the system accommodates easily, and what it resists

**Easy changes:**

- Adding a new post: drop a markdown file with correct front matter into `content/posts/`. The daily build picks it up. No other files need to change.
- Adding a new tag: just use it in front matter. Hugo generates the taxonomy page automatically.
- Updating a structural page (About, Now, Uses): edit in place, push to main.
- Changing the visual theme: update the submodule pointer. As long as hugo-coder's partial names don't change, the overrides continue to work.
- Adding a new series: use a new `series` value in front matter, write a parent essay with `ref` links to children. The series partial handles the rest.

**Changes that require care:**

- Adding a new menu item: requires editing `hugo.yaml` and deciding whether it points to an existing post or needs a new one. The menu is a curated list, not generated.
- Modifying the series partial: the off-by-one bug documented in `.issues` shows this template has subtle logic. Filter-then-slice, not slice-then-filter.
- Any change to the deploy workflow: the gap between local builds (drafts, future, expired) and production builds (none of these) is load-bearing. Changing build flags changes what's publicly visible.

**Changes that would require rethinking:**

- Introducing a content type other than posts (e.g., projects, notes): Hugo supports this, but the current site assumes everything is a post. The menu, the theme's list templates, the URL structure — all are built around a single `posts` section.
- Moving content authoring into the repo (e.g., adding a CMS, or using Hugo archetypes): the entire workflow assumes Obsidian produces finished markdown. The repo has no templates, no content scaffolding, no editorial tooling.
- Replacing the theme: every override would need to be rebuilt to match the new theme's partial names and SCSS variable conventions. The series partial is the most complex piece and the hardest to port.

## Uncertainties

**The front matter schema.** I see `title`, `description`, `tags`, `date`, `lastmod`, `aliases`, `series`, and `created` used across posts, but I cannot determine from this repo alone which fields are required by the theme versus which are author convention. Some posts have `created`, most don't. The `description` field is present on every post I checked, but I don't know if the theme degrades gracefully without it or produces a broken meta tag.

**The `life-progress-calendar.md` date.** This post has `date: 1962-07-04` — the author's birthday, not a publication date. It is the only post that uses `date` for something other than publication timing. I don't know whether this is intentional (it would sort to the very end of any date-ordered list) or an artifact of how the post was created in Obsidian.

**The Obsidian-to-repo pipeline.** Content arrives as commits, but I cannot see how it gets from the vault to git. The commit messages suggest both manual pushes (`Publish: <title>`) and batch operations (`Publish 91 notes from Obsidian`). Whether there's a script, an Obsidian plugin, or a manual copy-paste workflow is invisible from this side. A maintainer inheriting this system would need to understand that pipeline or be able to reproduce it.

**The `.issues` directory.** Four markdown files documenting known problems. This is not a Hugo convention or a standard tool's output — it appears to be a local practice, likely generated by a Claude Code review session. Whether this is an ongoing convention or a one-time artifact is unclear. The issues are well-observed (the series partial bug, the mixed layout paths, the deploy action pinning, the vCard privacy exposure) and represent genuine maintenance debt.

**The `sleep.md` post.** This post is anomalous. Where every other post in the SMEGPS series is a single sentence or a tight original essay, `sleep.md` is 150 lines of practical sleep advice, much of it quoted from named experts with attributions. It reads like compiled research notes that were published in an earlier style, before the site's voice settled into its current form. I suspect this is legacy content that predates the more disciplined essay format, kept because it's useful rather than because it fits the site's current editorial posture.

**The `created` field.** Only three posts carry it. It seems to track when the piece was first drafted in Obsidian, distinct from its publication `date`. But since no template consumes it, it is metadata in transit ��� meaningful in Obsidian, inert here. A future change to the theme or templates could start consuming it, which would retroactively matter for the 93 posts that lack it.
