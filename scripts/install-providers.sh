#!/usr/bin/env bash
set -euo pipefail

# Install missing provider CLIs based on PROVIDERS env var (comma-separated)

PROVIDERS="${PROVIDERS:-claude}"

install_claude() {
  if command -v claude &>/dev/null; then
    echo "claude already installed"
    return 0
  fi
  echo "Installing Claude Code CLI..."
  if command -v npm &>/dev/null; then
    npm install -g @anthropics/claude-code || true
  fi
  if ! command -v claude &>/dev/null; then
    echo "npm install failed, trying curl installer..."
    curl -fsSL https://claude.ai/install | bash || {
      echo "Warning: failed to install Claude Code CLI" >&2
      return 1
    }
  fi
  echo "claude installed: $(claude --version 2>/dev/null || echo 'version unknown')"
}

install_codex() {
  if command -v codex &>/dev/null; then
    echo "codex already installed"
    return 0
  fi
  echo "Installing Codex CLI..."
  if command -v npm &>/dev/null; then
    npm install -g @openai/codex || {
      echo "Warning: failed to install Codex CLI via npm" >&2
      return 1
    }
  else
    echo "Warning: npm not found, cannot install Codex CLI" >&2
    return 1
  fi
  echo "codex installed: $(codex --version 2>/dev/null || echo 'version unknown')"
}

install_opencode() {
  if command -v opencode &>/dev/null; then
    echo "opencode already installed"
    return 0
  fi
  echo "Installing OpenCode CLI..."
  if command -v npm &>/dev/null; then
    npm install -g opencode-ai || true
  fi
  if ! command -v opencode &>/dev/null; then
    echo "npm install failed, trying curl installer..."
    curl -fsSL https://opencode.ai/install | bash || {
      echo "Warning: failed to install OpenCode CLI" >&2
      return 1
    }
  fi
  echo "opencode installed: $(opencode --version 2>/dev/null || echo 'version unknown')"
}

install_copilot() {
  if command -v gh &>/dev/null; then
    echo "gh already installed"
    return 0
  fi
  echo "Installing GitHub CLI..."
  if command -v apt-get &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
  elif command -v brew &>/dev/null; then
    brew install gh
  elif command -v yum &>/dev/null; then
    sudo yum install -y gh
  else
    # Fallback: download binary directly
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64) ARCH="amd64" ;;
      arm64|aarch64) ARCH="arm64" ;;
    esac
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT
    curl -fsSL -o "${TMPDIR}/gh.tar.gz" "https://github.com/cli/cli/releases/latest/download/gh_${OS}_${ARCH}.tar.gz"
    tar -xzf "${TMPDIR}/gh.tar.gz" -C "$TMPDIR"
    BINARY=$(find "$TMPDIR" -name "gh" -type f | head -1)
    if [[ -n "$BINARY" ]]; then
      mkdir -p "${HOME}/.local/bin"
      cp "$BINARY" "${HOME}/.local/bin/gh"
      chmod +x "${HOME}/.local/bin/gh"
      export PATH="${HOME}/.local/bin:${PATH}"
      if [[ -n "${GITHUB_PATH:-}" ]]; then
        echo "${HOME}/.local/bin" >> "$GITHUB_PATH"
      fi
    fi
  fi
  echo "gh installed: $(gh --version | head -1)"
}

IFS=',' read -ra PROVIDER_LIST <<< "$PROVIDERS"
for provider in "${PROVIDER_LIST[@]}"; do
  provider=$(echo "$provider" | xargs | tr '[:upper:]' '[:lower:]')
  case "$provider" in
    claude)   install_claude ;;
    codex)    install_codex ;;
    opencode) install_opencode ;;
    copilot)  install_copilot ;;
    *)        echo "Unknown provider: $provider" >&2 ;;
  esac
done
