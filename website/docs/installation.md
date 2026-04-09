---
sidebar_position: 2
title: Installation
---

# Installation

## Homebrew (Recommended)

```bash
brew install marcus/tap/nightshift
```

## Binary Downloads

Pre-built binaries are available on the [GitHub releases page](https://github.com/marcus/nightshift/releases) for macOS and Linux (Intel and ARM).

## From Source

Requires Go 1.24+:

```bash
go install github.com/marcus/nightshift/cmd/nightshift@latest
```

Or build from the repository:

```bash
git clone https://github.com/marcus/nightshift.git
cd nightshift
go build -o nightshift ./cmd/nightshift
sudo mv nightshift /usr/local/bin/
```

## Verify Installation

```bash
nightshift --version
nightshift --help
```

## Provider Prerequisites

Nightshift can use Claude Code, Codex, and GitHub Copilot. Install and authenticate the providers you want to use:

### Claude Code

```bash
claude
/login
```

### Codex

```bash
codex --login
```

### GitHub Copilot

Install either the standalone `copilot` binary or the GitHub CLI:

```bash
npm install -g @github/copilot
# or
curl -fsSL https://gh.io/copilot-install | bash
```

Nightshift prefers the standalone `copilot` binary when it is available and falls back to `gh copilot`. Sign in with your GitHub account before running tasks.

## Next Step

Use the guided setup for the fastest path:

```bash
nightshift setup
```

If you prefer to bootstrap manually, create a config first:

```bash
nightshift init
nightshift init --global
```
