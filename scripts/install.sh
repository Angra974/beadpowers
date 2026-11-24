#!/usr/bin/env bash
# beadpowers installer for Agent Skills compatible coding agents.
#
# Installs the three beadpowers skills into the global skill directories used by
# Claude Code, Codex CLI, OpenCode, Pi, Freebuff, Cursor, Gemini CLI, Cline, Zed
# and other agents that read .agents/skills. Project mode also drops a managed
# block into AGENTS.md so agents without a skill loader can still find the skills.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="${REPO_ROOT}/skills"
MANIFEST_NAME=".beadpowers"
BLOCK_START="<!-- beadpowers:start -->"
BLOCK_END="<!-- beadpowers:end -->"

MODE="global"
PROJECT_DIR=""
LINK_MODE="symlink"
LINK_MODE_SET=0
FORCE=0
UNINSTALL=0

usage() {
  cat <<'EOF'
beadpowers installer

Installs the brainstorming, create-beads and using-beadpowers skills so every
coding agent on this machine can discover them.

Usage:
  scripts/install.sh                     Install for the current user (global)
  scripts/install.sh --project [DIR]     Install into a project (default: cwd)
  scripts/install.sh --copy              Copy skills (default in project mode)
  scripts/install.sh --symlink           Symlink skills (default in global mode)
  scripts/install.sh --force             Replace conflicting files or links
  scripts/install.sh --uninstall         Remove what this script installed
  scripts/install.sh --help              Show this help

Global targets (only existing/installed agents are touched):
  ~/.agents/skills             Codex CLI, Pi, Cline, Zed, Warp, Amp, ...
  ~/.claude/skills             Claude Code
  ~/.cursor/skills             Cursor
  ~/.gemini/skills             Gemini CLI
  ~/.config/opencode/skills    OpenCode

Project targets:
  <project>/.agents/skills     Codex, OpenCode, Pi, Freebuff, Cursor, Gemini, ...
  <project>/.claude/skills     Claude Code
  <project>/AGENTS.md          Managed beadpowers block (created or appended)

Examples:
  git clone https://github.com/Angra974/beadpowers.git ~/.beadpowers
  ~/.beadpowers/scripts/install.sh
  cd ~/code/my-app && ~/.beadpowers/scripts/install.sh --project
EOF
}

warn() { printf "warning: %s\n" "$*" >&2; }
exists() { [[ -e "$1" || -L "$1" ]]; }

manifest_has() {
  [[ -f "$1" ]] && grep -qxF -- "$2" "$1"
}

is_ours_link() {
  [[ -L "$1" ]] || return 1
  local target
  target="$(readlink "$1")"
  case "$target" in
    "$SKILLS_SRC"/*) return 0 ;;
  esac
  return 1
}

install_one() {
  local name="$1" target="$2"
  local src="${SKILLS_SRC}/${name}"
  local dest="${target}/${name}"
  local manifest="${target}/${MANIFEST_NAME}"
  local ours=0

  manifest_has "$manifest" "$name" && ours=1

  if exists "$dest"; then
    if is_ours_link "$dest" || [[ "$ours" -eq 1 ]]; then
      rm -rf -- "$dest"
    elif [[ "$FORCE" -eq 1 ]]; then
      rm -rf -- "$dest"
    else
      warn "$dest already exists and was not installed by beadpowers; skipping (use --force to replace)"
      return 0
    fi
  fi

  if [[ "$LINK_MODE" == "copy" ]]; then
    cp -R -- "$src" "$dest"
  else
    if ! ln -s -- "$src" "$dest" 2>/dev/null; then
      warn "cannot create symlink at $dest; copying instead"
      cp -R -- "$src" "$dest"
    fi
  fi

  touch "$manifest"
  manifest_has "$manifest" "$name" || printf "%s\n" "$name" >> "$manifest"
  printf "  ok   %s\n" "$dest"
}

uninstall_one() {
  local name="$1" target="$2"
  local dest="${target}/${name}"
  local manifest="${target}/${MANIFEST_NAME}"

  exists "$dest" || return 0

  if is_ours_link "$dest" || manifest_has "$manifest" "$name"; then
    rm -rf -- "$dest"
    printf "  rm   %s\n" "$dest"
  else
    warn "not removing $dest (it is not a beadpowers link)"
  fi
}

project_instruction_files() {
  printf '%s\n' "${PROJECT_DIR}/AGENTS.md" "${PROJECT_DIR}/CLAUDE.md"
}

append_agents_block() {
  local file
  for file in $(project_instruction_files); do
    if [[ -f "$file" ]] && grep -qF -- "$BLOCK_START" "$file"; then
      printf "  ok   %s (beadpowers block already present)\n" "$file"
      continue
    fi

    if [[ -f "$file" && -s "$file" ]]; then
      printf "\n" >> "$file"
    fi

    cat >> "$file" <<'BLOCK'
<!-- beadpowers:start -->
## Beadpowers

This project uses [beadpowers](https://github.com/Angra974/beadpowers) skills for bead-based workflows.

- Before any orchestrated or tracked work, first load `orchestrator-directive` from
  `.agents/skills/orchestrator-directive/SKILL.md`: decision ladder (active work -> `bd memories dec:`
  precedents -> project memory -> prudent default), reversibility rule (commit checkpoint, revert on
  failure), deep search over `bd remember`, and when the human is actually needed.
- Before any creative work (new feature, component, or behavior change), load the `brainstorming`
  skill from `.agents/skills/brainstorming/SKILL.md` (or `.claude/skills/brainstorming/SKILL.md`)
  and follow it exactly.
- When a design is agreed, load `create-beads` from `.agents/skills/create-beads/SKILL.md` to create
  a bead epic and bite-sized child tasks.
- When an `aidd-*` skill runs (AI-Driven Dev framework), or any agent creates, claims, closes or
  reports tracked work, first load `beads-integration` from `.agents/skills/beads-integration/SKILL.md`:
  all tracking goes through `bd` (identity `<tool>-<role>`, claim, provenance, review handoffs),
  never GitHub labels or markdown task files.
- Requires the `bd` CLI (https://github.com/gastownhall/beads). Run `bd init` once per repository.
- Do not write plan documents to `docs/plans/`; track work with `bd create`, `bd ready`, `bd close`.
<!-- beadpowers:end -->
BLOCK

    printf "  add  %s (beadpowers block)\n" "$file"
  done
}

remove_agents_block() {
  local file
  for file in $(project_instruction_files); do
    [[ -f "$file" ]] || continue
    grep -qF -- "$BLOCK_START" "$file" || continue

    local tmp
    tmp="$(mktemp)"
    awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
      $0 == start { skip = 1; next }
      $0 == end   { skip = 0; next }
      !skip       { print }
    ' "$file" > "$tmp"
    mv -- "$tmp" "$file"

    if ! grep -q '[^[:space:]]' "$file"; then
      rm -f -- "$file"
    fi
    printf "  rm   %s (beadpowers block)\n" "$file"
  done
}

# --- parse arguments -------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--global)
      MODE="global"
      ;;
    -p|--project)
      MODE="project"
      if [[ $# -gt 1 && "${2:0:1}" != "-" ]]; then
        PROJECT_DIR="$2"
        shift
      fi
      ;;
    -c|--copy)
      LINK_MODE="copy"
      LINK_MODE_SET=1
      ;;
    -l|--symlink)
      LINK_MODE="symlink"
      LINK_MODE_SET=1
      ;;
    -f|--force)
      FORCE=1
      ;;
    -u|--uninstall)
      UNINSTALL=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf "Unknown argument: %s\n\n" "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

# --- discover skills -------------------------------------------------------

if [[ ! -d "$SKILLS_SRC" ]]; then
  printf "error: skills directory not found at %s\n" "$SKILLS_SRC" >&2
  exit 1
fi

skills=()
for dir in "$SKILLS_SRC"/*/; do
  [[ -f "${dir}SKILL.md" ]] || continue
  skills+=("$(basename "$dir")")
done

if [[ ${#skills[@]} -eq 0 ]]; then
  printf "error: no skills found under %s\n" "$SKILLS_SRC" >&2
  exit 1
fi

# Project installs are vendored copies by default: absolute symlinks into the
# beadpowers clone would break as soon as the repository is cloned elsewhere.
if [[ "$MODE" == "project" && "$LINK_MODE_SET" -eq 0 ]]; then
  LINK_MODE="copy"
fi

# --- resolve targets -------------------------------------------------------

targets=()

if [[ "$MODE" == "project" ]]; then
  PROJECT_DIR="${PROJECT_DIR:-$PWD}"
  mkdir -p -- "$PROJECT_DIR"
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
  targets+=("${PROJECT_DIR}/.agents/skills")
  targets+=("${PROJECT_DIR}/.claude/skills")
else
  targets+=("${HOME}/.agents/skills")

  if command -v claude >/dev/null 2>&1 || [[ -d "${HOME}/.claude" ]]; then
    targets+=("${HOME}/.claude/skills")
  fi
  if command -v cursor >/dev/null 2>&1 || [[ -d "${HOME}/.cursor" ]]; then
    targets+=("${HOME}/.cursor/skills")
  fi
  if command -v gemini >/dev/null 2>&1 || [[ -d "${HOME}/.gemini" ]]; then
    targets+=("${HOME}/.gemini/skills")
  fi
  if command -v opencode >/dev/null 2>&1 || [[ -d "${HOME}/.config/opencode" ]]; then
    targets+=("${HOME}/.config/opencode/skills")
  fi
fi

# --- run -------------------------------------------------------------------

if [[ "$UNINSTALL" -eq 1 ]]; then
  printf "beadpowers: uninstall (%s)\n" "$MODE"
  removed=0
  for target in "${targets[@]}"; do
    [[ -d "$target" ]] || continue
    manifest="${target}/${MANIFEST_NAME}"
    [[ -f "$manifest" ]] || continue
    printf "from %s\n" "$target"
    while IFS= read -r name; do
      [[ -n "$name" ]] || continue
      uninstall_one "$name" "$target"
      removed=$((removed + 1))
    done < "$manifest"
    rm -f -- "$manifest"
    rmdir -- "$target" 2>/dev/null || true
  done
  if [[ "$MODE" == "project" ]]; then
    remove_agents_block
  fi
  printf "Removed %s skill entr%s.\n" "$removed" "$([[ "$removed" -eq 1 ]] && echo "y" || echo "ies")"
  exit 0
fi

printf "beadpowers: installing %s skill(s) (%s mode, %s)\n" "${#skills[@]}" "$MODE" "$LINK_MODE"
if [[ "$MODE" == "project" ]]; then
  printf "project: %s\n" "$PROJECT_DIR"
fi

for target in "${targets[@]}"; do
  mkdir -p -- "$target"
  printf "\n%s\n" "$target"
  for name in "${skills[@]}"; do
    install_one "$name" "$target"
  done
done

if [[ "$MODE" == "project" ]]; then
  printf "\n%s\n" "${PROJECT_DIR}/AGENTS.md"
  append_agents_block
fi

printf "\nDone. Restart your coding agent so it discovers the skills.\n"

if ! command -v bd >/dev/null 2>&1; then
  printf "\nNote: the bd (beads) CLI is not installed yet. Install it and run \`bd init\` in each project.\n"
  printf "See README.md or https://github.com/gastownhall/beads\n"
fi

printf "\nInvoke the skills:\n"
printf "  Claude Code   /brainstorming        (or /beadpowers:brainstorm with the plugin)\n"
printf "  OpenCode      @brainstorming        (or ask to use the brainstorming skill)\n"
printf "  Freebuff      /skill:brainstorming\n"
printf "  Codex, Pi, Gemini and others: ask to use the brainstorming skill.\n"
