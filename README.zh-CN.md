<p align="center">
  <img src="Resources/AppIcon.png" alt="Open In Nvim logo" width="128" height="128">
</p>

<h1 align="center">Open In Nvim</h1>

<p align="center">
  从 Finder 右键菜单、“打开方式”或默认打开方式，把文件和文件夹快速交给 Neovim。
</p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

## 简介

Open In Nvim 是一个 macOS App。它提供 Finder 入口，把文件或文件夹交给 Neovim：

- Finder 右键菜单中的“在 nvim 中打开”
- Finder “快速操作/服务”入口
- macOS “打开方式”入口
- 某些扩展名的默认打开方式

如果已有可连接的 nvim 实例，文件会优先打开到已有实例中；如果没有，则会打开终端并启动新的 nvim。

## 安装

生成 DMG：

```sh
make dmg
open "dist/Open In Nvim.dmg"
```

打开 DMG 后，把 `Open In Nvim.app` 拖到 `Applications`。

安装位置：

```text
/Applications/Open In Nvim.app
```

从旧版本升级时，建议先删除 `/Applications/Open In Nvim.app`，再从 DMG 中拖入新版本。

## 首次设置

直接打开 `/Applications/Open In Nvim.app` 会显示设置窗口。

常用设置：

- 语言：自动、简体中文、English
- 终端：自动选择、Ghostty、Alacritty、iTerm2、Terminal.app、自定义 App 名称
- 已有 nvim：选择文件进入已有 nvim 时的打开方式
- nvim 插件：自动写入 lazy.nvim 配置到 `~/.config/nvim/lua/plugins/open-in-nvim.lua`
- tmux：没有已有 nvim 时，是否在 tmux 中启动新实例
- 默认扩展名：勾选哪些扩展名默认使用 Open In Nvim 打开

默认扩展名：

```text
ts rs py json css scss less sass c cpp
```

高级设置：

- 自定义终端
- nvim 路径

设置由 App 管理并保存在本机，通常不需要手动编辑配置文件。

## 已有 nvim 实例

Open In Nvim 可以把文件发送到已经运行的 nvim 实例中，但前提是那个 nvim 实例暴露了 Neovim RPC server。普通 `nvim` 进程不一定默认暴露可发现的 server，因此外部 macOS App 可能没有稳定方式连接它。

仓库内置的 nvim 插件就是用来解决这一步配置的。nvim 正常启动时，插件会在需要时自动开启 RPC server，并写入一个 Open In Nvim 可以发现的状态文件。

这样你仍然可以照常启动 nvim：

```sh
nvim
```

不需要手动执行 `nvim --listen ...`。

使用 lazy.nvim 从 GitHub 安装插件。例如创建 `lua/plugins/open-in-nvim.lua`：

```lua
return {
  "pzehrel/open-in-nvim",
  lazy = false,
  config = function(plugin)
    vim.opt.runtimepath:prepend(plugin.dir .. "/nvim-plugin")
    require("open-in-nvim").setup()
  end,
}
```

App 会按顺序寻找可用实例：

```text
~/.local/state/nvim/open-in-nvim/server
Neovim 的 serverlist() RPC 发现
```

插件会通过 Neovim 的 `serverstart()` 函数创建 RPC server，因此普通 `nvim` 启动的实例也可以被 app 复用。然后通过 Neovim RPC 打开文件。打开方式由设置窗口中的“已有 nvim”控制，支持：

- 新标签页
- 水平窗口
- 垂直窗口
- 只打开 buffer

## tmux

tmux 只影响“没有可连接的已有 nvim，需要启动新 nvim”的场景。

模式：

- 关闭：直接在终端里启动 nvim
- 自动：检测到 `tmux` 时，在 tmux 中启动
- 始终使用：强制使用 tmux，找不到 `tmux` 时会报错

`tmux session` 默认留空。留空时，每次需要新建 nvim 都会创建一个新的 tmux session；填写名称后，如果该 session 已存在，会在其中新建 window，如果不存在，会创建该 session。

## Finder 入口

App 内置 Finder Sync Extension。启用后，在 Finder 的受监控目录中右键文件或文件夹，会直接看到“在 nvim 中打开”。

当前默认监控：

- 用户个人目录 `~/`
- 外接卷目录 `/Volumes`

如果 Finder 根菜单没有立刻出现，可以在系统设置里启用 Finder 扩展：

```text
隐私与安全性 -> 扩展 -> Finder 扩展 -> Open In Nvim Finder Extension
```

如果服务菜单没有立刻出现，可以登出重进，或在系统设置里检查：

```text
键盘 -> 键盘快捷键 -> 服务/快速操作
```

macOS 对 Finder Sync Extension 有系统级限制；如果某个位置没有显示根菜单项，可以继续使用“快速操作/服务”入口作为兜底。
