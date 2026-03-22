# 使用说明（中文）

这是一个去敏后的仓库版本，保留了配置逻辑和脚本，但不包含真实订阅地址、节点凭据和内部环境细节。

## 核心思路

- 程序只连本机 `mihomo`
- `mihomo` 再通过内部 HTTP 代理去拨 YAML 订阅节点
- 最终流量默认走 `MATCH,PROXY`

## 使用步骤

1. 准备 `mihomo` 二进制
2. 设置环境变量：

```bash
export INTERNAL_PROXY_URL='http://proxy.example.internal:3128'
export INTERNAL_PROXY_SERVER='proxy.example.internal'
export INTERNAL_PROXY_PORT='3128'
export MIHOMO_SUBSCRIPTION_URL='https://example.com/your-subscription?clash=1'
```

3. 刷新配置：

```bash
./scripts/refresh_mihomo.sh
```

4. 启动 `mihomo`：

```bash
/usr/local/bin/mihomo -f ~/.config/mihomo/config.yaml
```
