#!/usr/bin/env zsh
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

CONFIG_FILE="${OPEN_IN_NVIM_CONFIG:-$HOME/.config/open-in-nvim/config}"

if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

NVIM_BIN="${OPEN_IN_NVIM_NVIM:-$(command -v nvim || true)}"
TERMINAL="${OPEN_IN_NVIM_TERMINAL:-auto}"
REMOTE_TARGET="${OPEN_IN_NVIM_SERVER:-}"
REMOTE_OPEN="${OPEN_IN_NVIM_REMOTE_OPEN:-tab}"

if [[ -z "$NVIM_BIN" ]]; then
  print -ru2 -- "找不到 nvim。请先安装 Neovim，或在 ~/.config/open-in-nvim/config 中设置 OPEN_IN_NVIM_NVIM。"
  exit 1
fi

quote() {
  printf '%q' "$1"
}

osascript_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

vim_string() {
  local value="$1"
  local squote="'"
  value="${value//$squote/$squote$squote}"
  printf "%s%s%s" "$squote" "$value" "$squote"
}

server_candidates() {
  if [[ -n "$REMOTE_TARGET" ]]; then
    print -r -- "$REMOTE_TARGET"
  fi

  "$NVIM_BIN" --serverlist 2>/dev/null || true
}

first_nvim_server() {
  local server

  while IFS= read -r server; do
    [[ -z "$server" ]] && continue

    if "$NVIM_BIN" --server "$server" --remote-expr 'v:servername' >/dev/null 2>&1; then
      print -r -- "$server"
      return 0
    fi
  done < <(server_candidates)

  return 1
}

remote_open_files() {
  local server="$1"
  shift
  local target
  local expr

  case "$REMOTE_OPEN" in
    tab|tabpage)
      "$NVIM_BIN" --server "$server" --remote-tab "$@"
      ;;
    split|window)
      for target in "$@"; do
        expr="execute('split ' . fnameescape($(vim_string "$target")))"
        "$NVIM_BIN" --server "$server" --remote-expr "$expr" >/dev/null
      done
      ;;
    vsplit|vertical)
      for target in "$@"; do
        expr="execute('vsplit ' . fnameescape($(vim_string "$target")))"
        "$NVIM_BIN" --server "$server" --remote-expr "$expr" >/dev/null
      done
      ;;
    buffer|edit)
      "$NVIM_BIN" --server "$server" --remote "$@"
      ;;
    *)
      "$NVIM_BIN" --server "$server" --remote-tab "$@"
      ;;
  esac
}

new_server_path() {
  local runtime_dir="${TMPDIR:-/tmp}"
  print -r -- "$runtime_dir/open-in-nvim-${USER:-user}-$$-${RANDOM}.sock"
}

terminal_command_for_target() {
  local target="$1"
  local cwd
  local server
  local cmd

  if [[ -d "$target" ]]; then
    cwd="$target"
    cmd="cd $(quote "$cwd"); exec $(quote "$NVIM_BIN") --listen $(quote "$(new_server_path)") ."
  else
    cwd="${target:h}"
    server="$(new_server_path)"
    cmd="cd $(quote "$cwd"); exec $(quote "$NVIM_BIN") --listen $(quote "$server") $(quote "$target")"
  fi

  print -r -- "$cmd"
}

run_terminal_app() {
  local app_name="$1"
  local command="$2"
  local escaped_app
  local escaped_command

  escaped_app="$(osascript_string "$app_name")"
  escaped_command="$(osascript_string "$command")"

/usr/bin/osascript <<APPLESCRIPT >/dev/null
tell application "$escaped_app"
  activate
  do script "$escaped_command"
end tell
APPLESCRIPT
}

run_iterm() {
  local command="$1"
  local escaped_command

  escaped_command="$(osascript_string "$command")"

/usr/bin/osascript <<APPLESCRIPT >/dev/null
tell application "iTerm"
  activate
  create window with default profile command "$escaped_command"
end tell
APPLESCRIPT
}

run_ghostty() {
  local command="$1"

  if command -v ghostty >/dev/null 2>&1; then
    /usr/bin/nohup ghostty -e /bin/zsh -lc "$command" >/dev/null 2>&1 &
  else
    /usr/bin/open -na "Ghostty" --args -e /bin/zsh -lc "$command"
  fi
}

run_alacritty() {
  local command="$1"

  if command -v alacritty >/dev/null 2>&1; then
    /usr/bin/nohup alacritty -e /bin/zsh -lc "$command" >/dev/null 2>&1 &
  else
    /usr/bin/open -na "Alacritty" --args -e /bin/zsh -lc "$command"
  fi
}

open_terminal() {
  local command="$1"

  if [[ -n "${OPEN_IN_NVIM_TERMINAL_CMD:-}" ]]; then
    eval "${OPEN_IN_NVIM_TERMINAL_CMD//\{cmd\}/$(quote "$command")}"
    return
  fi

  case "$TERMINAL" in
    ghostty)
      run_ghostty "$command"
      ;;
    alacritty)
      run_alacritty "$command"
      ;;
    iterm|iterm2)
      run_iterm "$command"
      ;;
    terminal|terminal.app)
      run_terminal_app "Terminal" "$command"
      ;;
    auto)
      if /usr/bin/pgrep -x Ghostty >/dev/null 2>&1 || command -v ghostty >/dev/null 2>&1 || [[ -d "/Applications/Ghostty.app" || -d "$HOME/Applications/Ghostty.app" ]]; then
        run_ghostty "$command"
      elif /usr/bin/pgrep -x Alacritty >/dev/null 2>&1 || command -v alacritty >/dev/null 2>&1 || [[ -d "/Applications/Alacritty.app" || -d "$HOME/Applications/Alacritty.app" ]]; then
        run_alacritty "$command"
      elif [[ -d "/Applications/iTerm.app" || -d "$HOME/Applications/iTerm.app" ]]; then
        run_iterm "$command"
      else
        run_terminal_app "Terminal" "$command"
      fi
      ;;
    *)
      run_terminal_app "$TERMINAL" "$command"
      ;;
  esac
}

open_path() {
  local target="$1"
  local server
  local command

  if [[ ! -e "$target" ]]; then
    print -ru2 -- "路径不存在：$target"
    return 1
  fi

  if [[ -f "$target" ]]; then
    if server="$(first_nvim_server)"; then
      remote_open_files "$server" "$target"
      return
    fi
  fi

  command="$(terminal_command_for_target "$target")"
  open_terminal "$command"
}

if [[ "$#" -eq 0 ]]; then
  print -ru2 -- "没有收到路径。请从 Finder 右键菜单或“打开方式”调用。"
  exit 1
fi

for path in "$@"; do
  open_path "$path"
done
