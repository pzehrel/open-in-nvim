---
created: 2026-06-10
type: note
status: active
tags: [macos, nvim]
---

# 在 macOS 中用 nvim 打开文件和文件夹

这是一个很小的 macOS App，用来把 Finder 里的文件或文件夹交给 Neovim：

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
~/Applications/在 nvim 中打开.app
```

如果 Finder 的右键菜单没有立刻出现，可以登出重进，或在系统设置里检查：

```text
键盘 -> 键盘快捷键 -> 服务/快速操作
```

## 终端配置

直接打开 `~/Applications/在 nvim 中打开.app` 会显示设置窗口，可以选择：

- 自动选择
- Ghostty
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
- `iterm`
- `terminal`
- 任意支持 AppleScript `do script` 的终端 App 名称

如果你的第三方终端启动方式比较特殊，可以直接覆盖命令：

```sh
OPEN_IN_NVIM_TERMINAL_CMD='open -na Ghostty --args -e /bin/zsh -lc {cmd}'
```

`{cmd}` 会被替换为已经 shell-quote 的命令。

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
