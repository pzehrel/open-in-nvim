# Open In Nvim Plugin

<p>
  English | <a href="README.zh-CN.md">简体中文</a>
</p>

This plugin starts a Neovim RPC server for normal `nvim` launches with Neovim's `serverstart()` function, so the macOS app can send files selected in Finder to an existing nvim instance.

## Install

Install from GitHub with lazy.nvim. For example, create `lua/plugins/open-in-nvim.lua`:

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

## Configuration

Default setup:

```lua
require("open-in-nvim").setup()
```

The plugin writes a state file:

```text
~/.local/state/nvim/open-in-nvim/server
```

It contains the current instance's server, cwd, pid, and update time. If nvim is running inside tmux, it also records `tmux` and `tmux_pane`.

The state file is refreshed when the instance receives focus or changes buffers, and it is removed on exit when it still points to that instance.
