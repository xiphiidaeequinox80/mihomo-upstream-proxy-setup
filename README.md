# Mihomo Proxy Setup

A small, reproducible setup for routing local traffic through `mihomo`, while using an internal HTTP proxy as the upstream dialer for subscription nodes.

Traffic path:

`program -> local mihomo -> internal proxy -> subscription nodes -> internet`

## Recommended Path

For a normal Linux host with `root`, `systemd`, `curl`, and `python3`, use the one-command installer.

```bash
sudo INTERNAL_PROXY_URL='http://proxy.example.internal:3128' \
  INTERNAL_PROXY_SERVER='proxy.example.internal' \
  INTERNAL_PROXY_PORT='3128' \
  MIHOMO_SUBSCRIPTION_URL='https://example.com/your-subscription?clash=1' \
  ./scripts/install.sh
```

The installer will:

- install `mihomo`
- install scripts and shell helpers
- write `~/.config/mihomo/env.sh`
- generate `config.yaml`
- install and enable `mihomo.service`
- wire `~/.zshrc` and `~/.bashrc`

## Required Inputs

You need to provide these values:

- `INTERNAL_PROXY_URL`: full upstream HTTP proxy URL, used by `curl` when refreshing subscription
- `INTERNAL_PROXY_SERVER`: upstream HTTP proxy host, used in runtime `mihomo` config
- `INTERNAL_PROXY_PORT`: upstream HTTP proxy port
- `MIHOMO_SUBSCRIPTION_URL`: Clash YAML subscription URL

After installation, these values are persisted in:

- `~/.config/mihomo/env.sh`

## Included

- `scripts/install.sh`: one-command installer for a new host
- `scripts/update_mihomo_config.py`: converts a Clash YAML subscription into a runtime `mihomo` config and injects `dialer-proxy`
- `scripts/refresh_mihomo.sh`: fetches subscription YAML and regenerates config
- `systemd/mihomo.service`: example service template
- `shell/mihomo_helpers.zsh`: zsh helper functions
- `shell/mihomo_helpers.bash`: bash helper functions
- `docs/INSTALL_zh.md`: Chinese install guide
- `docs/USAGE_zh.md`: Chinese usage notes
- `docs/TUTORIAL_zh.md`: Chinese setup tutorial

## Documentation

- [Chinese install guide](docs/INSTALL_zh.md)
- [Chinese usage notes](docs/USAGE_zh.md)
- [Chinese tutorial](docs/TUTORIAL_zh.md)

## Manual Path

If you need to inspect or customize each step manually, see the install guide. The manual path is now treated as an advanced or debugging workflow, not the default path.

## Sensitive Data

Do not commit your real subscription URL, raw subscription file, generated config, or node credentials.

This repository only contains sanitized templates.
