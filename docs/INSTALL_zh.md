# 安装指南（中文）

这份文档给出一个从零开始的可执行安装流程，用于把服务器配置成：

`程序 -> 本机 mihomo -> 内部 HTTP 代理 -> YAML 订阅节点 -> 外网`

适用场景：

- 服务器本身直连外网能力较差
- 存在一个内部 HTTP 代理可用于出站
- 有可用的 Clash YAML 订阅
- 希望绝大多数外网流量走 `mihomo`

## 1. 推荐路径

对正常的 Linux 服务器，默认推荐直接使用仓库里的安装脚本，而不是手工一条条执行。

你需要提供四个值：

- `INTERNAL_PROXY_URL`
- `INTERNAL_PROXY_SERVER`
- `INTERNAL_PROXY_PORT`
- `MIHOMO_SUBSCRIPTION_URL`

然后执行：

```bash
sudo INTERNAL_PROXY_URL='http://proxy.example.internal:3128' \
  INTERNAL_PROXY_SERVER='proxy.example.internal' \
  INTERNAL_PROXY_PORT='3128' \
  MIHOMO_SUBSCRIPTION_URL='https://example.com/your-subscription?clash=1' \
  ./scripts/install.sh
```

这个脚本会自动完成：

1. 下载并安装 `mihomo`
2. 复制脚本和 helper 文件
3. 写入 `~/.config/mihomo/env.sh`
4. 接入 `~/.zshrc` 和 `~/.bashrc`
5. 生成运行配置
6. 安装并启动 `mihomo.service`

安装完成后，长期持久化配置在：

- `~/.config/mihomo/env.sh`

后面如果只是换订阅或改上游代理，优先改这个文件，不要再去改安装脚本。

## 2. 前提条件

服务器侧需要：

- Linux
- root 权限
- `curl`
- `python3`
- `systemd`

可选：

- `git`

已验证本仓库方案可运行于：

- Ubuntu 22.04

## 3. 获取仓库

```bash
git clone https://github.com/JiaranI/mihomo-upstream-proxy-setup.git
cd mihomo-upstream-proxy-setup
```

如果服务器上 GitHub SSH 不通，建议使用 HTTPS 克隆，并让 Git 走本地 `mihomo` 代理或现有可用代理。

## 4. 四个关键配置项的作用

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

这些值在一键安装成功后，会被持久化到：

```bash
~/.config/mihomo/env.sh
```

`refresh_mihomo.sh` 和 shell helper 会自动 source 这个文件。

## 5. 安装完成后的结果

如果安装脚本执行成功，通常会得到：

- `mihomo` 可执行文件
- `~/.config/mihomo/config.yaml`
- `~/.config/mihomo/env.sh`
- `~/.config/mihomo/mihomo_helpers.zsh`
- `~/.config/mihomo/mihomo_helpers.bash`
- `~/.local/bin/refresh_mihomo.sh`
- `mihomo.service`
- `~/.zshrc` / `~/.bashrc` 中的 helper `source` 入口

## 6. 验证

### 6.1 验证普通外网

```bash
curl --proxy http://127.0.0.1:7890 -I https://www.google.com
```

### 6.2 验证 OpenAI

```bash
curl --proxy http://127.0.0.1:7890 -I https://api.openai.com/v1/models
```

如果返回 `401`，说明链路已经打通，只是没有提供 API key。

## 7. 手工安装路径（进阶/排障）

如果你需要手工调试每一步，或者目标环境不适合直接运行 `install.sh`，再看这一节。

### 7.1 手工安装 mihomo

安装完成后验证：

```bash
/usr/local/bin/mihomo -v
```

如果你需要手动下载发布包，可以从 `MetaCubeX/mihomo` 的 GitHub Releases 获取适合当前架构的 Linux 版本。

### 7.2 准备目录

```bash
mkdir -p ~/.config/mihomo
mkdir -p ~/.local/bin
```

这里要区分“仓库中的源文件位置”和“机器上的最终生效位置”：

- 仓库中的源文件：
  - `scripts/update_mihomo_config.py`
  - `scripts/refresh_mihomo.sh`
  - `shell/mihomo_helpers.zsh`
  - `shell/mihomo_helpers.bash`
- 机器上的最终生效位置：
  - `~/.config/mihomo/update_mihomo_config.py`
  - `~/.local/bin/refresh_mihomo.sh`
  - `~/.config/mihomo/mihomo_helpers.zsh`
  - `~/.config/mihomo/mihomo_helpers.bash`
  - `~/.config/mihomo/env.sh`

复制命令：

```bash
cp scripts/update_mihomo_config.py ~/.config/mihomo/
cp scripts/refresh_mihomo.sh ~/.local/bin/
cp shell/mihomo_helpers.zsh ~/.config/mihomo/
cp shell/mihomo_helpers.bash ~/.config/mihomo/
chmod +x ~/.config/mihomo/update_mihomo_config.py
chmod +x ~/.local/bin/refresh_mihomo.sh
```

### 7.3 手工生成配置

执行：

```bash
GENERATOR_PATH="$PWD/scripts/update_mihomo_config.py" ~/.local/bin/refresh_mihomo.sh
```

这一步会：

1. 下载订阅 YAML
2. 保存到 `~/.config/mihomo/subscription.raw.yaml`
3. 生成运行配置 `~/.config/mihomo/config.yaml`
4. 用 `mihomo -t` 验证配置

### 7.4 手工准备 systemd 服务

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

### 7.5 手工配置 shell

不建议把一大段 `mihomo` 函数直接堆进 `~/.bashrc` 或 `~/.zshrc`。

推荐方式是：

- 仓库中保存一份 helper 模板：
  - `shell/mihomo_helpers.zsh`
  - `shell/mihomo_helpers.bash`
- 安装时把它们复制到本机实际生效位置：
  - `~/.config/mihomo/mihomo_helpers.zsh`
  - `~/.config/mihomo/mihomo_helpers.bash`
- 最后在 rc 文件里只保留一行 `source`

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
