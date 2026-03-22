# mihomo helpers for bash
mihomo_refresh() {
    ~/.local/bin/refresh_mihomo.sh
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
    python3 - "$1" <<'INNERPY'
from pathlib import Path
import sys

url = sys.argv[1]
p = Path('/root/.local/bin/refresh_mihomo.sh')
lines = p.read_text().splitlines()
for i, line in enumerate(lines):
    if line.startswith('SUBSCRIPTION_URL='):
        lines[i] = f'SUBSCRIPTION_URL="${{MIHOMO_SUBSCRIPTION_URL:-{url}}}"'
        break
else:
    raise SystemExit('SUBSCRIPTION_URL line not found')
p.write_text("\n".join(lines) + "\n")
print('updated subscription url in refresh_mihomo.sh')
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
