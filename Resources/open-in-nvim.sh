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
LANGUAGE_SETTING="${OPEN_IN_NVIM_LANGUAGE:-auto}"
TERMINAL="${OPEN_IN_NVIM_TERMINAL:-auto}"
REMOTE_OPEN="${OPEN_IN_NVIM_REMOTE_OPEN:-tab}"
NVIM_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
REMOTE_STATE_FILE="${OPEN_IN_NVIM_STATE_FILE:-$NVIM_STATE_HOME/nvim/open-in-nvim/server}"
TMUX_MODE="${OPEN_IN_NVIM_TMUX:-never}"
TMUX_SESSION="${OPEN_IN_NVIM_TMUX_SESSION:-}"

active_language() {
  local language="$LANGUAGE_SETTING"
  local preferred=""

  case "$language" in
    zh-Hans|en)
      print -r -- "$language"
      return
      ;;
  esac

  preferred="$(/usr/bin/defaults read -g AppleLanguages 2>/dev/null | awk -F'"' '/"/ {print $2; exit}')"
  if [[ "$preferred" == zh* ]]; then
    print -r -- "zh-Hans"
  else
    print -r -- "en"
  fi
}

message() {
  local key="$1"

  case "$(active_language):$key" in
    zh-Hans:no_nvim)
      print -r -- "找不到 nvim。请先安装 Neovim，或在设置中配置 nvim 路径。"
      ;;
    zh-Hans:tmux_missing)
      print -r -- "已设置始终使用 tmux，但找不到 tmux。"
      ;;
    zh-Hans:path_missing)
      print -r -- "路径不存在：$2"
      ;;
    zh-Hans:no_path)
      print -r -- "没有收到路径。请从 Finder 右键菜单或“打开方式”调用。"
      ;;
    *:no_nvim)
      print -r -- "Could not find nvim. Install Neovim or configure the nvim path in settings."
      ;;
    *:tmux_missing)
      print -r -- "tmux is set to Always, but tmux could not be found."
      ;;
    *:path_missing)
      print -r -- "Path does not exist: $2"
      ;;
    *:no_path)
      print -r -- "No paths received. Use this app from Finder or Open With."
      ;;
  esac
}

if [[ -z "$NVIM_BIN" ]]; then
  print -ru2 -- "$(message no_nvim)"
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
  local state_server=""

  if [[ -r "$REMOTE_STATE_FILE" ]]; then
    state_server="$(awk -F= '$1 == "server" {print substr($0, index($0, "=") + 1); exit}' "$REMOTE_STATE_FILE")"
    if [[ -n "$state_server" ]]; then
      print -r -- "$state_server"
    fi
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

should_use_tmux() {
  case "$TMUX_MODE" in
    never|off|false|0|"")
      return 1
      ;;
    always|on|true|1)
      if command -v tmux >/dev/null 2>&1; then
        return 0
      fi
      print -ru2 -- "$(message tmux_missing)"
      return 2
      ;;
    auto)
      command -v tmux >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

tmux_command_for_target() {
  local cwd="$1"
  local command="$2"
  local session="$TMUX_SESSION"
  local quoted_session
  local quoted_cwd
  local quoted_command

  quoted_cwd="$(quote "$cwd")"
  quoted_command="$(quote "$command")"

  if [[ -z "$session" ]]; then
    print -r -- "exec tmux new-session -c $quoted_cwd $quoted_command"
    return
  fi

  quoted_session="$(quote "$session")"

  print -r -- "if tmux has-session -t $quoted_session 2>/dev/null; then tmux new-window -t $quoted_session -c $quoted_cwd $quoted_command; exec tmux attach-session -t $quoted_session; else exec tmux new-session -s $quoted_session -c $quoted_cwd $quoted_command; fi"
}

terminal_command_for_target() {
  local target="$1"
  local cwd
  local server
  local cmd
  local tmux_status

  if [[ -d "$target" ]]; then
    cwd="$target"
    cmd="cd $(quote "$cwd"); exec $(quote "$NVIM_BIN") --listen $(quote "$(new_server_path)") ."
  else
    cwd="${target:h}"
    server="$(new_server_path)"
    cmd="cd $(quote "$cwd"); exec $(quote "$NVIM_BIN") --listen $(quote "$server") $(quote "$target")"
  fi

  if should_use_tmux; then
    tmux_command_for_target "$cwd" "$cmd"
    return
  else
    tmux_status="$?"
    if [[ "$tmux_status" -eq 2 ]]; then
      return 1
    fi
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
    print -ru2 -- "$(message path_missing "$target")"
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
  print -ru2 -- "$(message no_path)"
  exit 1
fi

for path in "$@"; do
  open_path "$path"
done
