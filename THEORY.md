# A theory of philoserf.com

## What the system is for

This repository publishes a private writing practice on a schedule. The author writes in an Obsidian vault. When a piece is finished, it is given a future `date` on the author's Monday–Wednesday–Friday calendar. A publisher plugin (`obsidian-publisher`) delivers it here by pull request, often weeks early. The site keeps it hidden until its date, then releases it. Alongside those pieces are a few pages about the author (About, Now, Uses, two reading lists) that the author edits here directly, and one block of identity data in `hugo.yaml` that every public file draws on.

So the domain has five things in it, and the code maps onto them closely:

- **Posts.** The author's essays, at `content/posts/*.md`, `.Section` `"posts"`. A post belongs to the publisher: this repo receives it and does not author it.
- **Structural pages.** `content/*.md`, edited here by hand.
- **The author's identity.** `hugo.yaml` `params`.
- **The release calendar.** Each post's `date`, together with the time of the most recent build.
- **The publisher.** It appears only as the commits it leaves: "Publish: …" and "Batch Publish: N notes", each a squash-merged PR, since `main` accepts nothing else.

The site has no editorial layer, no taxonomy, no comments, no analytics, and no script in the default page. Most of what makes it distinctive is what it declines to do.

## The build is the clock

The most important idea here sits in no single file. **Hugo's default exclusion of future-dated pages is the release gate, and a rebuild is what moves time forward.** A queued post is fully present in the repository. On 2026-10-13, 29 of the 188 posts were dated in the future, the latest 2026-12-16. Nothing hides a queued post except the fact that the last build ran before its date. The live site therefore depends on two inputs, the repository's contents and the time of the last build, and most of the deployment code exists to supply the second.

That is the job of the daily Cron Trigger in `wrangler.jsonc`. It calls `worker.js`'s `scheduled` handler, which POSTs the Worker's own deploy hook (the secret `DEPLOY_HOOK`). Workers Builds then rebuilds, and whatever has come due appears. The cron is not a cache refresh. Remove it and the site freezes at its last push. An earlier version of this document guessed that the cron kept the vCard's `REV:` timestamp fresh. That guess was wrong: the vault's pipeline note and every current comment say the cron exists for future-dated posts.

Several features exist only because of the queue:

- **Two passes in `build.command`.** The first runs `hugo --buildFuture -D --renderToMemory --panicOnWarning` and renders queued posts and drafts in memory. The second renders the live site. Without the first pass, a queued post that breaks a template would be rendered for the first time by an unattended cron build on its release morning. With it, the PR that delivers the post fails (#899). The two passes see different page sets, and each can fail where the other passes. `resolve-pagerefs.html` calls `errorf` on a home-page `featured` or `startHere` ref that resolves to nothing. A ref to a queued post passes the first pass and fails the second, because `site.GetPage` cannot find a page the build excluded. Home-page curation may point only at live posts. `task check` runs both passes locally (#950).
- **A failed build stops the clock, not the site.** Workers Builds keeps serving the previous version, so nothing visible breaks: a post simply doesn't appear on its date. The deploy hook reports only that it accepted the call. The build's outcome is in the Workers Builds dashboard and nowhere else.
- **The build tools float.** Hugo comes from the dashboard variable `HUGO_VERSION=latest`, and also floats locally through the Brewfile. Both passes of every deploy build run with `--panicOnWarning`. A Hugo release that starts warning about something this site uses will therefore fail the next cron build, with no commit involved. When a post fails to appear on a quiet day, check for that first.
- **Release time is Eastern midnight.** Post dates are date-only, and `hugo.yaml`'s `timeZone: America/Detroit` reads them as local midnight (#954). Until then they were UTC midnight, the evening before. The 09:00 UTC cron (04:00–05:00 Eastern) releases each post on the morning of its date; any build after midnight Eastern releases it sooner.

Dates under the queue need care. `enableGitInfo` with `frontmatter.lastmod: [lastmod, ":git", date, publishDate]` gives each post a `Lastmod` equal to the last commit that changed its bytes. That is when the publisher last delivered it. It is neither when the author last revised it nor when it was released. A batch publish rewrites every note the publisher selects (`status: publish`), and git records only the files that differ. So when the publisher's transform changes, most posts change in one commit and keep that commit's date: 124 posts still carry `bee4d8e`'s timestamp from #874. For a queued post, delivery comes before release, so its `Lastmod` falls before its `Date`. The templates read that as no modification: a post gets `dateModified` and `article:modified_time` only when `Lastmod` is after `Date`, and `layouts/sitemap.xml` writes the later of the two (#948). The one post with a non-ASCII filename gets no git date at all and falls back to its `date` (#974). The `lastmod`-first ordering was added for structural pages (#913). The rule that posts never set `lastmod` is enforced outside this repo, by the publisher's strip list.

## Two owners, one directory each

The publisher writes `content/posts/`. A person writes everything else. That split is the system's main boundary, and it is an odd one, because the publisher can only add and change files. It has no delete path.

Consequences:

- **This repository, not the vault, is where a post is unpublished.** Clearing `status: publish` in the vault stops future deliveries but leaves the file live here until someone deletes it. The history shows this as hand-made "Delete content/posts/…" commits. The set of notes selected in the vault and the set of files here can drift apart, and nothing reconciles them.
- **A post's identity is its filename**, and the filename is the slug of the note's title. Renaming a note publishes a second file under the new slug and leaves the old one in place. #862 removed 167 such orphans in one pass. Once an orphan is deleted, its URL returns 404. No redirect is possible, because the vault's publisher settings strip `aliases`. This holds even though the publisher's own README advises adding the old URL to `aliases` before republishing.
- **Hand edits to a post do not last.** The next batch publish rewrites every selected note, and git records the vault's version over the edit.

What a post contains is decided by a denylist that no repository tracks: `strippedFrontmatterFields` in the vault's `.obsidian/plugins/publisher/data.json`. It currently removes `status`, `lastmod`, `cssclass`, `cssclasses`, `created`, `modified`, `tags`, `strength` and `aliases`. Every post arrives with `title`, `description` and `date`, and three add `math: true`. The publisher hard-requires only `title` and `date`. So the site's tolerance of missing fields is still the interface, not habit. `description.html` falls back from `.Description` to `.Summary` to `params.description`, and every date use is guarded with `.IsZero`. The publisher can change what it sends without asking. No post currently uses that tolerance, since all 188 have a description. Keep it anyway: it is what lets the publisher change without coordinating with this repo.

Structural pages are the opposite case. They carry a hand-set `lastmod`, and four opt into an "Updated" line with `showUpdated: true`, so editing one means bumping its `lastmod`. They are also the only pages that can carry `aliases`. `/posts/now/` and the two `/posts/books-i-…/` aliases preserve URLs from when those pages were posts, before #862 moved them. The two archetypes encode the split: `default.md` sets `lastmod` alone, `posts.md` sets `date` alone. But `archetypes/posts.md` is not how posts arrive, and `task new:post` writes into the directory the publisher owns. The asymmetry now states the model. The mechanism that enforces it is the publisher's strip list together with the `lastmod` chain in `hugo.yaml`.

## What counts as a post

`eq .Section "posts"` is the site's definition of a post. The home page uses it for featured and recent, `llms.txt` for its Writing list, and `single.html` to choose the "Post" eyebrow, the `<time>`, the continue-reading aside, and `BlogPosting` over `WebPage`.

The predicate matters because Hugo's default `frontmatter.date` chain falls back to `lastmod`, so a structural page has a `.Date` that is really its last-edited date. `single.html` knows this. Its comment says structural pages "have no publish date", and it shows "Updated" in their place. So every place that publishes a publish date applies the predicate as `and .IsPage (eq .Section "posts")` (#949): `og:type` and the `article:*` metas in `baseof.html`, the JSON-LD `datePublished` in `single.html`, and `layouts/index.rss.xml`, the home feed, which lists posts only. Before that, the fallback date leaked out as a publish date, and editing Now pushed it up subscribers' feeds as if it were a new essay. `.IsPage` excludes the `/posts/` archive itself. Anything new that needs to tell posts from pages should use the same predicate.

## Identity is data, and every public file is built from it

`hugo.yaml` `params` holds the author's name, email, motto, theme colors, full contact card and social links. The home page emits five formats from it, listed under `outputs.home`: `html`, `rss`, `llms`, `manifest` and `vcard`. `layouts/robots.txt` adds a sixth file. Changing the author's name changes the page titles, meta author, JSON-LD, `llms.txt`, the web manifest, the vCard and the footer in one edit. A copy of `vcard.vcf`, `site.webmanifest` or `llms.txt` under `static/` would silently replace the generated version, which is why none exists.

Adding a home-page format takes four steps: a media type under `mediaTypes`, an output format with `notAlternative: true` (which keeps it out of `<link rel="alternate">`), an entry in `outputs.home`, and a template at `layouts/index.<format>.<ext>`. `params.themeColor` feeds the `theme-color` metas and the manifest. It must equal `--background-color` in `assets/css/style.css`, and only a comment says so. The motto has one source, `partials/motto.html`, shared by the home page, the `latin-motto` shortcode and the vCard. The vCard publishes a real home address, phone number and birthday on purpose. Its `REV:` field uses the build time, so it now changes every day.

## What `--panicOnWarning` actually buys

Strictness is the closest thing this repository has to a test suite, so be precise about what it catches. A missing shortcode or a broken `relref` fails any Hugo build, strict or not (checked against Hugo 0.167). The flag adds the warnings:

- **Raw HTML that Goldmark leaves out without error.** A note containing inline HTML fails the deploy instead of losing text from the rendered page.
- **Deprecation notices.** These are what make floating Hugo a risk to the clock.

The only `relref` links in the content are Now's links to the two reading lists, which exist so that a broken internal link fails the build. Posts contain no internal links today. When they do, the publisher writes them as absolute `/posts/<slug>/` links, not `relref`. A link to a post someone later deleted would not fail any build. Only `task links` (lychee over `public/`) would find it, and nothing runs that automatically.

There is one definition of the build: `wrangler.jsonc`'s `build.command`. `task deploy` and Workers Builds both run it, and it deliberately carries the two steps the build image needs: unshallow the clone so git dates are real, and `rm -rf public` because Hugo never prunes stale output. Local tasks don't match it exactly. `task check` runs only the live pass, so it skips every queued post. `task build` doesn't clear `public/`, so `task links` run after it can check pages for posts that have since been deleted. #716 set the rule that every serious build runs the same gate. The validate pass came later (#899) and broke that rule for `task check`.

## Contract templates and conditional assets

`layouts/shortcodes/callout.html` and `mermaid.html` are identical to the reference copies in `obsidian-publisher/hugo-shortcodes/`, and `assets/css/callout.css` differs only in Prettier's formatting. The contract is the shortcode names and arguments, which are settings on the publisher side (`calloutShortcodeName`, `mermaidShortcodeName`). No post currently uses either shortcode. They exist so that a future note with a callout or diagram renders instead of failing the build. The loaders belong to the site. Mermaid loads from jsDelivr, pinned to 11.16.0 with an SRI hash, through `partials/mermaid.html`. The site did not adopt the publisher's reference `mermaid.js`, which pins 10.9.1.

Heavy assets load only on the pages that need them: `callout.css` and Mermaid when the page uses that shortcode, KaTeX (pinned 0.16.11, SRI) when `.Params.math` is set. A script added unconditionally to `baseof.html` would break that pattern. The pinning rule is consistent: code that runs in a reader's browser is pinned and hashed, and code that runs at build time floats (Hugo, Wrangler through `bunx`, the Brewfile). The exception is the Worker runtime itself, where `compatibility_date` is pinned.

## Seams

**The publisher's seam** is one-way, carried by PRs, and invisible from inside this repository except in the commit log. The rules governing it are spread across the publisher's code, the vault's plugin settings and this repo's templates, and none of them can see the others.

**Hugo defaults are part of that contract, held by not configuring them.** The publisher assumes `autoIDType: github` and `removePathAccents: false`. Its wikilinks are built from `contentDir`, so they assume a post lives at `/posts/<filename>/`. This site satisfies all three by leaving `hugo.yaml` silent on them. Adding a `permalinks` block, or changing either Markup setting, would break links and anchors the publisher has already written, and nothing on either side would notice.

**Cloudflare holds part of the system outside the repository:** the Workers Builds connection, `HUGO_VERSION`, the deploy hook behind `DEPLOY_HOOK`, preview URLs turned off, and the zone-managed `/.well-known/security.txt`. The README's "Cloudflare settings" section records all of it, and that section is the only way to rebuild the Worker.

**The staging twin.** `philoserf/sandbox` is a copy of this site with placeholder prose and invented contact details. Its `layouts/`, `static/`, `Taskfile.yml` and `worker.js` are meant to stay byte-identical to this repo's. Rendering changes are tried there first: the Workers move and the cron both landed in sandbox before here. CLAUDE.md records the arrangement, and sandbox's README lists the intended differences. Nothing checks that the two stay identical.

**One boundary is an accident.** `layouts/_default/list.html` is the posts archive under the default name. It hard-codes the "Posts" heading and "Published Monday, Wednesday, and Friday". It is the default only because `posts` is the only section and taxonomies are off (`taxonomies: {}`). A second section would inherit the posts archive's heading.

## What the system accommodates, and what it resists

It absorbs easily:

- **Identity changes:** one edit to `params`.
- **A new structural page:** a file under `content/`, a `menus.main` entry, and optionally `llmsSection` to choose its `llms.txt` heading.
- **A new home-page format:** the four-step recipe.
- **A new publisher shortcode:** a template under `layouts/shortcodes/` named to match the publisher's setting, mirrored to sandbox.
- **A heavy dependency:** a conditional partial.
- **A change to the release schedule:** the cron expression, though see the release-time point above.

It resists:

- **Anything that needs per-post state in this repo.** Counts, local edit history and comments would all be overwritten by the next publish.
- **Taxonomies.** `tags` are removed upstream, so this is now a vault settings change before it becomes a layout change. It also needs term pages, a decision about showing tags on posts, and new JSON-LD.
- **Redirects for renamed posts.** These need `aliases` off the strip list. They also need the aliases converted into URL paths: #862 records that a note's old title, passed through as an alias, built literally to `public/posts/Adulthood as Latent Capacity/`.
- **A second content section.** It runs into `list.html`.
- **Changing permalinks or heading IDs.** That breaks the publisher contract above.

A maintainer who understands the theory looks first at `hugo.yaml` for identity and dates, at `build.command` for anything about the build, and at the date of the newest post before suspecting the deploy. A maintainer who doesn't edits a post in place and loses the edit. Or they add a static `llms.txt` and freeze it, point `featured` at tomorrow's post and break the morning build, or move the build into the Taskfile and lose the unshallow step without noticing.

## Uncertainties

- **Why `aliases` is stripped.** I guess the strip was a response to the problem #862 records, aliases that built literally as titles. The vault's pipeline note records only that the strip breaks renames. No record links the two.
- **What happens when a page isn't found.** I have not checked how Cloudflare routes such requests. I take `worker.js`'s comment and #942's manual checks as the record.
- **The publishing cadence.** "Published Monday, Wednesday, and Friday" is a vault convention restated in a template. Recent dates are mostly on those days, with some Tuesdays and Thursdays. The label states an intent, not a constraint.
- **The vault's own theory note.** `~/notes/Publishing pipeline theory.md` is the vault's account of this pipeline. It still describes GitHub Pages, a `notice` shortcode the site lacks and a 15:25 UTC cron, so it is behind this repo. Where the two disagree, read the code.
- **Earlier versions.** Three claims in the version this document replaces were wrong when checked: that the cron existed for the vCard, that a missing shortcode fails only under `--panicOnWarning`, and that a post scaffolded from the wrong archetype renders without a date. Don't recover them from git history. Treat any claim here that depends on a current setting (cron times, pinned versions, the strip list) as something to check, not something to trust. The parts most likely to stay true are the clock, the publisher's add-only ownership, the post predicate and identity as data.
