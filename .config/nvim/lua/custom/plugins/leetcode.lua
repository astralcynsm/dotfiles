return {
  {
    'kawre/leetcode.nvim',

    -- 1. 改回懒加载，不拖慢 Neovim 启动速度
    lazy = true,

    -- 2. 明确告诉 Lazy：当输入这些命令时，才加载插件
    cmd = { 'Leet', 'LeetCodeMenu', 'LeetList', 'LeetRandom' },

    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    init = function()
      vim.env.HTTP_PROXY = 'http://127.0.0.1:7897'
      vim.env.HTTPS_PROXY = 'http://127.0.0.1:7897'
    end,
    opts = {
      arg = 'leetcode.nvim',
      lang = 'python3',
      domain = 'com',
      image_support = false,

      -- 3. 关掉不必要的自动检查，提升一点速度
      cache = {
        update_interval = 60 * 60 * 24 * 7, -- 7天更新一次缓存
      },
      console = {
        open_on_runcode = true, -- 运行代码时才开控制台
      },
    },
  },
}
