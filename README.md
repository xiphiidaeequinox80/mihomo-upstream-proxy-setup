# Mihomo Proxy Setup

A small, reproducible setup for routing local traffic through `mihomo`, while using an internal HTTP proxy as the upstream dialer for subscription nodes.

Traffic path:

`program -> local mihomo -> internal proxy -> subscription nodes -> internet`

## Included

- `scripts/update_mihomo_config.py`: converts a Clash YAML subscription into a runtime `mihomo` config and injects `dialer-proxy`
- `scripts/refresh_mihomo.sh`: fetches subscription YAML and regenerates config
- `systemd/mihomo.service`: example service file
- `shell/mihomo_helpers.zsh`: zsh helper functions
- `shell/mihomo_helpers.bash`: bash helper functions
- `docs/USAGE_zh.md`: Chinese usage notes
- `docs/TUTORIAL_zh.md`: Chinese setup tutorial

## Documentation

- [Chinese install guide](docs/INSTALL_zh.md)
- [Chinese usage notes](docs/USAGE_zh.md)
- [Chinese tutorial](docs/TUTORIAL_zh.md)

## Sensitive Data

Do not commit your real subscription URL, raw subscription file, generated config, or node credentials.

This repository only contains sanitized templates.

## Required Environment Variables

Typical values you should set before use:

- `INTERNAL_PROXY_URL`
- `INTERNAL_PROXY_SERVER`
- `INTERNAL_PROXY_PORT`
- `MIHOMO_SUBSCRIPTION_URL`

## Example

```bash
export INTERNAL_PROXY_URL='http://proxy.example.internal:3128'
export INTERNAL_PROXY_SERVER='proxy.example.internal'
export INTERNAL_PROXY_PORT='3128'
export MIHOMO_SUBSCRIPTION_URL='https://example.com/your-subscription?clash=1'
./scripts/refresh_mihomo.sh
```
