#!/usr/bin/env python3

import os
import sys
from pathlib import Path

import yaml

INTERNAL_PROXY_NAME = os.environ.get("INTERNAL_PROXY_NAME", "corp-http")
INTERNAL_PROXY_SERVER = os.environ.get("INTERNAL_PROXY_SERVER", "proxy.example.internal")
INTERNAL_PROXY_PORT = int(os.environ.get("INTERNAL_PROXY_PORT", "3128"))
GLOBAL_RULES = ["MATCH,PROXY"]


def load_yaml(path: Path) -> dict:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("subscription content is not a YAML mapping")
    return data


def ensure_proxy_chain(data: dict) -> dict:
    proxies = data.get("proxies")
    if not isinstance(proxies, list) or not proxies:
        raise ValueError("subscription YAML does not contain a proxies list")

    filtered = []
    node_names = []
    for proxy in proxies:
        if not isinstance(proxy, dict):
            continue
        name = proxy.get("name")
        if not name or name == INTERNAL_PROXY_NAME:
            continue
        proxy = dict(proxy)
        proxy["dialer-proxy"] = INTERNAL_PROXY_NAME
        filtered.append(proxy)
        node_names.append(name)

    if not node_names:
        raise ValueError("no usable proxy nodes were found in the subscription")

    filtered.append(
        {
            "name": INTERNAL_PROXY_NAME,
            "type": "http",
            "server": INTERNAL_PROXY_SERVER,
            "port": INTERNAL_PROXY_PORT,
        }
    )

    return {
        "mixed-port": 7890,
        "socks-port": 7891,
        "redir-port": 7892,
        "allow-lan": False,
        "bind-address": "127.0.0.1",
        "mode": "rule",
        "log-level": "info",
        "ipv6": False,
        "external-controller": "127.0.0.1:9090",
        "proxies": filtered,
        "proxy-groups": [
            {
                "name": "AUTO",
                "type": "url-test",
                "url": "https://www.gstatic.com/generate_204",
                "interval": 300,
                "tolerance": 50,
                "proxies": node_names,
            },
            {
                "name": "PROXY",
                "type": "select",
                "proxies": ["AUTO", *node_names],
            },
        ],
        "rules": GLOBAL_RULES,
    }


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: update_mihomo_config.py <raw_subscription_yaml> <output_config_yaml>", file=sys.stderr)
        return 2
    source_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    data = load_yaml(source_path)
    rendered = ensure_proxy_chain(data)
    output_path.write_text(
        yaml.safe_dump(rendered, allow_unicode=False, sort_keys=False),
        encoding="utf-8",
    )
    print(f"wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
