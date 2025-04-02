return {
  'elentok/open-link.nvim',
  init = function()
    local expanders = require('open-link.expanders')
    require('open-link').setup({
      expanders = {
        -- expands '{user}/{repo}' to the github repo URL
        expanders.github,

        -- expands 'LIB-8272' and 'JIM-1234' to the specified Jira URL
        expanders.jira('https://libroreserve.atlassian.net/browse/', { 'LIB', 'JIM' }),
      },
    })
  end,
  cmd = { 'OpenLink', 'PasteImage' },
  keys = {
    -- { 'gb', '<cmd>OpenLink<cr>', desc = 'Open the link in web browser' },
    { '<leader>pi', '<cmd>PasteImage<cr>', desc = 'Paste image from clipboard' }
  }
}
