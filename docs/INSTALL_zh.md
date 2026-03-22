# 安装指南（中文）

这份文档给出一个从零开始的可执行安装流程，用于把服务器配置成：

`程序 -> 本机 mihomo -> 内部 HTTP 代理 -> YAML 订阅节点 -> 外网`

适用场景：

- 服务器本身直连外网能力较差
- 存在一个内部 HTTP 代理可用于出站
- 有可用的 Clash YAML 订阅
- 希望绝大多数外网流量走 `mihomo`

## 1. 前提条件

服务器侧需要：

- Linux
- root 权限
- `curl`
- `python3`
- `git`（可选）
- `systemd`

已验证本仓库方案可运行于：

- Ubuntu 22.04

## 2. 获取仓库

```bash
git clone https://github.com/JiaranI/mihomo-upstream-proxy-setup.git
cd mihomo-upstream-proxy-setup
```

如果服务器上 GitHub SSH 不通，建议使用 HTTPS 克隆，并让 Git 走本地 `mihomo` 代理或现有可用代理。

## 3. 安装 mihomo

在服务器上安装 `mihomo` 二进制。

安装完成后验证：

```bash
/usr/local/bin/mihomo -v
```

如果你需要手动下载发布包，可以从 `MetaCubeX/mihomo` 的 GitHub Releases 获取适合当前架构的 Linux 版本。

## 4. 准备目录

创建运行目录：

```bash
mkdir -p ~/.config/mihomo
mkdir -p ~/.local/bin
```

把仓库里的脚本和 shell helper 放到合适位置：

```bash
cp scripts/update_mihomo_config.py ~/.config/mihomo/
cp scripts/refresh_mihomo.sh ~/.local/bin/
cp shell/mihomo_helpers.zsh ~/.config/mihomo/
cp shell/mihomo_helpers.bash ~/.config/mihomo/
chmod +x ~/.config/mihomo/update_mihomo_config.py
chmod +x ~/.local/bin/refresh_mihomo.sh
```

## 5. 设置环境变量

最少需要这四个值：

```bash
export INTERNAL_PROXY_URL='http://proxy.example.internal:3128'
export INTERNAL_PROXY_SERVER='proxy.example.internal'
export INTERNAL_PROXY_PORT='3128'
export MIHOMO_SUBSCRIPTION_URL='https://example.com/your-subscription?clash=1'
```

含义：

- `MIHOMO_SUBSCRIPTION_URL`
  - Clash YAML 订阅地址
  - 用来下载原始节点配置
- `INTERNAL_PROXY_URL`
  - 内部 HTTP 代理完整 URL
  - 给 `refresh_mihomo.sh` 里的 `curl` 下载订阅用
- `INTERNAL_PROXY_SERVER`
  - 内部 HTTP 代理主机名/IP
  - 给 `mihomo` 最终配置里的 `corp-http` 节点用
- `INTERNAL_PROXY_PORT`
  - 内部 HTTP 代理端口
  - 和 `INTERNAL_PROXY_SERVER` 配套使用

## 6. 生成配置

执行：

```bash
GENERATOR_PATH="$PWD/scripts/update_mihomo_config.py" ~/.local/bin/refresh_mihomo.sh
```

这一步会：

1. 下载订阅 YAML
2. 保存到 `~/.config/mihomo/subscription.raw.yaml`
3. 生成运行配置 `~/.config/mihomo/config.yaml`
4. 用 `mihomo -t` 验证配置

## 7. 准备 systemd 服务

把仓库里的模板服务文件复制到系统目录：

```bash
cp systemd/mihomo.service /etc/systemd/system/mihomo.service
```

注意：仓库中的 `systemd/mihomo.service` 是模板。

如果你的用户名、home 目录或脚本路径不同，需要按实际环境调整以下几项：

- `User=`
- `WorkingDirectory=`
- `ExecStartPre=`
- `ExecStart=`

对于 root 用户的典型形式，可以参考：

```ini
[Unit]
Description=Mihomo proxy client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.config/mihomo
ExecStartPre=/root/.local/bin/refresh_mihomo.sh
ExecStart=/usr/local/bin/mihomo -f /root/.config/mihomo/config.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

启用服务：

```bash
systemctl daemon-reload
systemctl enable --now mihomo.service
systemctl status mihomo
```

## 8. 配置 shell

### 8.1 推荐做法：抽出独立 helper 文件

不建议把一大段 `mihomo` 函数直接堆进 `~/.bashrc` 或 `~/.zshrc`。

推荐方式是：

- `~/.config/mihomo/mihomo_helpers.zsh`
- `~/.config/mihomo/mihomo_helpers.bash`

然后在 rc 文件里只保留一行 `source`。

`~/.zshrc`：

```bash
if [ -f ~/.config/mihomo/mihomo_helpers.zsh ]; then
    source ~/.config/mihomo/mihomo_helpers.zsh
fi
```

`~/.bashrc`：

```bash
if [ -f ~/.config/mihomo/mihomo_helpers.bash ]; then
    . ~/.config/mihomo/mihomo_helpers.bash
fi
```

### 8.2 helper 文件里包含什么

helper 文件里已经包含：

- `mihomo_proxy_on`
- `mihomo_proxy_off`
- `mihomo_refresh`
- `mihomo_current_node`
- `mihomo_use_node`
- `mihomo_use_auto`
- `mihomo_restart`
- `mihomo_set_subscription`
- `openai_proxy_on`
- `openai_proxy_off`
- 自动启用代理逻辑

## 9. 验证

### 9.1 验证普通外网

```bash
curl --proxy http://127.0.0.1:7890 -I https://www.google.com
```

### 9.2 验证 OpenAI

```bash
curl --proxy http://127.0.0.1:7890 -I https://api.openai.com/v1/models
```

如果返回 `401`，说明链路已经打通，只是没有提供 API key。

### 9.3 验证当前节点

```bash
curl -s http://127.0.0.1:9090/proxies/PROXY
curl -s http://127.0.0.1:9090/proxies/AUTO
```

## 10. 切换节点

固定某个节点：

```bash
curl -X PUT http://127.0.0.1:9090/proxies/PROXY \
  -H 'Content-Type: application/json' \
  -d '{"name":"USA-01"}'
```

切回自动：

```bash
curl -X PUT http://127.0.0.1:9090/proxies/PROXY \
  -H 'Content-Type: application/json' \
  -d '{"name":"AUTO"}'
```

## 11. 更新订阅

```bash
~/.local/bin/refresh_mihomo.sh
systemctl restart mihomo
```

如果更换订阅地址：

```bash
export MIHOMO_SUBSCRIPTION_URL='https://your-new-subscription?clash=1'
~/.local/bin/refresh_mihomo.sh
systemctl restart mihomo
```

## 12. 关于 xterm-ghostty

如果你本地终端把 `TERM=xterm-ghostty` 传到服务器，而远端缺少对应 terminfo，`zsh` 的 `Backspace` 等按键可能异常。

可以在本机执行：

```bash
infocmp -x xterm-ghostty | ssh your-server 'tic -x -'
```

然后在服务器验证：

```bash
infocmp xterm-ghostty
```

如果能正常输出，说明远端已经支持 `xterm-ghostty`。
