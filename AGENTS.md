# AGENTS.md

## Project Overview

Hugo-based personal website for Mark Ayers (philoserf.com). Uses the hugo-coder theme for personal essays, professional journey, and technical preferences. Site motto: "COGITA·DISCE·NECTE·ENUNTIA" (Think, Learn, Connect, Articulate).

## Development Commands

All development uses [Task](https://taskfile.dev) for command orchestration:

- `task build` — Build site with drafts, future posts, and expired content
- `task serve` — Local dev server with live reload
- `task fix` — Auto-fix formatting (Prettier)
- `task optimize-images` — Optimize PNGs and JPEGs in `static/images/`
- `task update` — Update hugo-coder theme submodule
- `task bootstrap` — Install tools via Homebrew (macOS only)
- `task commit` — Interactive commit workflow (non-main branches only)

## Architecture

**Static Site Generator**: Hugo (Go-based)

- Configuration: `hugo.yaml` (YAML format, 2-space indentation)
- Theme: hugo-coder (in `themes/hugo-coder/` as Git submodule)
- Content: Markdown files in `content/posts/`
- Static assets: `static/` directory
- Build output: `public/` directory
- Uses Hugo's taxonomy system with tags
- Unsafe HTML rendering enabled in goldmark
- Color scheme set to auto (respects system preference)

## Deployment

GitHub Pages via GitHub Actions (`deploy.yml`):

- Triggers on push to `main` and daily at 15:25 UTC
- Production builds use `hugo --gc --minify` (no drafts, future, or expired content)
- Local `task build` and `task serve` include drafts/future/expired — production does not

## Code Style

- **YAML**: 2-space indentation
- **Filenames**: kebab-case for content files
- **Formatting**: Prettier handles all file formatting

## Git Workflow

- Never commit directly to `main` branch (enforced by `task commit`)
- All changes must pass through Prettier before commit
