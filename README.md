# philoserf.com

Personal website for Mark Ayers – exploring intersections of technology,
strategy, and personal development.

**Site motto:** COGITA·DISCE·NECTE·ENUNTIA (Think, Learn, Connect, Articulate)

## Quick Start

```bash
# Install dependencies
task bootstrap

# Start development server
task serve

# Build site
task build
```

Visit <http://localhost:1313> for local development.

## Technology Stack

- **Static Site Generator**: [Hugo](https://gohugo.io/) v0.152.2
- **Theme**: [hugo-coder](https://github.com/luizdepra/hugo-coder)
- **Build Tool**: [Task](https://taskfile.dev)
- **Hosting**: GitHub Pages
- **CI/CD**: GitHub Actions

## Available Commands

All development uses Task for command orchestration:

- `task build` - Build the Hugo site
- `task serve` - Start local development server with live reload
- `task fix` - Auto-fix formatting with Prettier and markdownlint
- `task validate-content` - Validate frontmatter completeness
- `task validate` - Run all validation checks
- `task optimize-images` - Optimize images in static/images
- `task update` - Update hugo-coder theme to latest version
- `task bootstrap` - Install tools via Homebrew
- `task commit` - Interactive commit workflow (non-main branches only)

Run `task --list` to see all available tasks with descriptions.

## Project Structure

```text
.
├── content/posts/       # All content (markdown files)
├── static/              # Static assets (images, fonts, etc.)
├── themes/hugo-coder/   # Theme (git submodule)
├── hugo.yaml            # Hugo configuration
├── taskfile.yml         # Task definitions
└── public/              # Build output (generated)
```

## Documentation

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contributor guidelines and setup
  instructions
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Architecture details and technical
  documentation
- **[CLAUDE.md](CLAUDE.md)** - Claude Code integration instructions
- **[CONTENT-LICENSE.md](CONTENT-LICENSE.md)** - Content licensing

## Development Workflow

1. Create a feature branch (never commit to `main`)
2. Make your changes
3. Run `task fix` to format code
4. Run `task validate` to check content
5. Use `task commit` for interactive commit workflow
6. Create a pull request

## Content Guidelines

- All posts in `content/posts/` directory
- Markdown with YAML frontmatter
- Required fields: `title`, `date`, `description`, `tags`, `publish`
- Tags use kebab-case (e.g., `personal-development`)
- Internal links use Hugo ref syntax: `{{< ref "filename" >}}`

## Code Quality

- **Formatting**: Prettier (prose wrap at 80 chars)
- **Linting**: markdownlint
- **Pre-commit**: Auto-runs `task fix` before each commit
- **CI**: GitHub Actions builds and deploys on push to main

## Deployment

Automatic deployment via GitHub Actions:

- **Trigger**: Push to main branch, manual dispatch, or daily at 3:25 PM UTC
- **Process**: Build with Hugo, deploy to GitHub Pages
- **URL**: <https://philoserf.com>

## License

- **Code/Config**: [Unlicense](LICENSE) (public domain)
- **Content**: Copyright © 2023–2025 Mark Ayers. All rights reserved. See
  [CONTENT-LICENSE.md](CONTENT-LICENSE.md)

## Resources

- Hugo Documentation: <https://gohugo.io/documentation/>
- Hugo Coder Theme: <https://github.com/luizdepra/hugo-coder>
- Task Documentation: <https://taskfile.dev>

---

**Built with** [Hugo](https://gohugo.io/) • **Hosted on**
[GitHub Pages](https://pages.github.com/)
