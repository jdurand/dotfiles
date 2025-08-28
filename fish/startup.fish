if not test "$TERM_PROGRAM" = "WarpTerminal"; and not test "$TERM_PROGRAM" = "vscode"
  echo "New Fish session... Starting Tmux now..."
  tmux attach-session -t main || tmux new-session -s main
end
