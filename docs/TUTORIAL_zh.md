# 配置教程（中文）

## 目标

把服务器流量改造成：

`程序 -> 本机 mihomo -> 内部代理 -> YAML 节点 -> 外网`

## 关键点

- 原始订阅使用 Clash YAML
- 最终运行配置不是原始订阅，而是由脚本转换生成
- 每个代理节点会被注入 `dialer-proxy`
- 默认规则为 `MATCH,PROXY`

## 目录结构

- `scripts/update_mihomo_config.py`
- `scripts/refresh_mihomo.sh`
- `systemd/mihomo.service`
- `docs/`

## 注意事项

- 不要把真实订阅 URL 提交到 GitHub
- 不要提交 `subscription.raw.yaml`
- 不要提交生成后的 `config.yaml`
- 不要提交任何节点密码或内部代理地址
