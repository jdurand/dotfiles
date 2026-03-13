-- Check whether the current session is accessed via SSH.
-- Inside tmux, queries the session environment (updated on client attach)
-- rather than the process env, so it reflects the latest client.
return function()
  if vim.env.TMUX then
    local result = vim.fn.system('tmux show-environment SSH_CONNECTION 2>/dev/null')
    return vim.v.shell_error == 0 and not result:match('^%-')
  end
  return vim.env.SSH_CLIENT ~= nil
    or vim.env.SSH_TTY ~= nil
    or vim.env.SSH_CONNECTION ~= nil
end
