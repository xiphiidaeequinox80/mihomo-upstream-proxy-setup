#!/usr/bin/env python3

import base64
import os
import sys
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlsplit

import yaml

INTERNAL_PROXY_NAME = os.environ.get("INTERNAL_PROXY_NAME", "corp-http")
INTERNAL_PROXY_SERVER = os.environ.get("INTERNAL_PROXY_SERVER", "proxy.example.internal")
INTERNAL_PROXY_PORT = int(os.environ.get("INTERNAL_PROXY_PORT", "3128"))
GLOBAL_RULES = ["MATCH,PROXY"]
METADATA_KEYWORDS = (
    "remaining",
    "expire",
    "expiry",
    "subscription",
    "官网",
    "到期",
    "剩余",
    "流量",
)


def load_yaml_text(text: str) -> dict:
    data = yaml.safe_load(text)
    if not isinstance(data, dict):
        raise ValueError("subscription content is not a YAML mapping")
    return data


def decode_base64_text(text: str) -> str:
    compact = "".join(text.split())
    padding = (-len(compact)) % 4
    try:
        return base64.b64decode(compact + ("=" * padding)).decode("utf-8")
    except Exception as exc:
        raise ValueError("subscription content is neither Clash YAML nor a supported base64 subscription") from exc


def normalize_node_name(raw_name: str | None, fallback: str) -> str:
    if not raw_name:
        return fallback
    name = unquote(raw_name).strip()
    return name or fallback


def parse_bool_flag(values: list[str] | None, default: bool = False) -> bool:
    if not values:
        return default
    value = values[-1].strip().lower()
    return value in {"1", "true", "yes", "on"}


def is_metadata_node(name: str) -> bool:
    lowered = name.lower()
    return any(keyword in lowered for keyword in METADATA_KEYWORDS)


def parse_trojan_uri(uri: str, index: int) -> dict:
    parsed = urlsplit(uri)
    if not parsed.hostname or parsed.port is None or parsed.username is None:
        raise ValueError(f"invalid trojan URI at line {index}")

    query = parse_qs(parsed.query, keep_blank_values=True)
    name = normalize_node_name(parsed.fragment, f"trojan-{index:03d}")
    proxy = {
        "name": name,
        "type": "trojan",
        "server": parsed.hostname,
        "port": parsed.port,
        "password": unquote(parsed.username),
        "udp": True,
        "skip-cert-verify": parse_bool_flag(query.get("allowInsecure")),
    }
    sni = query.get("sni") or query.get("peer")
    if sni:
        proxy["sni"] = sni[-1]
    alpn = query.get("alpn")
    if alpn:
        proxy["alpn"] = [item for item in alpn[-1].split(",") if item]
    return proxy


def parse_ss_uri(uri: str, index: int) -> dict:
    parsed = urlsplit(uri)
    raw_netloc = parsed.netloc
    fragment_name = normalize_node_name(parsed.fragment, f"ss-{index:03d}")
    if "@" in raw_netloc:
        userinfo, hostinfo = raw_netloc.rsplit("@", 1)
        decoded = unquote(userinfo)
    else:
        decoded_netloc = decode_base64_text(raw_netloc)
        if "@" not in decoded_netloc:
            raise ValueError(f"invalid ss URI at line {index}")
        decoded, hostinfo = decoded_netloc.rsplit("@", 1)

    if ":" not in decoded or ":" not in hostinfo:
        raise ValueError(f"invalid ss URI at line {index}")

    cipher, password = decoded.split(":", 1)
    server, port_text = hostinfo.rsplit(":", 1)
    proxy = {
        "name": fragment_name,
        "type": "ss",
        "server": server.strip("[]"),
        "port": int(port_text),
        "cipher": cipher,
        "password": unquote(password),
        "udp": True,
    }

    query = parse_qs(parsed.query, keep_blank_values=True)
    plugin = query.get("plugin")
    if plugin:
        proxy["plugin"] = plugin[-1]
    return proxy


def parse_vmess_uri(uri: str, index: int) -> dict:
    parsed = urlsplit(uri)
    payload = yaml.safe_load(decode_base64_text(parsed.netloc))
    if not isinstance(payload, dict):
        raise ValueError(f"invalid vmess URI at line {index}")

    name = normalize_node_name(payload.get("ps"), f"vmess-{index:03d}")
    network = payload.get("net") or "tcp"
    proxy = {
        "name": name,
        "type": "vmess",
        "server": payload["add"],
        "port": int(payload["port"]),
        "uuid": payload["id"],
        "alterId": int(payload.get("aid") or 0),
        "cipher": payload.get("scy") or "auto",
        "udp": True,
        "network": network,
    }

    host = payload.get("host")
    path = payload.get("path")
    if host:
        proxy["servername"] = host
    tls = str(payload.get("tls") or "").lower()
    if tls in {"tls", "1", "true"}:
        proxy["tls"] = True
        if host:
            proxy["servername"] = host
    if network == "ws":
        ws_opts = {}
        if path:
            ws_opts["path"] = path
        if host:
            ws_opts["headers"] = {"Host": host}
        if ws_opts:
            proxy["ws-opts"] = ws_opts
    return proxy


def parse_uri_subscription(text: str) -> dict:
    if "://" not in text:
        text = decode_base64_text(text)
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        raise ValueError("subscription does not contain any node URIs")

    proxies = []
    skipped = []
    for index, line in enumerate(lines, start=1):
        scheme = line.split("://", 1)[0].lower()
        try:
            if scheme == "trojan":
                proxies.append(parse_trojan_uri(line, index))
            elif scheme == "ss":
                proxies.append(parse_ss_uri(line, index))
            elif scheme == "vmess":
                proxies.append(parse_vmess_uri(line, index))
            else:
                skipped.append(scheme or f"line-{index}")
        except Exception as exc:
            raise ValueError(f"failed to parse {scheme or 'unknown'} subscription line {index}: {exc}") from exc

    if not proxies:
        unsupported = ", ".join(sorted(set(skipped))) if skipped else "unknown"
        raise ValueError(f"no supported node URIs were found in the subscription (unsupported: {unsupported})")

    return {"proxies": proxies}


def load_subscription(path: Path) -> dict:
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        raise ValueError("subscription content is empty")
    try:
        return load_yaml_text(text)
    except Exception:
        return parse_uri_subscription(text)


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
        if is_metadata_node(str(name)):
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
    data = load_subscription(source_path)
    rendered = ensure_proxy_chain(data)
    output_path.write_text(
        yaml.safe_dump(rendered, allow_unicode=False, sort_keys=False),
        encoding="utf-8",
    )
    print(f"wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
