local M = {}

local defaults = {
  state_file = vim.fn.stdpath("state") .. "/open-in-nvim/server",
}

local current = {
  server = nil,
  state_file = nil,
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

local function read_state_server(path)
  if path == nil or path == "" or vim.fn.filereadable(path) == 0 then
    return nil
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    local server = line:match("^server=(.*)$")
    if server ~= nil then
      return server
    end
  end

  return nil
end

local function remove_state_if_current()
  if current.state_file == nil or current.state_file == "" or current.server == nil or current.server == "" then
    return
  end

  if read_state_server(current.state_file) == current.server then
    pcall(vim.fn.delete, current.state_file)
  end
end

local function refresh_state()
  if current.state_file ~= nil and current.state_file ~= "" and current.server ~= nil and current.server ~= "" then
    write_state(current.state_file, current.server)
  end
end

local function start_server()
  local ok, server = pcall(vim.fn.serverstart)
  if ok and server ~= nil and server ~= "" then
    return server
  end

  if vim.v.servername ~= nil and vim.v.servername ~= "" then
    return vim.v.servername
  end

  return nil
end

function M.setup(opts)
  opts = vim.tbl_extend("force", defaults, opts or {})

  current.server = start_server()
  current.state_file = opts.state_file

  if current.server == nil or current.server == "" then
    return
  end

  local group = vim.api.nvim_create_augroup("OpenInNvim", { clear = true })

  vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "DirChanged", "BufEnter" }, {
    group = group,
    callback = refresh_state,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = remove_state_if_current,
  })

  refresh_state()
end

return M
