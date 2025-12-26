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
    # Make user-installed Python tools (ruff) visible for this run
    export PATH="$HOME/.local/bin:$PATH"
}

assert_repo_layout() {
    if [[ ! -d "./nvim" ]]; then
        echo "ERROR: expected ./nvim folder next to this script."
        echo "Repo layout must be:"
        echo "  dotfiles/"
        echo "    bootstrap-nvim.sh"
        echo "    nvim/init.lua"
        exit 1
    fi

    if [[ ! -f "./nvim/init.lua" ]]; then
        echo "ERROR: expected ./nvim/init.lua to exist."
        exit 1
    fi
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
        log "Node already installed: $(node --version)"
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
    # -f fail on HTTP errors, -L follow redirects
    curl -fL -o "/tmp/${tarball}" "$url"

    # sanity check (avoid tar on HTML/error pages)
    if ! file "/tmp/${tarball}" | grep -qi 'gzip compressed'; then
        echo "ERROR: downloaded file is not a gzip tarball:"
        file "/tmp/${tarball}"
        echo "URL was: $url"
        exit 1
    fi

    sudo rm -rf /opt/nvim-linux-*
    sudo tar -C /opt -xzf "/tmp/${tarball}"

    # the extracted dir matches tarball base name
    local extracted_dir="/opt/${tarball%.tar.gz}"
    sudo ln -sf "${extracted_dir}/bin/nvim" /usr/local/bin/nvim

    rm -f "/tmp/${tarball}"
    log "Neovim installed: $(nvim --version | head -n1)"
}

install_global_clis() {
    log "Installing global npm CLIs (prettier/eslint/typescript-language-server) as user"

    if ! command -v npm >/dev/null 2>&1; then
        echo "ERROR: npm not found in PATH for this user."
        echo "If you use nvm, load it (new shell) or install nodejs/npm system-wide."
        exit 1
    fi

    # Put npm global installs in ~/.local (no sudo needed)
    ensure_path_local_bin
    npm config set prefix "$HOME/.local"

    npm install -g \
        typescript \
        typescript-language-server \
        prettier \
        eslint

    log "Installing/Upgrading ruff via pipx (PEP 668 safe)"
    sudo apt install -y pipx
    pipx ensurepath

    # Make pipx-installed apps available for this run
    export PATH="$HOME/.local/bin:$PATH"

    # Install or upgrade ruff
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
    assert_repo_layout
    install_apt_deps
    install_node_22_if_missing
    install_neovim_0115
    install_global_clis
    symlink_nvim_config
    print_next_steps
}

main

