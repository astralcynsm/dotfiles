return {
  -- ==========================================
  -- 1. 自动补全括号 (Autopairs)
  -- ==========================================
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    dependencies = { 'hrsh7th/nvim-cmp' },
    config = function()
      local npairs = require 'nvim-autopairs'
      npairs.setup {}
      -- 如果你希望选中函数补全时自动加上括号 ()
      local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
      local cmp = require 'cmp'
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },
}
