#!/usr/bin/env bash

set -e

echo "Detecting OS..."

OS="$(uname -s)"

case "$OS" in
  Darwin)
    echo "Detected macOS."
    if ! command -v brew &>/dev/null; then
      echo "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
      exit 1
    fi
    echo "Installing dependencies with Homebrew..."
    brew install fzf bat ripgrep #the_silver_searcher perl universal-ctags
    ;;

  Linux)
    # Check for Ubuntu specifically
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      if [[ "$ID" == "ubuntu" ]]; then
        echo "Detected Ubuntu Linux."
        echo "Updating package lists..."
        sudo apt-get update
        echo "Installing dependencies with apt..."
        sudo apt-get install -y fzf bat ripgrep #silversearcher-ag perl universal-ctags
      else
        echo "Unsupported Linux distribution: $ID"
        exit 1
      fi
    else
      echo "Could not detect Linux distribution."
      exit 1
    fi
    ;;

  CYGWIN*|MINGW*|MSYS*)
    echo "Windows detected. This script does not support Windows."
    exit 1
    ;;

  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

echo "All dependencies installed successfully."

