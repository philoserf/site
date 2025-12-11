# Development Guide

This document provides architecture details and technical information for
developers working on philoserf.com.

## Architecture Overview

### Technology Stack

- **Static Site Generator**: [Hugo](https://gohugo.io/) (Go-based)
- **Theme**: [hugo-coder](https://github.com/luizdepra/hugo-coder) (Git
  submodule)
- **Configuration**: YAML (hugo.yaml)
- **Content**: Markdown with YAML frontmatter
- **Hosting**: GitHub Pages
- **CI/CD**: GitHub Actions
- **Build Tool**: [Task](https://taskfile.dev)

### Project Structure

```text
/Users/markayers/source/mine/site/
├── .github/
│   ├── workflows/
│   │   ├── deploy.yml           # Main deployment workflow
│   │   ├── claude.yml           # Claude Code integration
│   │   └── claude-code-review.yml # PR review automation
│   └── dependabot.yml           # Dependency updates
├── content/
│   └── posts/                   # All content (38 markdown files)
├── static/
│   ├── images/                  # Avatar, favicons, icons
│   ├── fonts/                   # FontAwesome files
│   ├── CNAME                    # GitHub Pages domain
│   ├── robots.txt               # SEO robots
│   ├── site.webmanifest         # PWA manifest
│   └── vcard.vcf                # Contact card
├── themes/
│   └── hugo-coder/              # Theme submodule
├── public/                      # Build output (generated)
├── resources/_gen/              # Hugo cache (generated)
├── hugo.yaml                    # Hugo configuration
├── taskfile.yml                 # Task definitions
├── Brewfile                     # macOS dependencies
├── .prettierrc.json             # Prettier config
├── .editorconfig                # Editor settings
├── .markdownlint.json           # Markdown linting
├── .yamllint                    # YAML linting
├── CLAUDE.md                    # Claude Code instructions
├── CONTRIBUTING.md              # Contributor guide
└── DEVELOPMENT.md               # This file
```

### Content Organization

**Philosophy**: Flat structure, minimal complexity

- All posts in single `content/posts/` directory
- No subdirectories or page bundles
- Each post is standalone markdown file
- Static assets in global `/static/` directory

**Special Pages** (with URL aliases):

- `about.md` → `/about`
- `now.md` → `/now`
- `uses.md` → `/uses`

**Content Types**:

1. Core identity posts (3): About, Now, Uses
2. Essays & long-form (25+): Philosophy, systems thinking, personal development
3. Lists & references (5+): Reading lists, guides
4. Practical guides (5+): Recipes, procedures with exact steps

### Hugo Configuration

**Site Settings** (hugo.yaml):

```yaml
title: Mark Ayers
baseURL: https://philoserf.com/
theme: hugo-coder
colorScheme: auto # System preference
```

**Key Parameters**:

- `author`: Mark Ayers
- `since`: 2005
- `info`: Tagline with motto
- `license`: CC BY-NC-SA 4.0
- `avatarURL`: /images/avatar.jpeg

**Taxonomies**:

- Single taxonomy: `tags`
- 40+ unique tags
- Kebab-case naming convention

**Markup Settings**:

- Goldmark renderer with unsafe HTML enabled
- Allows inline HTML in markdown

**Social Links**:

- GitHub, Mastodon, Bluesky configured

## Build Process

### Local Development Build

```bash
hugo --cleanDestinationDir --buildFuture --buildDrafts --buildExpired
```

**Flags explained**:

- `--cleanDestinationDir` - Removes obsolete files from public/
- `--buildFuture` - Includes posts dated in future
- `--buildDrafts` - Includes draft posts
- `--buildExpired` - Includes expired content

### Production Build (CI)

```bash
hugo --gc --minify
```

**Flags explained**:

- `--gc` - Garbage collection (cleanup unused cache)
- `--minify` - Minifies HTML, CSS, JS

**Hugo Version**: 0.151.2 (pinned in CI)

### Build Artifacts

**Generated directories**:

- `public/` - Complete static site ready for deployment
- `resources/_gen/` - Hugo cache (images, CSS, JS processing)

**Build output structure**:

```text
public/
├── index.xml           # RSS feed
├── sitemap.xml         # XML sitemap
├── posts/              # Post archives and pages
├── tags/               # Tag-based navigation
├── about/              # Aliased pages
├── now/
├── uses/
├── fonts/              # Static assets
├── images/
└── [metadata files]    # CNAME, robots.txt, etc.
```

## Development Workflow

### Task Automation

All commands orchestrated via `taskfile.yml`:

| Task             | Dependencies     | Purpose                        |
| ---------------- | ---------------- | ------------------------------ |
| default          | build            | Default task (runs build)      |
| bootstrap        | none             | Installs Homebrew dependencies |
| build            | bootstrap        | Builds Hugo site               |
| serve            | bootstrap        | Local dev server               |
| fix              | bootstrap        | Runs formatters/linters        |
| validate-content | none             | Validates frontmatter          |
| validate         | validate-content | Runs all validation checks     |
| optimize-images  | bootstrap        | Optimizes images               |
| update           | none             | Updates theme submodule        |
| commit           | bootstrap, build | Interactive commit workflow    |

**Task Features**:

- Dependency management (auto-runs prerequisites)
- Source/generates tracking (smart rebuilds)
- Interactive mode support (for commit task)

### Pre-commit Hooks

**Location**: `.git/hooks/pre-commit`

**Behavior**:

1. Runs `task fix` (Prettier + markdownlint)
2. Auto-stages formatting changes
3. Allows commit to proceed

**Note**: Hook is repository-local, not version-controlled. New clones need
manual setup.

### Code Quality Tools

**Prettier**:

- Prose wrapping at 80 characters
- 2-space indentation
- No semicolons
- Double quotes
- ES5 trailing commas

**Markdownlint** (.markdownlint.json):

- Default rules enabled
- MD013 disabled (line length - handled by Prettier)
- MD033 disabled (inline HTML - needed for Hugo)

**EditorConfig** (.editorconfig):

- UTF-8 encoding
- LF line endings
- Trim trailing whitespace
- Insert final newline
- 2-space indent for Markdown/YAML
- Tab indent for Go

## CI/CD Pipeline

### Deployment Workflow (.github/workflows/deploy.yml)

**Triggers**:

- Push to main branch
- Manual dispatch (workflow_dispatch)
- Daily schedule: 3:25 PM UTC

**Jobs**:

1. **Build Job**
   - Checkout with submodules
   - Install Hugo 0.151.2
   - Build with `--gc --minify`
   - Upload artifact

2. **Deploy Job**
   - Deploy to GitHub Pages
   - Uses OIDC authentication
   - Updates site at <https://philoserf.com>

**Permissions**:

- `contents: read` - Read repository
- `pages: write` - Deploy to Pages
- `id-token: write` - OIDC auth

**Concurrency**: Only one deployment at a time (cancel-in-progress: false)

### Claude Code Integration

**Claude Workflow** (.github/workflows/claude.yml):

- Triggers on comments mentioning @claude
- Provides AI assistance on issues/PRs

**Claude Code Review** (.github/workflows/claude-code-review.yml):

- Runs on PR open/sync
- Reviews code quality, bugs, performance
- Posts feedback directly on PRs
- Currently optional/configured

### Dependabot

**Configuration** (.github/dependabot.yml):

- Updates GitHub Actions weekly
- Updates Git submodules (theme) weekly

## Theme Management

### Hugo Coder Theme

**Repository**: <https://github.com/luizdepra/hugo-coder.git> **Integration**: Git
submodule at `themes/hugo-coder/`

**Update theme**:

```bash
task update
# or
git submodule update --remote --merge
```

**Customization approach**:

- No custom layouts/partials/shortcodes
- All customization via hugo.yaml parameters
- Minimizes maintenance burden

**If custom layouts needed**: Create overrides in root `/layouts/` directory
(currently empty).

## Content Management

### Frontmatter Schema

**Required fields**:

```yaml
title: string # Post title
date: YYYY-MM-DD # Publication date
lastmod: YYYY-MM-DD # Last modification date
description: string # SEO/preview description
tags: array # List of tags
publish: boolean # Publication flag
```

**Optional fields**:

```yaml
aliases: array # URL redirects (for special pages)
math: boolean # Enable KaTeX math rendering
summary: string # Custom summary (overrides description)
```

**Standard field order**:

1. title
2. date
3. lastmod
4. description
5. tags
6. publish
7. (optional fields)

### Taxonomy System

**Single taxonomy**: tags

**Tag conventions**:

- Lowercase with hyphens (kebab-case)
- 2-5 tags per post (avoid over-tagging)
- Top tags: personal-development (8), philosophy (7), lifestyle (7),
  productivity (6)

**Tag pages**: Auto-generated by Hugo at `/tags/<tag-name>/`

### Internal Linking

**Use Hugo ref shortcode**:

```markdown
See [related post]({{< ref "filename" >}})
```

**Benefits**:

- Build-time link validation
- Relative path resolution
- Automatic updates if URLs change

**Example** (from sleep-move-eat-grow-play-share.md):

```markdown
[Sleep]({{< ref "sleep" >}})
```

### Content Patterns

**Hub pages**: Central pages linking to series

- Example: `sleep-move-eat-grow-play-share.md` links to 6 practice posts
- Consider for: Think/Do/Be series, Maker/Manager/Consumer series

**Cross-linking**: Encourage related post connections

**Frontmatter consistency**: Use archetype or manual standard order

## Troubleshooting

### Build Failures

**Hugo version mismatch**:

```bash
hugo version  # Check local version
# Update Brewfile if needed
brew upgrade hugo
```

**Theme missing**:

```bash
git submodule update --init --recursive
```

**Cache corruption**:

```bash
rm -rf resources/_gen/
task build
```

### Link Validation Issues

**False positives** (tag pages, external links):

- Add to `--ignore-urls` regex in taskfile.yml
- Or mark as expected in CI logs

**Actual broken links**:

- Check file exists: `ls content/posts/target-file.md`
- Verify ref syntax: `{{< ref "filename" >}}`

### Git Submodule Issues

**Submodule not updating**:

```bash
cd themes/hugo-coder
git fetch
git checkout main
git pull
cd ../..
git add themes/hugo-coder
git commit -m "Update theme"
```

**Submodule detached HEAD**: This is normal for submodules. Don't worry unless
making theme changes.

### Pre-commit Hook Not Running

**Check executable bit**:

```bash
ls -l .git/hooks/pre-commit
# Should show: -rwxr-xr-x
chmod +x .git/hooks/pre-commit
```

**Hook failing silently**: Run manually to see errors:

```bash
.git/hooks/pre-commit
```

## Performance Considerations

### Build Performance

**Typical build times**:

- Local (with drafts): ~50-100ms for 38 posts
- CI (minified): ~200-500ms

**Build optimization**:

- Hugo's native Go speed (no Node.js build step)
- Minimal custom processing
- No external API calls during build

### Site Performance

**Optimization strategies**:

- Static site (no server-side processing)
- Minified HTML/CSS/JS in production
- Preloaded fonts (FontAwesome)
- Responsive images (avatar variants)

**Future enhancements** (not yet implemented):

- WebP image conversion
- Image lazy-loading
- Critical CSS inlining
- Service worker caching

## Security Considerations

### Content Security

- All content is static HTML
- No user input/forms
- No JavaScript execution (beyond theme defaults)
- Unsafe HTML enabled only for author control

### Deployment Security

- OIDC authentication (no long-lived tokens)
- Read-only content permissions
- Branch protection on main (enforced by task)
- Dependabot for dependency updates

### Secrets Management

- No secrets in repository
- GitHub Actions uses repository secrets
- CNAME is public (not sensitive)

## Testing Strategy

### Current Testing

1. **Build validation**: CI ensures site compiles
2. **Content validation**: Script checks frontmatter completeness
3. **Lint/format**: Prettier, markdownlint enforce standards
4. **Manual testing**: Local serve for visual validation

### Future Testing (Not Yet Implemented)

1. **Accessibility testing**: pa11y-ci or similar
2. **SEO validation**: Check meta tags, Open Graph, Schema.org
3. **Performance testing**: Lighthouse CI for metrics
4. **Visual regression**: Screenshot diff testing

## Monitoring & Analytics

### Current Status

**No analytics configured** - Privacy-focused approach

**Deployment monitoring**:

- GitHub Actions workflow status
- GitHub Pages deployment logs

### Future Considerations

- Privacy-respecting analytics (Plausible, Fathom)
- Uptime monitoring (UptimeRobot, StatusPage)
- Performance monitoring (Lighthouse CI trends)

## Useful Commands

### Hugo Commands

```bash
# Create new post
hugo new content/posts/my-post.md

# Build site
hugo

# Serve locally
hugo server

# Check Hugo version
hugo version

# List all content
hugo list all
```

### Git Commands

```bash
# Check submodule status
git submodule status

# Update all submodules
git submodule update --remote --merge

# View recent commits
git log --oneline -10

# Check for uncommitted changes
git status
```

### Task Commands

```bash
# List all tasks
task --list

# Run specific task
task <task-name>

# Dry run (show what would execute)
task --dry <task-name>
```

## Resources

- **Hugo Documentation**: <https://gohugo.io/documentation/>
- **Hugo Coder Theme**: <https://github.com/luizdepra/hugo-coder>
- **Task Documentation**: <https://taskfile.dev>
- **Prettier**: <https://prettier.io/docs/>
- **Markdownlint**: <https://github.com/DavidAnson/markdownlint>
- **GitHub Pages**: <https://docs.github.com/en/pages>

---

**Last Updated**: 2025-12-10
