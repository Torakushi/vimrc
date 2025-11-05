#!/bin/bash

VIM_PACK_DIR="$HOME/.vim/pack"

plugins=(
  "completion https://github.com/prabirshrestha/asyncomplete.vim.git"
  "completion https://github.com/prabirshrestha/asyncomplete-lsp.vim.git"
  "copilot https://github.com/github/copilot.vim.git"
  "lsp https://github.com/prabirshrestha/vim-lsp.git"
  "lsp https://github.com/mattn/vim-lsp-settings.git"
  "fzf https://github.com/junegunn/fzf.vim.git"
  "nerdTree https://github.com/preservim/nerdtree.git"
  "lint https://github.com/dense-analysis/ale.git"
  "test https://github.com/vim-test/vim-test.git"
  "rooter https://github.com/airblade/vim-rooter.git"
  "git https://github.com/tpope/vim-fugitive.git"
)

mode="$1" # "install", "update" or "clean"

if [[ "$mode" != "install" && "$mode" != "update" && "$mode" != "clean" ]]; then
  echo "Usage: $0 {install|update|clean}"
  exit 1
fi

# Build a space-delimited whitelist of allowed plugin directory names
allowed_plugins=""
for plugin in "${plugins[@]}"; do
  repo_url=$(echo "$plugin" | cut -d' ' -f2)
  plugin_name=$(basename "$repo_url" .git)
  allowed_plugins="$allowed_plugins $plugin_name"
done

# Install/update listed plugins
for plugin in "${plugins[@]}"; do
  category=$(echo "$plugin" | cut -d' ' -f1)
  repo_url=$(echo "$plugin" | cut -d' ' -f2)
  plugin_name=$(basename "$repo_url" .git)
  target_dir="$VIM_PACK_DIR/$category/start/$plugin_name"

  mkdir -p "$VIM_PACK_DIR/$category/start"

  if [[ "$mode" == "install" ]]; then
    if [ ! -d "$target_dir" ]; then
      printf "Cloning %-25s ......... " "$plugin_name"
      git clone --depth=1 "$repo_url" "$target_dir" &> /dev/null && echo "Installed" || echo "Failed"
    else
      echo "$plugin_name already installed"
    fi
  elif [[ "$mode" == "update" ]]; then
    if [ -d "$target_dir/.git" ]; then
      printf "Updating %-25s ......... " "$plugin_name"
      git -C "$target_dir" pull --ff-only &> /dev/null && echo "Updated" || echo "Failed"
    else
      echo "$plugin_name not installed, skipping"
    fi
  fi
done

# Clean: remove any plugin dir not in whitelist, in both start/ and opt/
if [[ "$mode" == "clean" ]]; then
  echo "Cleaning unregistered plugins..."
  # Iterate categories (e.g., completion, lsp, fzf, etc.)
  if [ -d "$VIM_PACK_DIR" ]; then
    for category_dir in "$VIM_PACK_DIR"/*; do
      [ -d "$category_dir" ] || continue
      for loc in start opt; do
        base="$category_dir/$loc"
        [ -d "$base" ] || continue
        for dir in "$base"/*; do
          [ -d "$dir" ] || continue
          plugin_name=$(basename "$dir")
          case " $allowed_plugins " in
            *" $plugin_name "*) : ;;  # keep
            *)
              printf "Removing %-25s (%s) ......... " "$plugin_name" "$loc"
              rm -rf "$dir"
              echo "Removed"
              ;;
          esac
        done
      done
    done
  fi
fi
