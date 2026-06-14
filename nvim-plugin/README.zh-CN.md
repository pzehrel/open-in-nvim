# Open In Nvim 插件

<p>
  <a href="README.md">English</a> | 简体中文
</p>

让普通启动的 Neovim 自动开启 RPC server，方便 macOS App 把 Finder 中选择的文件发送到已有 nvim 实例。

## 安装

使用 lazy.nvim 从 GitHub 安装。例如创建 `lua/plugins/open-in-nvim.lua`：

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

## 配置

默认配置：

```lua
require("open-in-nvim").setup()
```

插件会写入状态文件：

```text
~/.local/state/nvim/open-in-nvim/server
```

其中包含当前实例的 server、cwd、pid 和更新时间。如果 nvim 运行在 tmux 中，也会记录 `tmux` 和 `tmux_pane`。
