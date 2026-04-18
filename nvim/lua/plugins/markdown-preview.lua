return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  ft = { 'markdown' },
  build = function()
    vim.fn['mkdp#util#install']()
  end,
  init = function()
    if vim.fn.has('macunix') == 1 then
      -- Use custom function for macOS open flags
      vim.g.mkdp_browserfunc = 'g:OpenMarkdownPreview'
    else
      vim.g.mkdp_browser = 'min-browser'
    end
    -- Set a custom page title prefix for Aerospace detection
    -- vim.g.mkdp_page_title = '[MDPREV] ${name}'
  end,
  config = function()
    if vim.fn.has('macunix') == 1 then
      vim.cmd([[
        function! g:OpenMarkdownPreview(url)
          call jobstart(['open', '-gna', 'Min', a:url])
        endfunction
      ]])
    end
  end
}
