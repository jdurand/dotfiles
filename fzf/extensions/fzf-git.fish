# Git fzf functions
# ------------------------------------------------------------------------------

# overrides patrickF1/fzf.fish _fzf_wrapper
function _fzf_wrapper --description 'prepares some environment variables before executing fzf.'
  set -f --export SHELL (command --search fish)

  if not set -q FZF_DEFAULT_OPTS; and not set -q FZF_DEFAULT_OPTS_FILE
    set --export FZF_DEFAULT_OPTS '--cycle --layout=reverse --border --height=90% --preview-window=wrap --marker="󰁔"'
  end

  # Read each line of output as one argument, preserving quoted strings
  set args
  _normalize_fzf_prompt $argv | while read -l line
    set args $args $line
  end

  fzf $args
end

function _normalize_fzf_prompt --description 'normalizes the --prompt fzf argument'
  set result

  for arg in $argv
    if string match -q -- '--prompt=*' $arg
      set key_val (string split '=' -- $arg)
      set lower_prompt (string lower -- $key_val[2])
      set trimmed_prompt (string trim -- $lower_prompt)
      set result $result "--prompt=$trimmed_prompt"
    else
      set result $result $arg
    end
  end

  # Output each arg on its own line
  for item in $result
    printf '%s\n' $item
  end
end

function fzf_add_to_commandline -d 'add stdin to the command line, for fzf functions'
  read -l result
  commandline -t ""
  commandline -it -- (string escape $result)
  commandline -f repaint
end

function fzf_add_multi_files_to_commandline -d 'add stdin to the command line without escaping, for fzf functions'
  read -l result
  set files (string split '*' $result)
  commandline -t ""
  for file in $files
    commandline -it -- (string escape $file)" "
  end
  commandline -f repaint
end

function fzf_add_multi_hashes_to_commandline -d 'add multiple hashes in the selected order'
  read -d \n -z -a result
  set -l hashes
  for hash in $result
    if test -n (string trim $hash)
      set -a hashes $hash
    end
  end
  commandline -t ""
  commandline -it -- (string join " " $hashes)
  commandline -f repaint
end

function fzf-drop-down
  _fzf_wrapper --height 75% \
      --min-height 20 \
      --border \
      --bind ctrl-p:toggle-preview \
      --bind ctrl-a:select-all \
      --bind ctrl-u:preview-page-up \
      --bind ctrl-d:preview-page-down \
      # --header "Press CTRL+P to toggle preview" \
      # --prompt '...>' \
      $argv
end

function __setup_git_fzf_commands
  function __git_fzf_is_in_git_repo
    command -s -q git
      and git rev-parse HEAD >/dev/null 2>&1
  end

  function __git_fzf_git_remote
    __git_fzf_is_in_git_repo; or return
    git remote -v | awk '{print $1 ":" $2}' | uniq | \
      fzf-drop-down --ansi --tac --preview-window right:70% \
      --prompt ' remote>' \
      --preview 'git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" --remotes=$(echo {1} | cut -d ":" -f1) | head -200' | \
      cut -d ':' -f1 | \
      fzf_add_to_commandline
  end

  function __git_fzf_git_status
    __git_fzf_is_in_git_repo; or return
    git -c color.status=always status --short | \
      fzf-drop-down -m --ansi \
      --prompt ' diff>' \
      --preview 'git diff --color=always HEAD -- {-1} | head -500' | \
      cut -c4- | \
      sed 's/.* -> //' | \
      tr '\n' '*' | \
      sed 's/\*$//' | \
      fzf_add_multi_files_to_commandline
  end

  function __git_fzf_git_branch
    __git_fzf_is_in_git_repo; or return
    git branch -a --color=always | grep -v '/HEAD\s' | \
      fzf-drop-down -m --ansi --preview-window right:70% \
      --prompt ' branch>' \
      --preview 'git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s %C(magenta)[%an]%Creset" (echo {} | sed s/^..// | cut -d" " -f1) | head -'$LINES | \
      sed 's/^..//' | cut -d' ' -f1 | \
      sed 's#^remotes/##' | \
      fzf_add_to_commandline
  end

  function __git_fzf_git_tag
    __git_fzf_is_in_git_repo; or return
    git tag --sort -version:refname | \
      fzf-drop-down --ansi --preview-window right:70% \
      --prompt ' tag>' \
      --preview 'git show --color=always {} | head -'$LINES | \
      fzf_add_to_commandline
  end

  function __git_fzf_git_log
    __git_fzf_is_in_git_repo; or return
    git log --color=always --graph --date=short \
      --format="%C(auto)%cd %h%d %s %C(magenta)[%an]%Creset" | \
      fzf-drop-down -m --ansi --reverse \
      --prompt ' log>' \
      --preview 'git show --color=always (echo {} | grep -o "[a-f0-9]\{7,\}") | head -'$LINES | \
      awk '{print $3}' \
      | fzf_add_multi_hashes_to_commandline
  end

  # sets up key bindings for insert mode and default mode
  function __git_fzf_key_bindings -d 'set custom key bindings for git+fzf'
    for mode in default insert
      bind --mode $mode \cg\cf __git_fzf_git_status
      bind --mode $mode \cg\cb __git_fzf_git_branch
      bind --mode $mode \cg\ct __git_fzf_git_tag
      bind --mode $mode \cg\ch __git_fzf_git_log
      bind --mode $mode \cg\cr __git_fzf_git_remote
    end
  end

  __git_fzf_key_bindings
end

function setup_git_fzf_key_bindings
  __setup_git_fzf_commands
end
