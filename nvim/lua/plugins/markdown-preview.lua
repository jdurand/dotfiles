return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  ft = { 'markdown' },
  build = function()
    vim.fn['mkdp#util#install']()
  end,
  init = function()
    -- Open in Chrome app mode (no address bar)
    vim.g.mkdp_browserfunc = 'g:OpenMarkdownPreview'
    -- Set a custom page title prefix for Aerospace detection
    -- vim.g.mkdp_page_title = '[MDPREV] ${name}'
  end,
  config = function()
    vim.cmd([[
      function! g:OpenMarkdownPreview(url)
        " Chrome in app mode (no address bar)
        " call jobstart(['open', '-gna', 'Google Chrome', '--args', '--app=' . a:url])

        " Min browser (minimal by design, no special flags needed)
        call jobstart(['open', '-gna', 'Min', a:url])
      endfunction
    ]])
  end
}
