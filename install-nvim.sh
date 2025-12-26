#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./install-nvim.sh --repo https://github.com/<you>/dotfiles.git
#   ./install-nvim.sh --repo git@github.com:<you>/dotfiles.git --branch main
#
# What it does:
# - Installs Neovim v0.11.5 (tarball) to /opt/nvim-linux64 and symlink /usr/local/bin/nvim
# - Installs deps: git/curl/unzip/ripgrep/fd/python/pip
# - Installs Node.js 22 (for tsserver/prettier/eslint) if missing
# - Installs npm CLIs (prettier/eslint/typescript-language-server)
# - Installs ruff (user install)
# - Clones your dotfiles repo to ~/dotfiles (or updates it)
# - Symlinks ~/.config/nvim -> ~/dotfiles/nvim (or a stow alternative)
#
# Notes:
# - For icons you must set terminal font to a Nerd Font on the client side (local terminal).

NEOVIM_VERSION="v0.11.5"
DOTFILES_REPO=""
DOTFILES_BRANCH="main"
USE_STOW="0"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            DOTFILES_REPO="$2"
            shift 2
            ;;
        --branch)
            DOTFILES_BRANCH="$2"
            shift 2
            ;;
        --stow)
            USE_STOW="1"
            shift 1
            ;;
        *)
            echo "Unknown arg: $1"
            exit 2
            ;;
    esac
done

if [[ -z "$DOTFILES_REPO" ]]; then
    echo "Missing --repo <git-url>"
    exit 2
fi

log() { printf "\n==> %s\n" "$*"; }

ensure_path_local_bin() {
    # Ensure ~/.local/bin is available for the current script run too.
    export PATH="$HOME/.local/bin:$PATH"
}

install_apt_deps() {
    log "Installing system dependencies (apt)"
    sudo apt update
    sudo apt install -y \
        git curl ca-certificates unzip \
        ripgrep fd-find \
        python3 python3-venv python3-pip \
        xz-utils

    # Debian/Ubuntu provide fd as fdfind
    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
        sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
    fi
}

install_node_22_if_missing() {
    if command -v node >/dev/null 2>&1; then
        log "Node is already installed: $(node --version)"
        return
    fi

    log "Installing Node.js 22 (nodesource)"
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    log "Node installed: $(node --version)"
}

install_neovim_0115() {
    local current="none"
    if command -v nvim >/dev/null 2>&1; then
        current="$(nvim --version | head -n1 || true)"
    fi

    if [[ "$current" == *"NVIM v0.11.5"* ]]; then
        log "Neovim already at 0.11.5"
        return
    fi

    log "Installing Neovim $NEOVIM_VERSION"
    local url="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz"

    rm -f /tmp/nvim-linux64.tar.gz
    curl -L -o /tmp/nvim-linux64.tar.gz "$url"

    sudo rm -rf /opt/nvim-linux64
    sudo tar -C /opt -xzf /tmp/nvim-linux64.tar.gz

    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    rm -f /tmp/nvim-linux64.tar.gz

    log "Neovim installed: $(nvim --version | head -n1)"
}

install_cli_tools() {
    log "Installing global npm CLIs (prettier/eslint/typescript-language-server)"
    # idempotent; npm will update if needed
    sudo npm install -g \
        typescript \
        typescript-language-server \
        prettier \
        eslint
}

install_ruff() {
    log "Installing/Upgrading ruff (user)"
    ensure_path_local_bin
    python3 -m pip install --user --upgrade pip
    python3 -m pip install --user --upgrade ruff

    if ! command -v ruff >/dev/null 2>&1; then
        echo "ERROR: ruff is installed but not found in PATH."
        echo "Add this to your shell rc: export PATH=\"\$HOME/.local/bin:\$PATH\""
        exit 1
    fi

    log "ruff: $(ruff --version)"
}

clone_or_update_dotfiles() {
    log "Cloning/updating dotfiles repo"
    if [[ -d "$HOME/dotfiles/.git" ]]; then
        (cd "$HOME/dotfiles" && git fetch --all && git checkout "$DOTFILES_BRANCH" && git pull)
    else
        git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$HOME/dotfiles"
    fi
}

symlink_nvim_config_ln() {
    log "Symlinking Neovim config (ln -sfn)"
    mkdir -p "$HOME/.config"

    if [[ ! -d "$HOME/dotfiles/nvim" ]]; then
        echo "ERROR: expected $HOME/dotfiles/nvim to exist."
        echo "Your dotfiles repo must contain a 'nvim/' folder (with init.lua inside)."
        exit 1
    fi

    # -s: symlink, -f: replace existing, -n: treat existing link as file
    ln -sfn "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

    log "Linked: ~/.config/nvim -> $(readlink -f "$HOME/.config/nvim")"
}

symlink_nvim_config_stow() {
    log "Symlinking Neovim config using GNU stow"
    sudo apt install -y stow

    if [[ ! -d "$HOME/dotfiles/nvim" ]]; then
        echo "ERROR: expected $HOME/dotfiles/nvim to exist."
        echo "Your dotfiles repo must contain a 'nvim/' folder."
        exit 1
    fi

    # For stow to create ~/.config/nvim, the repo layout should be:
    # dotfiles/
    #   nvim/
    #     .config/
    #       nvim/
    #         init.lua
    #
    # If your repo is dotfiles/nvim/init.lua (no .config layer), use ln instead
    if [[ -d "$HOME/dotfiles/nvim/.config/nvim" ]]; then
        (cd "$HOME/dotfiles" && stow -R nvim)
        log "Stow done. Linked ~/.config/nvim"
    else
        echo "ERROR: Your repo layout is not stow-ready."
        echo "For stow you need: dotfiles/nvim/.config/nvim/init.lua"
        echo "You currently have: dotfiles/nvim/..."
        echo "Either restructure for stow, or run without --stow to use ln -sfn."
        exit 1
    fi
}

print_next_steps() {
    cat <<'EOF'

Next steps:
1) Start Neovim once so lazy.nvim installs plugins:
   nvim

2) In Neovim, verify:
   :Mason
   :LspInfo
   :ConformInfo

3) Icons:
   Icons depend on your LOCAL terminal font. Set your terminal to a Nerd Font
   (JetBrainsMono Nerd Font / FiraCode Nerd Font). SSH servers won't control that.

EOF
}

main() {
    install_apt_deps
    install_node_22_if_missing
    install_neovim_0115
    install_cli_tools
    install_ruff
    clone_or_update_dotfiles

    if [[ "$USE_STOW" == "1" ]]; then
        symlink_nvim_config_stow
    else
        symlink_nvim_config_ln
    fi

    print_next_steps
}

main


