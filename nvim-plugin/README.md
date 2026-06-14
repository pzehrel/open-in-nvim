# Open In Nvim 插件

让普通启动的 Neovim 自动开启 RPC server，方便 macOS App 把 Finder 中选择的文件发送到已有 nvim 实例。

## 安装

使用 lazy.nvim：

```lua
{
  dir = "/path/to/open-in-nvim/nvim-plugin",
  name = "open-in-nvim",
  config = function()
    require("open-in-nvim").setup()
  end,
}
```

也可以直接把 `nvim-plugin/lua/open-in-nvim` 复制到你的 Neovim 配置目录。

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
