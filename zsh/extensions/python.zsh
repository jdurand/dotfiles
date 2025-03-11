# export function to load pyenv

load_pyenv() {
  if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"

    # Add python binaries to $PATH
    export PATH="$PATH:$(pyenv root)/shims"
  fi
}
