---
sidebar_position: 9
title: Integrations
---

# Integrations

Nightshift integrates with your existing development workflow.

## AI Providers

Nightshift supports three execution providers. It uses the first enabled provider in `providers.preference`, which defaults to `claude -> codex -> copilot`.

```yaml
providers:
  preference:
    - claude
    - codex
    - copilot
```

### Claude Code

Nightshift uses the Claude Code CLI to execute tasks. Authenticate via subscription or API key:

```bash
claude
/login
```

Relevant config keys:

- `providers.claude.enabled`
- `providers.claude.data_path`
- `providers.claude.dangerously_skip_permissions`

### Codex

Nightshift supports OpenAI's Codex CLI as an alternative provider:

```bash
codex --login
```

Relevant config keys:

- `providers.codex.enabled`
- `providers.codex.data_path`
- `providers.codex.dangerously_bypass_approvals_and_sandbox`

### GitHub Copilot

Nightshift supports GitHub Copilot through either the standalone `copilot` binary or `gh copilot`.

```bash
npm install -g @github/copilot
# or
curl -fsSL https://gh.io/copilot-install | bash
```

Copilot usage is tracked by request count instead of token usage. Nightshift stores that tracking data under `providers.copilot.data_path` (default: `~/.copilot`).

Relevant config keys:

- `providers.copilot.enabled`
- `providers.copilot.data_path`
- `providers.copilot.dangerously_skip_permissions`

## GitHub

All output is PR-based. Nightshift creates branches and pull requests for its findings.

## td (Task Management)

Nightshift can source tasks from [td](https://td.haplab.com) - task management for AI-assisted development. Tasks tagged with `nightshift` in td will be picked up automatically.

```yaml
integrations:
  task_sources:
    - td:
        enabled: true
        teach_agent: true   # Include td usage + core workflow in prompts
```

## CLAUDE.md / AGENTS.md

Nightshift reads project-level instruction files to understand context when executing tasks. Place a `CLAUDE.md` or `AGENTS.md` in your repo root to give Nightshift project-specific guidance. Tasks mentioned in these files get a priority bonus (+2).

## GitHub Issues

Source tasks from GitHub issues labeled with `nightshift`:

```yaml
integrations:
  github_issues:
    enabled: true
    label: "nightshift"
```
