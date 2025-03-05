# CLAUDE.md - Guide for Agentic Coding Assistants

## Build & Development Commands

- Build site: `task build` (or `hugo --cleanDestinationDir --buildFuture --buildDrafts --buildExpired`)
- Run local server: `task serve` (or `hugo server --buildDrafts --buildFuture --buildExpired --disableFastRender --navigateToChanged`)
- Fix formatting: `task fix` (runs prettier and markdownlint)
- Commit changes: `task commit` (interactive process)

## Code Style Guidelines

- Content files: Use Markdown in `/content/` directory
- Prefer semantic HTML in templates (layouts directory)
- Follow Hugo template conventions in layout files
- YAML formatting: Use 2-space indentation in hugo.yaml
- CSS: Use SCSS with BEM-like naming in assets/scss
- Filenames: Use kebab-case for content files
- Content frontmatter: Required fields include title, date

## Error Handling

- Follow Hugo's error handling practices
- Use proper task dependencies in taskfile.yml

## Content Guidelines

- Personal website with occasional article posts
- Maintain consistent tone across content
- All changes run through Prettier and markdownlint before commit
