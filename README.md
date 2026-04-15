# philoserf.com

Personal website for Mark Ayers — semi-weekly essays on technology, strategy, and personal development.

**Site motto:** COGITA·DISCE·NECTE·ENUNTIA (Think, Learn, Connect, Articulate)

## Quick Start

```bash
task setup    # Install dependencies via Homebrew
task dev      # Start local dev server (drafts + future content)
task build    # Build production site
```

Visit <http://localhost:1313> for local development.

## Stack

- **Static site generator**: [Hugo](https://gohugo.io/) (Extended)
- **Layouts**: hand-rolled (no theme)
- **Build runner**: [Task](https://taskfile.dev)
- **Formatter**: Prettier via Bun
- **Hosting**: GitHub Pages
- **CI/CD**: GitHub Actions

## Tasks

Run `task` or `task help` to list all tasks.

- `task setup` — install dependencies
- `task dev` — dev server with drafts and future content
- `task build` — production build with minification
- `task check` — verify the site builds
- `task clean` — remove generated files
- `task format` — Prettier auto-format
- `task new -- path/file.md` — scaffold new content
- `task new:post -- post-title` — scaffold new blog post

## Project Structure

```text
.
├── archetypes/          # New-content templates
├── content/             # Markdown content
│   ├── _index.md        # Homepage
│   ├── about.md, now.md, uses.md
│   └── posts/           # Essays
├── layouts/             # Custom Hugo templates
├── static/              # Static assets
├── hugo.yaml            # Hugo configuration
├── Taskfile.yml         # Task definitions
└── public/              # Build output (gitignored)
```

## Workflow

1. Create a feature branch (never commit to `main`)
2. Make your changes
3. Run `task format` to format
4. Commit with a descriptive message
5. Open a pull request

## Deployment

Automatic via GitHub Actions on push to `main`. Built with `hugo --minify`, deployed to GitHub Pages.

## License

- **Code / Config**: [MIT License](LICENSE)
- **Content**: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) © 2023–2026 Mark Ayers. See [CONTENT-LICENSE.md](CONTENT-LICENSE.md).

## Resources

- Hugo documentation: <https://gohugo.io/documentation/>
- Task documentation: <https://taskfile.dev>
