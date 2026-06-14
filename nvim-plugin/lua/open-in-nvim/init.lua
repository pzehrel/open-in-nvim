local M = {}

local defaults = {
  state_file = vim.fn.stdpath("state") .. "/open-in-nvim/server",
}

local function mkdir_parent(path)
  local parent = vim.fn.fnamemodify(path, ":h")
  if parent ~= "" then
    vim.fn.mkdir(parent, "p")
  end
end

local function write_state(path, server)
  mkdir_parent(path)
  local lines = {
    "server=" .. server,
    "cwd=" .. vim.fn.getcwd(),
    "pid=" .. tostring(vim.fn.getpid()),
    "time=" .. tostring(os.time()),
  }

  if vim.env.TMUX ~= nil and vim.env.TMUX ~= "" then
    table.insert(lines, "tmux=" .. vim.env.TMUX)
  end

  if vim.env.TMUX_PANE ~= nil and vim.env.TMUX_PANE ~= "" then
    table.insert(lines, "tmux_pane=" .. vim.env.TMUX_PANE)
  end

  vim.fn.writefile(lines, path)
end

function M.setup(opts)
  opts = vim.tbl_extend("force", defaults, opts or {})

  local server = vim.v.servername
  if server == nil or server == "" then
    local ok
    ok, server = pcall(vim.fn.serverstart)

    if not ok then
      return
    end
  end

  if opts.state_file ~= nil and opts.state_file ~= "" and server ~= nil and server ~= "" then
    write_state(opts.state_file, server)
  end
end

return M
