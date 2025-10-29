-- chchchanges.nvim - Git hunk analyzer for quickfix list
-- Entry point that defines commands without eagerly loading the module

if vim.g.loaded_chchchanges then
  return
end
vim.g.loaded_chchchanges = 1

-- Create user command with lazy loading
-- Usage: :ChChanges - populate and open quickfix
--        :ChChanges! - populate but don't open quickfix
vim.api.nvim_create_user_command('ChChanges', function(cmd_opts)
  require('chchchanges').populate_quickfix({ open = not cmd_opts.bang })
end, {
  bang = true,
  desc = 'Analyze git changes and populate quickfix list (! to not open)',
})
