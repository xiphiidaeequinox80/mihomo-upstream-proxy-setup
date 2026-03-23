#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/mihomo"
RAW_PATH="${CONFIG_DIR}/subscription.raw.yaml"
CONFIG_PATH="${CONFIG_DIR}/config.yaml"
ENV_PATH="${CONFIG_DIR}/env.sh"
GENERATOR_PATH="${GENERATOR_PATH:-${PWD}/scripts/update_mihomo_config.py}"
MIHOMO_BIN="${MIHOMO_BIN:-/usr/local/bin/mihomo}"

mkdir -p "${CONFIG_DIR}"

if [[ -f "${ENV_PATH}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_PATH}"
fi

INTERNAL_PROXY_URL="${INTERNAL_PROXY_URL:-http://proxy.example.internal:3128}"
SUBSCRIPTION_URL="${MIHOMO_SUBSCRIPTION_URL:-https://example.com/your-subscription?clash=1}"

HTTP_PROXY="${INTERNAL_PROXY_URL}" \
HTTPS_PROXY="${INTERNAL_PROXY_URL}" \
NO_PROXY="" \
curl -fsSL --connect-timeout 20 --max-time 180 \
  "${SUBSCRIPTION_URL}" \
  -o "${RAW_PATH}"

python3 "${GENERATOR_PATH}" "${RAW_PATH}" "${CONFIG_PATH}"
"${MIHOMO_BIN}" -t -f "${CONFIG_PATH}"
echo "mihomo config refreshed: ${CONFIG_PATH}"
