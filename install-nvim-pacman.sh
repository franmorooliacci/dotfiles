#!/usr/bin/env bash
set -euo pipefail

NEOVIM_VERSION="v0.11.5"

log() { printf "\n==> %s\n" "$*"; }

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: missing required command: $1"
        exit 1
    fi
}

ensure_path_local_bin() {
    export PATH="$HOME/.local/bin:$PATH"
}

assert_repo_layout() {
    if [[ ! -d "./nvim" ]]; then
        echo "ERROR: expected ./nvim folder next to this script."
        echo "Repo layout must be:"
        echo "  dotfiles/"
        echo "    bootstrap-nvim-arch.sh"
        echo "    nvim/init.lua"
        exit 1
    fi

    if [[ ! -f "./nvim/init.lua" ]]; then
        echo "ERROR: expected ./nvim/init.lua to exist."
        exit 1
    fi
}

install_pacman_deps() {
    log "Installing system dependencies (pacman)"
    sudo pacman -Syu --noconfirm

    # Packages:
    # - fd (Arch provides it as "fd", not "fd-find")
    # - base-devel is useful if you install AUR stuff (nodejs 22 fallback)
    # - python-pipx for ruff via pipx
    sudo pacman -S --needed --noconfirm \
        git curl ca-certificates unzip \
        ripgrep fd \
        python python-pipx \
        xz \
        base-devel
}

install_node_22_if_missing() {
    if command -v node >/dev/null 2>&1; then
        log "Node already installed: $(node --version)"
        return
    fi

    # Prefer official repos first
    if sudo pacman -Si nodejs >/dev/null 2>&1; then
        log "Installing Node.js from pacman repos (nodejs, npm)"
        sudo pacman -S --needed --noconfirm nodejs npm
        log "Node installed: $(node --version)"
        return
    fi

    # Fallback: AUR (requires an AUR helper like yay/paru)
    if command -v yay >/dev/null 2>&1; then
        log "Installing Node.js 22 via AUR (yay): nodejs-lts-iron / nodejs-lts-jod"
        # Choose one that exists in AUR; try iron first
        yay -S --needed --noconfirm nodejs-lts-iron npm || yay -S --needed --noconfirm nodejs-lts-jod npm
        log "Node installed: $(node --version)"
        return
    fi

    if command -v paru >/dev/null 2>&1; then
        log "Installing Node.js 22 via AUR (paru): nodejs-lts-iron / nodejs-lts-jod"
        paru -S --needed --noconfirm nodejs-lts-iron npm || paru -S --needed --noconfirm nodejs-lts-jod npm
        log "Node installed: $(node --version)"
        return
    fi

    echo "ERROR: Node not installed and no AUR helper found."
    echo "Install nodejs/npm via pacman if available, or install yay/paru and retry."
    exit 1
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

    log "Installing Neovim $NEOVIM_VERSION (from GitHub release tarball)"

    local arch
    arch="$(uname -m)"
    local tarball

    case "$arch" in
        x86_64|amd64) tarball="nvim-linux-x86_64.tar.gz" ;;
        aarch64|arm64) tarball="nvim-linux-arm64.tar.gz" ;;
        *)
            echo "ERROR: unsupported arch: $arch"
            exit 1
            ;;
    esac

    local url="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${tarball}"

    rm -f "/tmp/${tarball}"
    curl -fL -o "/tmp/${tarball}" "$url"

    if ! file "/tmp/${tarball}" | grep -qi 'gzip compressed'; then
        echo "ERROR: downloaded file is not a gzip tarball:"
        file "/tmp/${tarball}"
        echo "URL was: $url"
        exit 1
    fi

    sudo rm -rf /opt/nvim-linux-*
    sudo tar -C /opt -xzf "/tmp/${tarball}"

    local extracted_dir="/opt/${tarball%.tar.gz}"
    sudo ln -sf "${extracted_dir}/bin/nvim" /usr/local/bin/nvim

    rm -f "/tmp/${tarball}"
    log "Neovim installed: $(nvim --version | head -n1)"
}

install_global_clis() {
    log "Installing global npm CLIs (prettier/eslint/typescript-language-server) as user"

    if ! command -v npm >/dev/null 2>&1; then
        echo "ERROR: npm not found in PATH for this user."
        echo "Install nodejs/npm or load your node environment (nvm, etc)."
        exit 1
    fi

    ensure_path_local_bin
    npm config set prefix "$HOME/.local"

    npm install -g \
        typescript \
        typescript-language-server \
        prettier \
        eslint

    log "Installing/Upgrading ruff via pipx"
    ensure_path_local_bin

    # pipx is installed via pacman as python-pipx; ensure path
    pipx ensurepath || true
    export PATH="$HOME/.local/bin:$PATH"

    if command -v ruff >/dev/null 2>&1; then
        pipx upgrade ruff || true
    else
        pipx install ruff
    fi

    if ! command -v ruff >/dev/null 2>&1; then
        echo "ERROR: ruff installed but not found in PATH."
        echo "Add to your shell rc:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        exit 1
    fi

    log "ruff: $(ruff --version)"
}

symlink_nvim_config() {
    log "Symlinking Neovim config"
    mkdir -p "$HOME/.config"
    ln -sfn "$(pwd)/nvim" "$HOME/.config/nvim"
    log "Linked: ~/.config/nvim -> $(readlink -f "$HOME/.config/nvim")"
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

Notes:
- Icons depend on your LOCAL terminal font (client side). Over SSH, the server can't set fonts.

EOF
}

main() {
    need_cmd sudo
    need_cmd pacman
    assert_repo_layout
    install_pacman_deps
    install_node_22_if_missing
    install_neovim_0115
    install_global_clis
    symlink_nvim_config
    print_next_steps
}

main

