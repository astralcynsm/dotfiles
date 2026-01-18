return {
  {
    'goolord/alpha-nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VimEnter', -- 启动时加载
    config = function()
      local dashboard = require 'alpha.themes.dashboard'

      -- 1. 自定义你的大 Logo (这里我放了一个 ARCH 的例子，你可以替换成你的 figlet 输出)
      dashboard.section.header.val = {
        [[Y8b Y8P                                     ]],
        [[ Y8b Y  Y8b Y888P 88888e   dP"Y 888 888 8e  ]],
        [[  Y8b    Y8b Y8P  888 88b C88b  888 888 88b ]],
        [[ e Y8b    Y8b Y   888 888  Y88D 888 888 888 ]],
        [[d8b Y8b    888    888 888 d,dP  888 888 888 ]],
        [[           888                              ]],
        [[           888                              ]],
      }

      -- 设置 Logo 的颜色 (Cyan 是青色，适合极客风)
      dashboard.section.header.opts.hl = 'Number'

      -- 2. 定义按钮 (按你的需求定制)
      dashboard.section.buttons.val = {
        -- 参数：快捷键，显示文字，执行的命令
        dashboard.button('r', '  Recent Files', ':Telescope oldfiles<CR>'),
        dashboard.button('n', '  New File', ':ene <BAR> startinsert <CR>'),
        dashboard.button('f', '  Open File', ':Telescope find_files<CR>'),

        -- "Open project folder" 通常对应查找当前目录文件，或者打开侧边栏
        -- 这里我把它映射为 "Find Text" (Grep) 或者打开 NeoTree，看你喜好
        dashboard.button('p', '  Open Project (Explorer)', ':Neotree toggle<CR>'),

        -- 加一个退出，方便手快
        dashboard.button('q', '  Quit', ':qa<CR>'),
      }

      -- 3. 底部统计信息 (类似 leetcode.nvim 下面的 session info)
      local function footer()
        -- 获取插件数量
        local plugins = #vim.tbl_keys(require('lazy').plugins())
        -- 获取启动时间
        local datetime = os.date ' %d-%m-%Y   %H:%M:%S'
        local version = vim.version()
        local nvim_version_info = '  v' .. version.major .. '.' .. version.minor .. '.' .. version.patch

        return datetime .. '  ⚡Neovim' .. nvim_version_info .. '   ' .. plugins .. ' plugins'
      end

      dashboard.section.footer.val = footer()
      dashboard.section.footer.opts.hl = 'Type'

      -- 4. 布局微调 (设置边距，让它看起来在中间)
      -- header 也就是 Logo 上面的留白
      dashboard.config.layout = {
        { type = 'padding', val = 2 },
        dashboard.section.header,
        { type = 'padding', val = 2 },
        dashboard.section.buttons,
        { type = 'padding', val = 1 },
        dashboard.section.footer,
      }

      require('alpha').setup(dashboard.config)
    end,
  },
}
