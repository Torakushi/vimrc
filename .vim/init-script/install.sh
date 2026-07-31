#!/usr/bin/env bash
#
# Single entry point for the Vim setup: link dotfiles, install plugins + deps.
# Kept bash 3.2 compatible (macOS /bin/bash): no assoc arrays, no mapfile.

set -euo pipefail

# Repo root, found from the script's own location (works from any cwd)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Where plugins are cloned. Overridable for tests: VIM_PACK_DIR=/tmp/x ./install.sh ...
VIM_PACK_DIR="${VIM_PACK_DIR:-$HOME/.vim/pack}"

DRY_RUN=0
ASSUME_YES=0
PROFILE="full"

# Plugin table. Parallel arrays since bash 3.2 has no assoc arrays.
P_name=(); P_cat=(); P_repo=(); P_prof=(); P_brew=(); P_apt=(); P_note=(); P_loc=(); P_ref=()

# plugin key=value ...  (defaults: prof=full loc=start)
plugin() {
  local name="" cat="" repo="" prof="full" brew="" apt="" note="" loc="start" ref="" kv
  for kv in "$@"; do
    case "$kv" in
      name=*) name="${kv#name=}";;
      cat=*)  cat="${kv#cat=}";;
      repo=*) repo="${kv#repo=}";;
      prof=*) prof="${kv#prof=}";;
      brew=*) brew="${kv#brew=}";;
      apt=*)  apt="${kv#apt=}";;
      note=*) note="${kv#note=}";;
      loc=*)  loc="${kv#loc=}";;
      ref=*)  ref="${kv#ref=}";;
      *) echo "plugin: unknown field '$kv'" >&2; exit 1;;
    esac
  done
  P_name+=("$name"); P_cat+=("$cat"); P_repo+=("$repo"); P_prof+=("$prof"); P_brew+=("$brew")
  P_apt+=("$apt"); P_note+=("$note"); P_loc+=("$loc"); P_ref+=("$ref")
}

plugin name=asyncomplete.vim cat=completion \
  repo=https://github.com/prabirshrestha/asyncomplete.vim.git

plugin name=asyncomplete-lsp.vim cat=completion \
  repo=https://github.com/prabirshrestha/asyncomplete-lsp.vim.git

plugin name=vim-tabby cat=completion loc=opt ref=1.4.0 \
  repo=https://github.com/TabbyML/vim-tabby.git \
  brew=node apt=nodejs \
  note="optional AI completion (lazy, :TabbyOn). needs a tabby server + shell alias, see README 'Dependencies > Tabby'"

plugin name=vim-lsp cat=lsp \
  repo=https://github.com/prabirshrestha/vim-lsp.git

plugin name=vim-lsp-settings cat=lsp brew=node apt=nodejs \
  repo=https://github.com/mattn/vim-lsp-settings.git \
  note="LSP servers install via :LspInstallServer (rust: rustup + rust-analyzer)"

plugin name=fzf.vim cat=fzf prof=full,minimal \
  repo=https://github.com/junegunn/fzf.vim.git \
  brew=fzf,bat,ripgrep,universal-ctags,git-delta \
  apt=fzf,bat,ripgrep,universal-ctags,git-delta

plugin name=nerdtree cat=nerdTree prof=full,minimal \
  repo=https://github.com/preservim/nerdtree.git

plugin name=ale cat=lint \
  repo=https://github.com/dense-analysis/ale.git \
  note="fixers/linters are per project (prettier, eslint)"

plugin name=vim-test cat=test \
  repo=https://github.com/vim-test/vim-test.git \
  note="test runners (jest...) are project-scoped"

plugin name=vim-rooter cat=rooter prof=full,minimal \
  repo=https://github.com/airblade/vim-rooter.git

plugin name=vim-fugitive cat=git prof=full,minimal \
  repo=https://github.com/tpope/vim-fugitive.git

plugin name=vim-surround cat=edit prof=full,minimal \
  repo=https://github.com/tpope/vim-surround.git

plugin name=vim-commentary cat=edit prof=full,minimal \
  repo=https://github.com/tpope/vim-commentary.git

plugin name=vim-repeat cat=edit prof=full,minimal \
  repo=https://github.com/tpope/vim-repeat.git

plugin name=vim-unimpaired cat=edit prof=full,minimal \
  repo=https://github.com/tpope/vim-unimpaired.git

plugin name=traces.vim cat=edit \
  repo=https://github.com/markonm/traces.vim.git

plugin name=targets.vim cat=edit \
  repo=https://github.com/wellle/targets.vim.git

plugin name=editorconfig-vim cat=edit \
  repo=https://github.com/editorconfig/editorconfig-vim.git

plugin name=vim-signify cat=git \
  repo=https://github.com/mhinz/vim-signify.git

plugin name=lightline.vim cat=ui \
  repo=https://github.com/itchyny/lightline.vim.git

plugin name=vim-which-key cat=ui \
  repo=https://github.com/liuchengxu/vim-which-key.git

plugin name=undotree cat=ui \
  repo=https://github.com/mbbill/undotree.git

plugin name=vim-highlightedyank cat=ui \
  repo=https://github.com/machakann/vim-highlightedyank.git

# ---------- helpers ----------

# Colors only on a real terminal
if [ -t 1 ]; then
  BOLD="$(tput bold 2>/dev/null || true)"
  RED="$(tput setaf 1 2>/dev/null || true)"
  GREEN="$(tput setaf 2 2>/dev/null || true)"
  BLUE="$(tput setaf 4 2>/dev/null || true)"
  RESET="$(tput sgr0 2>/dev/null || true)"
else
  BOLD=""; RED=""; GREEN=""; BLUE=""; RESET=""
fi

# Is $2 (a profile) listed in the csv $1 ?
in_profile() { case ",$1," in *",$2,"*) return 0;; *) return 1;; esac; }

# Append $2 to space-list $1 only if absent
add_unique() { case " $1 " in *" $2 "*) echo "$1";; *) echo "$1 $2";; esac; }

# Run a command, or just print it under --dry-run
run() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] $*"; else "$@"; fi
}

# y/N prompt, auto-yes with --yes
confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  printf "%s [y/N] " "$1"
  read -r ans
  case "$ans" in [yY]*) return 0;; *) return 1;; esac
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos;;
    Linux)
      if [ -f /etc/os-release ] && grep -q '^ID=ubuntu' /etc/os-release; then
        echo ubuntu
      else
        echo linux-other
      fi
      ;;
    *) echo other;;
  esac
}

# ---------- system deps ----------

# Collect deduped deps for the current profile. $1 = os
collect_deps() {
  local os="$1" acc="" i deps d
  for i in "${!P_name[@]}"; do
    in_profile "${P_prof[$i]}" "$PROFILE" || continue
    if [ "$os" = "ubuntu" ]; then deps="${P_apt[$i]}"; else deps="${P_brew[$i]}"; fi
    [ -z "$deps" ] && continue
    for d in $(echo "$deps" | tr ',' ' '); do
      acc="$(add_unique "$acc" "$d")"
    done
  done
  echo "$acc"
}

install_deps() {
  local os deps
  os="$(detect_os)"
  case "$os" in
    macos)  deps="$(collect_deps macos)";;
    ubuntu) deps="$(collect_deps ubuntu)";;
    *) echo "  ${RED}OS not supported for auto deps ($os), install manually${RESET}"; return 0;;
  esac
  [ -z "$deps" ] && return 0
  echo "${BOLD}Installing system deps:${RESET}$deps"
  case "$os" in
    macos)
      command -v brew >/dev/null 2>&1 || { echo "  ${RED}Homebrew missing: https://brew.sh${RESET}"; return 1; }
      run brew install $deps
      ;;
    ubuntu)
      run sudo apt-get update
      run sudo apt-get install -y $deps
      ;;
  esac
}

# ---------- commands ----------

gen_helptags() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  command -v vim >/dev/null 2>&1 || return 0
  local d
  for d in "$VIM_PACK_DIR"/*/start/*/doc "$VIM_PACK_DIR"/*/opt/*/doc; do
    [ -d "$d" ] || continue
    vim -u NONE -es -c "helptags $d" -c qa >/dev/null 2>&1 || true
  done
}

print_notes() {
  local shown=0 i
  for i in "${!P_name[@]}"; do
    in_profile "${P_prof[$i]}" "$PROFILE" || continue
    [ -z "${P_note[$i]}" ] && continue
    [ "$shown" -eq 0 ] && { echo; echo "${BOLD}Manual steps left to you:${RESET}"; shown=1; }
    printf "  - %s: %s\n" "${P_name[$i]}" "${P_note[$i]}"
  done
}

cmd_install() {
  install_deps
  echo "${BOLD}Installing plugins into:${RESET} $VIM_PACK_DIR"
  if [ -L "$HOME/.vim" ]; then
    echo "  (~/.vim is a symlink -> $(readlink "$HOME/.vim"), so plugins land under there/pack)"
  fi
  local i name cat repo dir loc ref
  for i in "${!P_name[@]}"; do
    in_profile "${P_prof[$i]}" "$PROFILE" || continue
    name="${P_name[$i]}"; cat="${P_cat[$i]}"; repo="${P_repo[$i]}"
    loc="${P_loc[$i]}"; ref="${P_ref[$i]}"
    dir="$VIM_PACK_DIR/$cat/$loc/$name"
    if [ -d "$dir" ]; then
      echo "  $name already installed"
      continue
    fi
    run mkdir -p "$VIM_PACK_DIR/$cat/$loc"
    printf "  cloning %-22s ... " "$name"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run]"
    elif [ -n "$ref" ]; then
      git clone --depth=1 --branch "$ref" "$repo" "$dir" >/dev/null 2>&1 && echo "ok ($ref)" || echo "failed"
    else
      git clone --depth=1 "$repo" "$dir" >/dev/null 2>&1 && echo "ok" || echo "failed"
    fi
  done
  gen_helptags
  print_notes
}

cmd_update() {
  echo "${BOLD}Updating plugins:${RESET}"
  local dir
  for dir in "$VIM_PACK_DIR"/*/start/* "$VIM_PACK_DIR"/*/opt/*; do
    [ -d "$dir/.git" ] || continue
    printf "  updating %-22s ... " "$(basename "$dir")"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run]"
    elif ! git -C "$dir" symbolic-ref -q HEAD >/dev/null 2>&1; then
      echo "pinned, skipped"
    else
      git -C "$dir" pull --ff-only >/dev/null 2>&1 && echo "ok" || echo "failed"
    fi
  done
  gen_helptags
}

cmd_clean() {
  local allowed="" i candidates="" cat_dir loc dir
  for i in "${!P_name[@]}"; do allowed="$(add_unique "$allowed" "${P_name[$i]}")"; done
  [ -d "$VIM_PACK_DIR" ] || { echo "nothing to clean"; return 0; }
  for cat_dir in "$VIM_PACK_DIR"/*; do
    [ -d "$cat_dir" ] || continue
    for loc in start opt; do
      [ -d "$cat_dir/$loc" ] || continue
      for dir in "$cat_dir/$loc"/*; do
        [ -d "$dir" ] || continue
        case " $allowed " in *" $(basename "$dir") "*) continue;; esac
        candidates="$candidates $dir"
      done
    done
  done
  [ -z "$candidates" ] && { echo "nothing to clean"; return 0; }
  echo "Unregistered plugins:"
  for dir in $candidates; do echo "  $(basename "$dir")"; done
  confirm "remove them?" || { echo "aborted"; return 0; }
  for dir in $candidates; do run rm -rf "$dir"; echo "  removed $(basename "$dir")"; done
}

cmd_uninstall() {
  local target="${1:-}" i name cat loc dir candidates=""
  for i in "${!P_name[@]}"; do
    name="${P_name[$i]}"; cat="${P_cat[$i]}"; loc="${P_loc[$i]}"
    [ -n "$target" ] && [ "$target" != "$name" ] && continue
    dir="$VIM_PACK_DIR/$cat/$loc/$name"
    [ -d "$dir" ] && candidates="$candidates $dir"
  done
  [ -z "$candidates" ] && { echo "nothing to uninstall"; return 0; }
  echo "Will remove (plugins only, deps kept):"
  for dir in $candidates; do echo "  $(basename "$dir")"; done
  confirm "proceed?" || { echo "aborted"; return 0; }
  for dir in $candidates; do run rm -rf "$dir"; echo "  removed $(basename "$dir")"; done
}

cmd_list() {
  printf "%-22s %-11s %-13s %-5s %s\n" "PLUGIN" "CATEGORY" "PROFILE" "INST" "DEPS"
  local i name cat prof deps dir mark loc
  for i in "${!P_name[@]}"; do
    name="${P_name[$i]}"; cat="${P_cat[$i]}"; prof="${P_prof[$i]}"; deps="${P_brew[$i]}"; loc="${P_loc[$i]}"
    dir="$VIM_PACK_DIR/$cat/$loc/$name"
    [ -d "$dir" ] && mark="yes" || mark="no"
    printf "%-22s %-11s %-13s %-5s %s\n" "$name" "$cat" "$prof" "$mark" "${deps:-–}"
  done
}

check_bin() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "  ${GREEN}ok     ${RESET} %s\n" "$2"
  else
    printf "  ${RED}missing${RESET} %s\n" "$2"
  fi
}

cmd_doctor() {
  echo "${BOLD}Binaries:${RESET}"
  check_bin vim   "vim"
  check_bin git   "git"
  check_bin node  "node (tabby agent + typescript LSP)"
  check_bin fzf   "fzf (:Files, :Rg)"
  check_bin bat   "bat (fzf preview)"
  check_bin rg    "ripgrep (:Rg)"
  check_bin ag    "the_silver_searcher (:Ag, optional)"
  check_bin ctags "universal-ctags (:Tags, optional)"
  check_bin delta "git-delta (nicer git diff, optional)"
  check_bin perl  "perl (fzf Tags/Helptags)"
}

# ---------- deploy (symlink repo <-> $HOME) ----------

link_one() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  $dst already linked"; return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    # a leftover .bak would be silently nested into by mv, refuse instead
    if [ -e "$dst.bak" ] || [ -L "$dst.bak" ]; then
      echo "  ${RED}$dst.bak already exists, move or delete it first${RESET}"
      return 1
    fi
    echo "  backup $dst -> $dst.bak"
    run mv "$dst" "$dst.bak"
  fi
  run ln -s "$src" "$dst"
  echo "  linked $dst -> $src"
}

cmd_link() {
  link_one "$REPO_DIR/.vimrc" "$HOME/.vimrc"
  link_one "$REPO_DIR/.vim"   "$HOME/.vim"
  echo
  echo "${BOLD}${RED}Now run: install.sh install${RESET}"
  echo "plugins are gitignored, they must be (re)cloned into .vim/pack"
}

unlink_one() {
  local dst="$1" src="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    run rm "$dst"; echo "  unlinked $dst"
    if [ -e "$dst.bak" ] || [ -L "$dst.bak" ]; then
      run mv "$dst.bak" "$dst"; echo "  restored $dst from .bak"
    fi
  else
    echo "  $dst not linked to repo, skipping"
  fi
}

cmd_unlink() {
  unlink_one "$HOME/.vimrc" "$REPO_DIR/.vimrc"
  unlink_one "$HOME/.vim"   "$REPO_DIR/.vim"
}

# ---------- ui ----------

banner() {
  echo "${BOLD}${BLUE}vimrc setup${RESET}"
  echo "repo: $REPO_DIR"
  echo "pack: $VIM_PACK_DIR"
  echo
}

usage() {
  cat <<EOF
usage: install.sh <command> [--profile full|minimal] [--dry-run] [--yes]

  link             symlink repo -> \$HOME (backup existing)
  unlink           remove symlinks, restore .bak
  install          install plugins for profile + system deps
  update           git pull all installed plugins
  clean            remove plugins not in the manifest
  uninstall [name] remove managed plugins (deps kept)
  list             show plugins and install status
  doctor           check required/optional binaries
EOF
}

# ---------- arg parsing ----------

POSITIONAL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)     DRY_RUN=1;;
    --yes|-y)      ASSUME_YES=1;;
    --profile)     shift; PROFILE="${1:-full}";;
    --profile=*)   PROFILE="${1#*=}";;
    -h|--help)     usage; exit 0;;
    -*)            echo "unknown option: $1" >&2; usage; exit 1;;
    *)             POSITIONAL="$POSITIONAL $1";;
  esac
  shift
done
# shellcheck disable=SC2086
set -- $POSITIONAL
cmd="${1:-}"
arg="${2:-}"

case "$PROFILE" in full|minimal) ;; *) echo "unknown profile: $PROFILE" >&2; exit 1;; esac

# ---------- dispatch ----------

case "$cmd" in
  "")        banner; cmd_list; echo; usage;;
  link)      banner; cmd_link;;
  unlink)    banner; cmd_unlink;;
  install)   banner; echo "profile: $PROFILE"; echo; cmd_install;;
  update)    banner; cmd_update;;
  clean)     banner; cmd_clean;;
  uninstall) banner; cmd_uninstall "$arg";;
  list)      banner; cmd_list;;
  doctor)    banner; cmd_doctor;;
  *)         echo "unknown command: $cmd" >&2; usage; exit 1;;
esac
