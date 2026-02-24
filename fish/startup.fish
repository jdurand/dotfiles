# Skip in unsupported terminals
test "$TERM_PROGRAM" = "WarpTerminal"; or test "$TERM_PROGRAM" = "vscode"; and return

# Skip if already inside tmux
set -q TMUX; and return

# Ensure main tmux session exists
if not tmux has-session -t main 2>/dev/null
  if type -q tmux-session-manager
    tmux new-session -d -s main
  else
    echo "New Fish session... Starting Tmux now..."
    tmux new-session -s main
  end
  return
end

# With tmux-session-manager, don't auto-attach
type -q tmux-session-manager; and return

# Attach to main if unattached
set -l attached (tmux display-message -p -t main '#{session_attached}' 2>/dev/null)
if test "$attached" = "0"
  echo "Attaching to Tmux main session..."
  tmux attach-session -t main
end
