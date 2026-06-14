<p align="center">
  <img src="Resources/AppIcon.png" alt="Open In Nvim logo" width="128" height="128">
</p>

<h1 align="center">Open In Nvim</h1>

<p align="center">
  从 Finder 右键菜单、“打开方式”或默认打开方式，把文件和文件夹快速交给 Neovim。
</p>

## 功能

- 在支持的 Finder 目录中，右键菜单会直接显示“在 nvim 中打开”。
- 右键文件或文件夹，选择“快速操作”或“服务”里的“在 nvim 中打开”。
- 在“打开方式”里选择“在 nvim 中打开”，也可以把它设为某些文件类型的默认打开方式。
- 打开文件时，如果系统里已经有可连接的 nvim 实例，会把文件放进已有 nvim 的 buffer。
- 打开文件夹时，始终新开一个终端窗口，并在该目录里运行 `nvim .`。
- 没有已有 nvim 实例时，打开文件也会新开终端。

## 安装

```sh
make dmg
open "dist/Open In Nvim.dmg"
```

打开 DMG 后，把 `Open In Nvim.app` 拖到 `Applications` 即可。安装后 App 会位于：

```text
/Applications/Open In Nvim.app
```

从旧版本升级时，建议先删除 `/Applications/Open In Nvim.app`，再从 DMG 中拖入新版本。如果右键服务仍然指向旧版本，可以刷新 macOS Services 缓存：

```sh
/System/Library/CoreServices/pbs -flush
/System/Library/CoreServices/pbs -update
```

如果 Finder 根菜单没有立刻出现，可以在系统设置里启用 Finder 扩展：

```text
隐私与安全性 -> 扩展 -> Finder 扩展 -> Open In Nvim Finder Extension
```

如果服务菜单没有立刻出现，可以登出重进，或在系统设置里检查：

```text
键盘 -> 键盘快捷键 -> 服务/快速操作
```

## 终端配置

直接打开 `/Applications/Open In Nvim.app` 会显示设置窗口，可以选择：

- 语言（自动、简体中文、English）
- 自动选择
- Ghostty
- Alacritty
- iTerm2
- Terminal.app
- 自定义 App 名称

如果文件会打开到已有 nvim 实例，也可以选择打开方式：

- 新标签页
- 水平窗口
- 垂直窗口
- 只打开 buffer

如果没有可连接的已有 nvim，需要新开 nvim，也可以选择是否使用 tmux：

- 关闭：直接在终端里启动 nvim
- 自动：检测到 `tmux` 时，在 tmux session 里新建 window
- 始终使用：强制使用 tmux，找不到 `tmux` 时会报错

tmux session 默认留空。留空时，每次需要新建 nvim 都会创建一个新的 tmux session；填写名称后，如果该 session 已存在，会在其中新建 window，如果不存在，会创建该 session。

还可以勾选哪些文件扩展名默认使用 Open In Nvim 打开，并添加自定义扩展名。默认扩展名：

```text
ts rs py json css scss less sass c cpp
```

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
OPEN_IN_NVIM_LANGUAGE=auto
OPEN_IN_NVIM_TERMINAL=ghostty
OPEN_IN_NVIM_NVIM=/opt/homebrew/bin/nvim
OPEN_IN_NVIM_REMOTE_OPEN=tab
OPEN_IN_NVIM_DEFAULT_EXTENSIONS='ts rs py json css scss less sass c cpp'
OPEN_IN_NVIM_STATE_FILE="$HOME/.local/state/nvim/open-in-nvim/server"
OPEN_IN_NVIM_TMUX=auto
OPEN_IN_NVIM_TMUX_SESSION=''
```

支持的 `OPEN_IN_NVIM_TERMINAL` 值：

- `auto`
- `ghostty`
- `alacritty`
- `iterm`
- `terminal`
- 任意支持 AppleScript `do script` 的终端 App 名称

支持的 `OPEN_IN_NVIM_LANGUAGE` 值：

- `auto`
- `zh-Hans`
- `en`

如果你的第三方终端启动方式比较特殊，可以直接覆盖命令：

```sh
OPEN_IN_NVIM_TERMINAL_CMD='open -na Ghostty --args -e /bin/zsh -lc {cmd}'
```

`{cmd}` 会被替换为已经 shell-quote 的命令。

支持的 `OPEN_IN_NVIM_TMUX` 值：

- `never`
- `auto`
- `always`

## Finder 根菜单

App 内置 Finder Sync Extension。启用后，在 Finder 的受监控目录中右键文件或文件夹，会直接看到“在 nvim 中打开”菜单项。

当前默认监控：

- 用户个人目录 `~/`
- 外接卷目录 `/Volumes`

macOS 对 Finder Sync Extension 有系统级限制；如果某个位置没有显示根菜单项，可以继续使用“快速操作/服务”入口作为兜底。

如果系统设置里没有出现这个扩展，通常需要使用完整 Xcode 工具链和开发者签名重新构建。当前 Makefile 会进行 ad-hoc 签名，适合本机开发验证；不同 macOS 版本对手工构建的 Finder Sync Extension 接受程度可能不同。

## 已有 nvim 实例

推荐安装仓库内置的 nvim 插件。插件会在普通启动 nvim 时自动开启 RPC server，因此不需要手动执行 `nvim --listen`。

使用 lazy.nvim 安装本地插件：

```lua
{
  dir = "/path/to/open-in-nvim/nvim-plugin",
  name = "open-in-nvim",
  config = function()
    require("open-in-nvim").setup()
  end,
}
```

安装后，照常启动：

```sh
nvim
```

App 会优先使用：

```sh
~/.local/state/nvim/open-in-nvim/server
nvim --serverlist
nvim --server <address> --remote-tab <file>
```

因此只要已有 nvim 出现在 `nvim --serverlist` 里，文件就会打开到该实例中。`OPEN_IN_NVIM_REMOTE_OPEN` 支持 `tab`、`split`、`vsplit`、`buffer`。

## 开发

本地生成 DMG：

```sh
make dmg
```

输出文件位于：

```text
dist/Open In Nvim.dmg
```

发布版本：

```sh
git tag v0.3.0
git push origin v0.3.0
```

推送 `v*` tag 后，GitHub Actions 会自动构建 DMG、生成 sha256、根据上一个 tag 生成 changelog，并创建 GitHub Release。

核心逻辑在 `Resources/open-in-nvim.sh`，macOS 服务和默认打开方式入口在 `Sources/OpenInNvim/main.swift`。
