#
# Cleanup
# -----------------------------------------------------------------------------

# unset GEM_HOME set by tmuxinator
# see: https://github.com/Homebrew/homebrew-core/issues/59484
#      https://discourse.brew.sh/t/why-does-tmuxinator-sets-gem-home/7296
unset -v GEM_HOME
