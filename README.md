---
created: 2026-06-10
type: note
status: active
tags: [macos, nvim]
---

# Open-In-Nvim

这是一个很小的 macOS App，用来把 Finder 里的文件或文件夹交给 Neovim：

- 在支持的 Finder 目录中，右键菜单会直接显示“在 nvim 中打开”。
- 右键文件或文件夹，选择“快速操作”或“服务”里的“在 nvim 中打开”。
- 在“打开方式”里选择“在 nvim 中打开”，也可以把它设为某些文件类型的默认打开方式。
- 打开文件时，如果系统里已经有可连接的 nvim 实例，会把文件放进已有 nvim 的 buffer。
- 打开文件夹时，始终新开一个终端窗口，并在该目录里运行 `nvim .`。
- 没有已有 nvim 实例时，打开文件也会新开终端。

## 安装

```sh
make install
```

安装后 App 会位于：

```text
/Applications/Open-In-Nvim.app
```

如果 Finder 根菜单没有立刻出现，可以在系统设置里启用 Finder 扩展：

```text
隐私与安全性 -> 扩展 -> Finder 扩展 -> Open-In-Nvim Finder Extension
```

如果服务菜单没有立刻出现，可以登出重进，或在系统设置里检查：

```text
键盘 -> 键盘快捷键 -> 服务/快速操作
```

## 终端配置

直接打开 `/Applications/Open-In-Nvim.app` 会显示设置窗口，可以选择：

- 自动选择
- Ghostty
- Alacritty
- iTerm2
- Terminal.app
- 自定义 App 名称

设置会保存到：

```text
~/.config/open-in-nvim/config
```

也可以手动编辑配置文件：

```sh
mkdir -p ~/.config/open-in-nvim
nvim ~/.config/open-in-nvim/config
```

示例：

```sh
OPEN_IN_NVIM_TERMINAL=ghostty
OPEN_IN_NVIM_NVIM=/opt/homebrew/bin/nvim
```

支持的 `OPEN_IN_NVIM_TERMINAL` 值：

- `auto`
- `ghostty`
- `alacritty`
- `iterm`
- `terminal`
- 任意支持 AppleScript `do script` 的终端 App 名称

如果你的第三方终端启动方式比较特殊，可以直接覆盖命令：

```sh
OPEN_IN_NVIM_TERMINAL_CMD='open -na Ghostty --args -e /bin/zsh -lc {cmd}'
```

`{cmd}` 会被替换为已经 shell-quote 的命令。

## Finder 根菜单

App 内置 Finder Sync Extension。启用后，在 Finder 的受监控目录中右键文件或文件夹，会直接看到“在 nvim 中打开”菜单项。

当前默认监控：

- 用户个人目录 `~/`
- 外接卷目录 `/Volumes`

macOS 对 Finder Sync Extension 有系统级限制；如果某个位置没有显示根菜单项，可以继续使用“快速操作/服务”入口作为兜底。

如果系统设置里没有出现这个扩展，通常需要使用完整 Xcode 工具链和开发者签名重新构建。当前 Makefile 会进行 ad-hoc 签名，适合本机开发验证；不同 macOS 版本对手工构建的 Finder Sync Extension 接受程度可能不同。

## 已有 nvim 实例

脚本会使用：

```sh
nvim --serverlist
nvim --server <address> --remote <file>
```

因此只要已有 nvim 出现在 `nvim --serverlist` 里，文件就会打开到该实例中。

如果你想固定发送到某个实例，可以在配置文件中设置：

```sh
OPEN_IN_NVIM_SERVER=/tmp/my-nvim.sock
```

然后用这个地址启动 nvim：

```sh
nvim --listen /tmp/my-nvim.sock
```

## 开发

```sh
make build
open build/在\ nvim\ 中打开.app
```

核心逻辑在 `Resources/open-in-nvim.sh`，macOS 服务和默认打开方式入口在 `Sources/OpenInNvim/main.swift`。
