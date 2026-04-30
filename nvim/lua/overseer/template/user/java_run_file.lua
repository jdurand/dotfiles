return {
  name = 'Java: run current file',
  builder = function()
    local file = vim.fn.expand('%:p')
    vim.schedule(function() require('overseer').open({ enter = false }) end)
    return {
      cmd = { 'java' },
      args = { file },
      components = { 'default' },
    }
  end,
  desc = 'Run the current Java file via single-file source-code execution (Java 11+)',
  condition = {
    filetype = { 'java' },
  },
}
