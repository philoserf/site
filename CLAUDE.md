# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Commands

All commands use Task (Taskfile.yml). Run `task` or `task help` to see available tasks.

```bash
task setup   # Install dependencies
task dev     # Start development server with drafts and future content
task build   # Build production site with minification
task clean   # Remove generated files
task check   # Verify site builds correctly
task format  # Format code
task new -- path/file.md     # Create new content file
task new:post -- post-title  # Create new blog post
```

## Architecture

- **Config**: hugo.yaml
- **Layouts**: layouts/\_default/baseof.html, index.html, single.html, list.html
- **Content**: content/ directory with posts/ subdirectory
- **Archetypes**: archetypes/default.md (pages — `lastmod` only) and archetypes/posts.md (posts — `date` + `lastmod`); the asymmetry is load-bearing
- **Styling**: static/style.css (CSS variables for theming)
- **Generated text files**: `robots.txt`, `site.webmanifest`, `vcard.vcf`, `llms.txt` render from `layouts/` templates via custom output formats on the home page — do not re-create them under `static/`
- **Build output**: public/ (gitignored), resources/ (gitignored)

## Deployment

Automated to GitHub Pages via GitHub Actions (.github/workflows/deploy.yml):

- Triggers on pushes to `main` and daily at 15:25 UTC
- Builds with `hugo --gc --minify` and `HUGO_ENV=production`
- Deploys via `actions/upload-pages-artifact` + `actions/deploy-pages` (artifact-based; no `gh-pages` branch)

## Notes

- Draft content enabled in dev server (`-D` flag)
- New content starts as drafts
- Production builds use minification
- Formatting: MD013 (line length) disabled
