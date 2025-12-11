# Contributing to philoserf.com

Thank you for your interest in contributing! This document provides guidelines
for contributing to this Hugo-based personal website.

## Getting Started

### Prerequisites

- macOS (for Homebrew-based setup)
- [Homebrew](https://brew.sh/) package manager
- Git for version control

### Local Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/philoserf/site.git
   cd site
   ```

2. **Install dependencies**

   ```bash
   task bootstrap
   ```

   This installs: Hugo, Prettier, markdownlint-cli, go-task, gh (GitHub CLI)

3. **Update theme submodule**

   ```bash
   git submodule update --init --recursive
   ```

4. **Start local development server**

   ```bash
   task serve
   ```

   Opens at <http://localhost:1313> with live reload

## Development Workflow

### Available Commands

All development uses [Task](https://taskfile.dev) for command orchestration:

- `task build` - Build the Hugo site with drafts, future posts, and expired
  content
- `task serve` - Start local development server with live reload
- `task fix` - Auto-fix formatting with Prettier and markdownlint
- `task validate-content` - Validate frontmatter completeness and consistency
- `task validate` - Run all validation checks
- `task optimize-images` - Optimize images in static/images directory
- `task update` - Update hugo-coder theme to latest version
- `task bootstrap` - Install tools via Homebrew
- `task commit` - Interactive commit workflow (requires non-main branch)

Run `task --list` to see all available tasks with descriptions.

### Creating New Content

**Use Hugo's archetype system:**

```bash
hugo new content/posts/my-new-post.md
```

This generates a new post with proper frontmatter template.

**Required frontmatter fields:**

```yaml
---
title: Post Title
date: 2025-12-10
lastmod: 2025-12-10
description: Brief description for SEO and previews
tags:
  - tag1
  - tag2
publish: true
---
```

**Frontmatter field order (standard):**

1. title
2. date
3. lastmod
4. description
5. tags
6. publish

**Tagging conventions:**

- Use lowercase with hyphens (kebab-case)
- Examples: `personal-development`, `philosophy`, `productivity`
- Be specific but avoid over-tagging (2-5 tags per post)

### Making Changes

1. **Create a feature branch**

   ```bash
   git checkout -b feature/my-changes
   ```

   Never commit directly to `main` - this is enforced by the commit task.

2. **Make your changes**
   - Edit content in `content/posts/`
   - Follow existing patterns and conventions
   - Test locally with `task serve`

3. **Format and lint**

   ```bash
   task fix
   ```

   This runs automatically via pre-commit hook, but you can run manually.

4. **Validate content** (optional)

   ```bash
   task validate
   ```

5. **Commit your changes**

   ```bash
   task commit
   ```

   This task:
   - Verifies you're not on main branch
   - Runs build to ensure it compiles
   - Stages changes interactively
   - Prompts for commit message
   - Pushes to remote

   **Alternative (standard git):**

   ```bash
   git add .
   git commit -m "Your commit message"
   git push
   ```

6. **Create a pull request** Use GitHub web interface or `gh` CLI:

   ```bash
   gh pr create --fill
   ```

## Code Quality Standards

### Formatting

- **Markdown**: Follows markdownlint rules (`.markdownlint.json`)
- **YAML**: 2-space indentation
- **Line endings**: LF (Unix style) - enforced by `.editorconfig`
- **Encoding**: UTF-8 - enforced by `.editorconfig`
- **Trailing whitespace**: Removed automatically
- **Final newline**: Added automatically

### Pre-commit Hooks

A pre-commit hook automatically runs `task fix` before each commit to ensure
code quality. This is enforced at `.git/hooks/pre-commit`.

### Continuous Integration

GitHub Actions automatically:

- Builds the site on every push to main
- Deploys to GitHub Pages
- Runs on daily schedule (3:25 PM UTC)

## Content Guidelines

### Writing Style

- **Tone**: Personal, intellectual, precise
- **Voice**: First-person perspective
- **Length**: Varies from micro-essays (300-600 words) to deep dives (5000+
  words)
- **Structure**: Clear headings, bullet lists for clarity, practical examples

### Content Types

1. **Essays** - Philosophy, personal development, systems thinking
2. **Guides** - Step-by-step instructions with exact measurements/steps
3. **Lists** - Reading lists, references, curated resources
4. **Status pages** - About, Now, Uses pages (updated regularly)

### Internal Linking

Use Hugo's ref shortcode for internal links:

```markdown
See [related post]({{< ref "post-filename" >}})
```

### Images

- Place in `/static/images/`
- Optimize before adding (prefer WebP when possible)
- Reference as `/images/filename.ext`

## Theme Customization

This site uses the [hugo-coder](https://github.com/luizdepra/hugo-coder) theme
as a Git submodule.

**To update the theme:**

```bash
task update
```

**Note:** No custom layouts or overrides currently exist. All customization is
done through `hugo.yaml` configuration.

## Commit Message Conventions

No strict convention enforced, but prefer clear, descriptive messages:

**Good examples:**

- `Add post: Exploring Meaning and Power in Modern Systems`
- `Fix typo in about page`
- `Update now page with current reading`
- `Remove orphaned category field from frontmatter`

**Avoid:**

- `WIP` or `test` without context
- `Updates` (too vague)
- Overly long messages (keep first line under 72 characters)

## Pull Request Process

1. **Ensure all checks pass**
   - Build succeeds
   - Links validate (warnings okay, errors should be fixed)
   - Code is formatted

2. **Provide clear PR description**
   - What changed and why
   - Any related issues
   - Testing performed

3. **Wait for review**
   - Claude Code Review may provide automated feedback
   - Address any comments or suggestions

4. **Merge**
   - Squash and merge preferred for clean history
   - Delete branch after merge

## Troubleshooting

### Build fails locally

```bash
# Clean and rebuild
rm -rf public/ resources/_gen/
task build
```

### Theme not loading

```bash
# Update submodules
git submodule update --init --recursive
```

### Pre-commit hook not running

```bash
# Ensure hook is executable
chmod +x .git/hooks/pre-commit
```

### Task command not found

```bash
# Install via Homebrew
brew install go-task
```

## Getting Help

- **Documentation**: See [DEVELOPMENT.md](DEVELOPMENT.md) for architecture
  details
- **Hugo docs**: <https://gohugo.io/documentation/>
- **Theme docs**: <https://github.com/luizdepra/hugo-coder>
- **Issues**: Create a GitHub issue for bugs or questions

## License

Content is licensed under
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

---

**Site motto:** COGITA·DISCE·NECTE·ENUNTIA (Think, Learn, Connect, Articulate)
