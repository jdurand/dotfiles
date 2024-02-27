local is_git_directory = function()
  local result = vim.fn.system("git rev-parse --is-inside-work-tree")
  if vim.v.shell_error == 0 and result:find("true") then
    return true
  else
    return false
  end
end

local assert_git_repo = function(callback, context)
  local cmd = {
    "sort",
    "-u",
    "<(git diff --name-only --cached)",
    "<(git diff --name-only)",
    "<(git diff --name-only --diff-filter=U)",
  }

  if not is_git_directory() then
    vim.notify(
      "Current project is not a git directory",
      vim.log.levels.WARN,
      { title = "Telescope Git " .. (context or 'Files'), git_command = cmd }
    )
  else
    callback()
  end
end

return {
  is_git_directory = is_git_directory,
  assert_git_repo = assert_git_repo
}
