#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INSTALL_USER="${INSTALL_USER:-${SUDO_USER:-$(id -un)}}"
INSTALL_HOME="${INSTALL_HOME:-$(getent passwd "${INSTALL_USER}" | cut -d: -f6)}"
MIHOMO_VERSION="${MIHOMO_VERSION:-1.19.21}"
MIHOMO_BIN="${MIHOMO_BIN:-/usr/local/bin/mihomo}"
CONFIG_DIR="${INSTALL_HOME}/.config/mihomo"
LOCAL_BIN_DIR="${INSTALL_HOME}/.local/bin"
SERVICE_PATH="${SERVICE_PATH:-/etc/systemd/system/mihomo.service}"

usage() {
    cat <<'INNER'
Usage:
  sudo INTERNAL_PROXY_URL=... \
       INTERNAL_PROXY_SERVER=... \
       INTERNAL_PROXY_PORT=... \
       MIHOMO_SUBSCRIPTION_URL=... \
       ./scripts/install.sh

Optional:
  INSTALL_USER=<user>            install target user, default current sudo user or current user
  INSTALL_HOME=<path>            install target home, auto-detected from INSTALL_USER
  MIHOMO_VERSION=<version>       default 1.19.21
  MIHOMO_BIN=<path>              default /usr/local/bin/mihomo
INNER
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "missing required command: $1" >&2
        exit 1
    }
}

append_source_line() {
    local rc_path="$1"
    local line="$2"
    touch "$rc_path"
    grep -Fqx "$line" "$rc_path" || printf '\n%s\n' "$line" >>"$rc_path"
}

download_mihomo() {
    local arch url tmp_gz tmp_bin
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64-compatible" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo "unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
    url="https://github.com/MetaCubeX/mihomo/releases/download/v${MIHOMO_VERSION}/mihomo-linux-${arch}-v${MIHOMO_VERSION}.gz"
    tmp_gz="$(mktemp /tmp/mihomo.XXXXXX.gz)"
    tmp_bin="${tmp_gz%.gz}"
    echo "downloading mihomo ${MIHOMO_VERSION} from ${url}"
    curl -fsSL --connect-timeout 20 --max-time 300 "$url" -o "$tmp_gz"
    gunzip -f "$tmp_gz"
    install -m 0755 "$tmp_bin" "$MIHOMO_BIN"
    rm -f "$tmp_bin"
}

write_env_file() {
    cat >"${CONFIG_DIR}/env.sh" <<INNER
export INTERNAL_PROXY_URL=$(printf '%q' "${INTERNAL_PROXY_URL}")
export INTERNAL_PROXY_SERVER=$(printf '%q' "${INTERNAL_PROXY_SERVER}")
export INTERNAL_PROXY_PORT=$(printf '%q' "${INTERNAL_PROXY_PORT}")
export MIHOMO_SUBSCRIPTION_URL=$(printf '%q' "${MIHOMO_SUBSCRIPTION_URL}")
export MIHOMO_BIN=$(printf '%q' "${MIHOMO_BIN}")
INNER
}

install_service() {
    cat >"${SERVICE_PATH}" <<INNER
[Unit]
Description=Mihomo proxy client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${INSTALL_USER}
WorkingDirectory=${CONFIG_DIR}
ExecStartPre=${LOCAL_BIN_DIR}/refresh_mihomo.sh
ExecStart=${MIHOMO_BIN} -f ${CONFIG_DIR}/config.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
INNER
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    [[ "$(id -u)" -eq 0 ]] || {
        echo "run as root or via sudo" >&2
        exit 1
    }

    [[ -n "${INSTALL_HOME}" ]] || {
        echo "failed to resolve INSTALL_HOME for user ${INSTALL_USER}" >&2
        exit 1
    }

    : "${INTERNAL_PROXY_URL:?INTERNAL_PROXY_URL is required}"
    : "${INTERNAL_PROXY_SERVER:?INTERNAL_PROXY_SERVER is required}"
    : "${INTERNAL_PROXY_PORT:?INTERNAL_PROXY_PORT is required}"
    : "${MIHOMO_SUBSCRIPTION_URL:?MIHOMO_SUBSCRIPTION_URL is required}"

    require_cmd curl
    require_cmd python3
    require_cmd install
    require_cmd gunzip
    require_cmd systemctl
    require_cmd getent

    mkdir -p "${CONFIG_DIR}" "${LOCAL_BIN_DIR}"

    download_mihomo
    "${MIHOMO_BIN}" -v

    install -m 0755 "${REPO_ROOT}/scripts/update_mihomo_config.py" "${CONFIG_DIR}/update_mihomo_config.py"
    install -m 0755 "${REPO_ROOT}/scripts/refresh_mihomo.sh" "${LOCAL_BIN_DIR}/refresh_mihomo.sh"
    install -m 0644 "${REPO_ROOT}/shell/mihomo_helpers.zsh" "${CONFIG_DIR}/mihomo_helpers.zsh"
    install -m 0644 "${REPO_ROOT}/shell/mihomo_helpers.bash" "${CONFIG_DIR}/mihomo_helpers.bash"

    write_env_file
    chown -R "${INSTALL_USER}:${INSTALL_USER}" "${CONFIG_DIR}" "${LOCAL_BIN_DIR}"

    append_source_line "${INSTALL_HOME}/.zshrc" 'if [ -f ~/.config/mihomo/mihomo_helpers.zsh ]; then source ~/.config/mihomo/mihomo_helpers.zsh; fi'
    append_source_line "${INSTALL_HOME}/.bashrc" 'if [ -f ~/.config/mihomo/mihomo_helpers.bash ]; then . ~/.config/mihomo/mihomo_helpers.bash; fi'
    chown "${INSTALL_USER}:${INSTALL_USER}" "${INSTALL_HOME}/.zshrc" "${INSTALL_HOME}/.bashrc"

    su - "${INSTALL_USER}" -c "GENERATOR_PATH='${CONFIG_DIR}/update_mihomo_config.py' '${LOCAL_BIN_DIR}/refresh_mihomo.sh'"

    install_service
    systemctl daemon-reload
    systemctl enable --now mihomo.service
    systemctl --no-pager --full status mihomo.service | sed -n '1,12p'

    cat <<INNER

Install complete.

Config:
  ${CONFIG_DIR}/env.sh
  ${CONFIG_DIR}/config.yaml

Helpers:
  ${CONFIG_DIR}/mihomo_helpers.zsh
  ${CONFIG_DIR}/mihomo_helpers.bash

Service:
  ${SERVICE_PATH}

Next:
  1. open a new shell or run: source ~/.zshrc
  2. verify: mihomo_current_node
  3. test: curl --proxy http://127.0.0.1:7890 -I https://api.openai.com/v1/models
INNER
}

main "$@"
