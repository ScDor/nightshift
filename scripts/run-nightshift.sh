#!/usr/bin/env bash
set -euo pipefail

# Ensure ~/.local/bin is on PATH (where we install nightshift)
export PATH="${HOME}/.local/bin:${PATH}"

# Ensure jq is available for report parsing
if ! command -v jq &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq jq
  elif command -v brew &>/dev/null; then
    brew install jq
  elif command -v yum &>/dev/null; then
    sudo yum install -y jq
  fi
fi

# Generate config, run nightshift, and write GitHub Action outputs

PROVIDERS="${PROVIDERS:-claude}"
CONFIG="${CONFIG:-}"
CONFIG_PATH="${CONFIG_PATH:-}"
PROJECT_PATH="${PROJECT_PATH:-.}"
MAX_PROJECTS="${MAX_PROJECTS:-1}"
MAX_TASKS="${MAX_TASKS:-1}"
TASK="${TASK:-}"
DRY_RUN="${DRY_RUN:-false}"
IGNORE_BUDGET="${IGNORE_BUDGET:-false}"

# Expand project path to absolute
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)

# Generate config if not provided
CONFIG_FILE=""
CLEANUP_CONFIG=false

if [[ -n "$CONFIG_PATH" && -f "$CONFIG_PATH" ]]; then
  echo "Using existing config: $CONFIG_PATH"
  CONFIG_FILE="$CONFIG_PATH"
elif [[ -n "$CONFIG" ]]; then
  CONFIG_FILE="${PROJECT_PATH}/nightshift.yaml"
  echo "$CONFIG" > "$CONFIG_FILE"
  CLEANUP_CONFIG=true
  echo "Using inline config (written to project dir)"
else
  CONFIG_FILE="${PROJECT_PATH}/nightshift.yaml"
  CLEANUP_CONFIG=true
  echo "Generating default config..."

  # Build provider preference list
  IFS=',' read -ra PROVIDER_LIST <<< "$PROVIDERS"
  PREF_ARRAY=""
  for p in "${PROVIDER_LIST[@]}"; do
    p=$(echo "$p" | xargs | tr '[:upper:]' '[:lower:]')
    PREF_ARRAY="${PREF_ARRAY}    - ${p}
"
  done

  # Build providers block
  PROVIDERS_BLOCK=""
  for p in "${PROVIDER_LIST[@]}"; do
    p=$(echo "$p" | xargs | tr '[:upper:]' '[:lower:]')
    case "$p" in
      claude)
        PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  claude:
    enabled: true
    data_path: \"~/.claude\"
    dangerously_skip_permissions: true
"
        ;;
      codex)
        PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  codex:
    enabled: true
    data_path: \"~/.codex\"
    dangerously_bypass_approvals_and_sandbox: true
"
        ;;
      opencode)
        PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  opencode:
    enabled: true
    data_path: \"~/.opencode\"
"
        ;;
      copilot)
        PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  copilot:
    enabled: true
    data_path: \"~/.copilot\"
"
        ;;
    esac
  done

  cat > "$CONFIG_FILE" <<EOF
providers:
  preference:
${PREF_ARRAY}${PROVIDERS_BLOCK}projects:
  - path: "${PROJECT_PATH}"
EOF
fi

echo "Config file:"
cat "$CONFIG_FILE"

# Build run command
RUN_ARGS=(
  "run"
  "--yes"
  "--max-projects" "$MAX_PROJECTS"
  "--max-tasks" "$MAX_TASKS"
  "--project" "$PROJECT_PATH"
)

if [[ -n "$TASK" ]]; then
  RUN_ARGS+=("--task" "$TASK")
fi

if [[ "$DRY_RUN" == "true" ]]; then
  RUN_ARGS+=("--dry-run")
fi

if [[ "$IGNORE_BUDGET" == "true" ]]; then
  RUN_ARGS+=("--ignore-budget")
fi

echo "Running: nightshift ${RUN_ARGS[*]}"
nightshift "${RUN_ARGS[@]}"

# Clean up generated config if we created it
if [[ "$CLEANUP_CONFIG" == "true" && -f "${PROJECT_PATH}/nightshift.yaml" ]]; then
  rm -f "${PROJECT_PATH}/nightshift.yaml"
fi

# Extract outputs from the latest run report
REPORTS_DIR="${HOME}/.local/share/nightshift/reports"
if [[ -d "$REPORTS_DIR" ]]; then
  LATEST_REPORT=$(find "$REPORTS_DIR" -name 'run-*.json' -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
  if [[ -z "$LATEST_REPORT" ]]; then
    # macOS fallback (no -printf)
    LATEST_REPORT=$(ls -t "$REPORTS_DIR"/run-*.json 2>/dev/null | head -1 || true)
  fi

  if [[ -n "$LATEST_REPORT" && -f "$LATEST_REPORT" ]]; then
    echo "Parsing report: $LATEST_REPORT"

    if command -v jq &>/dev/null; then
      PR_URL=$(jq -r '[.tasks[] | select(.output_type=="PR" and .output_ref != null and .output_ref != "") | .output_ref] | first // ""' "$LATEST_REPORT")
      COMPLETED=$(jq '[.tasks[] | select(.status=="completed")] | length' "$LATEST_REPORT")
      FAILED=$(jq '[.tasks[] | select(.status=="failed")] | length' "$LATEST_REPORT")
      SKIPPED=$(jq '[.tasks[] | select(.status=="skipped")] | length' "$LATEST_REPORT")
    else
      echo "Warning: jq not found, falling back to basic parsing" >&2
      PR_URL=""
      COMPLETED=$(grep -c '"status": "completed"' "$LATEST_REPORT" || true)
      FAILED=$(grep -c '"status": "failed"' "$LATEST_REPORT" || true)
      SKIPPED=$(grep -c '"status": "skipped"' "$LATEST_REPORT" || true)
    fi

    SUMMARY="${COMPLETED} completed, ${FAILED} failed, ${SKIPPED} skipped"

    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
      {
        echo "pr-url=${PR_URL}"
        echo "report-path=${LATEST_REPORT}"
        echo "tasks-completed=${COMPLETED}"
        echo "tasks-failed=${FAILED}"
        echo "summary=${SUMMARY}"
      } >> "$GITHUB_OUTPUT"
    fi

    echo "Outputs:"
    echo "  pr-url: ${PR_URL}"
    echo "  report-path: ${LATEST_REPORT}"
    echo "  tasks-completed: ${COMPLETED}"
    echo "  tasks-failed: ${FAILED}"
    echo "  summary: ${SUMMARY}"
  else
    echo "No run report found"
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
      echo "pr-url=" >> "$GITHUB_OUTPUT"
      echo "report-path=" >> "$GITHUB_OUTPUT"
      echo "tasks-completed=0" >> "$GITHUB_OUTPUT"
      echo "tasks-failed=0" >> "$GITHUB_OUTPUT"
      echo "summary=no report generated" >> "$GITHUB_OUTPUT"
    fi
  fi
else
  echo "Reports directory not found"
fi
