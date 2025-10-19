# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hugo-based personal website for Mark Ayers (philoserf.com). It uses the hugo-coder theme and focuses on personal essays, professional journey, and technical preferences. The site motto is "COGITA·DISCE·NECTE·ENUNTIA" (Think, Learn, Connect, Articulate).

## Development Commands

All development uses [Task](https://taskfile.dev) for command orchestration:

- **Build site**: `task build` - Builds the Hugo site with drafts, future posts, and expired content
- **Local development server**: `task serve` - Runs Hugo server with live reload
- **Format/lint code**: `task fix` - Runs Prettier and markdownlint with auto-fix
- **Update theme**: `task update` - Updates the hugo-coder theme submodule to latest version
- **Bootstrap dependencies**: `task bootstrap` - Installs tools via Homebrew (macOS only)
- **Commit workflow**: `task commit` - Interactive commit process (only works on non-main branches)

Raw Hugo commands (if needed):

- Build: `hugo --cleanDestinationDir --buildFuture --buildDrafts --buildExpired`
- Serve: `hugo server --buildDrafts --buildFuture --buildExpired --disableFastRender --navigateToChanged`

## Architecture

**Static Site Generator**: Hugo (Go-based)

- Configuration: `hugo.yaml` (YAML format, 2-space indentation)
- Theme: hugo-coder (located in `themes/hugo-coder/` as submodule)
- Content: Markdown files in `content/posts/`
- Static assets: `static/` directory
- Build output: `public/` directory

**Content Structure**:

- All content lives in `content/posts/`
- Content frontmatter requires: `title`, `date`
- Uses Hugo's taxonomy system with tags

**Workflow**:

- Never commit directly to `main` branch (enforced by `task commit`)
- All changes must pass through Prettier and markdownlint before commit
- Build artifacts are generated in `public/` directory

## Code Style

- **Markdown**: Follows markdownlint rules (`.markdownlint.json`)
- **YAML**: 2-space indentation (see `.yamllint`)
- **Filenames**: kebab-case for content files
- **Formatting**: Prettier handles all file formatting
- **Tone**: Consistent personal voice across content

## Key Files

- `hugo.yaml`: Site configuration, menus, params, and social links
- `taskfile.yml`: All build and development commands
- `Brewfile`: macOS dependencies (Hugo, Prettier, markdownlint)
- `.gitmodules`: Hugo theme as Git submodule

## Hugo-Specific Notes

- Unsafe HTML rendering is enabled in goldmark (for inline HTML in Markdown)
- Site builds include drafts, future posts, and expired content by default
- Color scheme is set to auto (respects system preference)
