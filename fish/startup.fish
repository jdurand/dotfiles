echo "New Fish session... Starting Tmux now..."
tmux attach-session -t main || tmux new-session -s main
