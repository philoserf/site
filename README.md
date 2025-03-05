# Site

My personal website with occasional article posts.

[![deploy](https://github.com/philoserf/site/actions/workflows/deploy.yml/badge.svg)](https://github.com/philoserf/site/actions/workflows/deploy.yml)
[![fix-markdown-headers](https://github.com/philoserf/site/actions/workflows/fix-markdown-headers.yml/badge.svg)](https://github.com/philoserf/site/actions/workflows/fix-markdown-headers.yml)

## GitHub Actions

### Deploy

Automatically deploys the site when changes are pushed to the main branch.

### Fix Markdown Headers

Automatically fixes markdown files with multiple top-level headings in pull requests by removing the first `# Title` heading, which resolves markdownlint error MD025.
