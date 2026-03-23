# mihomo helpers for zsh
export MIHOMO_CONFIG_DIR="${MIHOMO_CONFIG_DIR:-$HOME/.config/mihomo}"
export MIHOMO_ENV_FILE="${MIHOMO_ENV_FILE:-$MIHOMO_CONFIG_DIR/env.sh}"
export MIHOMO_REFRESH_SCRIPT="${MIHOMO_REFRESH_SCRIPT:-$HOME/.local/bin/refresh_mihomo.sh}"

if [ -f "$MIHOMO_ENV_FILE" ]; then
    source "$MIHOMO_ENV_FILE"
fi

mihomo_refresh() {
    "$MIHOMO_REFRESH_SCRIPT"
}

mihomo_proxy_on() {
    export http_proxy="http://127.0.0.1:7890"
    export https_proxy="http://127.0.0.1:7890"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export ALL_PROXY="socks5h://127.0.0.1:7891"
    export all_proxy="$ALL_PROXY"
    echo "Mihomo proxy enabled via 127.0.0.1:7890 / 7891"
}

mihomo_proxy_off() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy
    echo "Mihomo proxy disabled"
}

openai_proxy_on() {
    mihomo_proxy_on
}

openai_proxy_off() {
    mihomo_proxy_off
}

mihomo_current_node() {
    echo "PROXY:" && curl -s http://127.0.0.1:9090/proxies/PROXY | python3 -m json.tool
    echo "AUTO:" && curl -s http://127.0.0.1:9090/proxies/AUTO | python3 -m json.tool
}

mihomo_use_node() {
    if [ -z "$1" ]; then
        echo 'usage: mihomo_use_node "Node-Name"'
        return 1
    fi
    payload=$(printf '{"name":"%s"}' "$1")
    curl -s -X PUT http://127.0.0.1:9090/proxies/PROXY \
      -H 'Content-Type: application/json' \
      -d "$payload" && echo
}

mihomo_use_auto() {
    curl -s -X PUT http://127.0.0.1:9090/proxies/PROXY \
      -H 'Content-Type: application/json' \
      -d '{"name":"AUTO"}' && echo
}

mihomo_restart() {
    systemctl restart mihomo && systemctl --no-pager --full status mihomo | sed -n '1,12p'
}

mihomo_set_subscription() {
    if [ -z "$1" ]; then
        echo 'usage: mihomo_set_subscription "https://?..."'
        return 1
    fi
    mkdir -p "$MIHOMO_CONFIG_DIR"
    python3 - "$1" "$MIHOMO_ENV_FILE" <<'INNERPY'
from pathlib import Path
import shlex
import sys

url = sys.argv[1]
env_path = Path(sys.argv[2])
lines = []
if env_path.exists():
    lines = env_path.read_text(encoding="utf-8").splitlines()

key = "MIHOMO_SUBSCRIPTION_URL"
new_line = f"export {key}={shlex.quote(url)}"
for i, line in enumerate(lines):
    if line.startswith(f"export {key}=") or line.startswith(f"{key}="):
        lines[i] = new_line
        break
else:
    lines.append(new_line)

env_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"updated {key} in {env_path}")
INNERPY
}

if [[ $- == *i* ]]; then
    if [[ -z "$MIHOMO_AUTO_PROXY" ]]; then
        export MIHOMO_AUTO_PROXY=1
    fi
    if [[ "$MIHOMO_AUTO_PROXY" == "1" ]]; then
        mihomo_proxy_on >/dev/null 2>&1
    fi
fi
