return {
  -- 1.Neo-tree
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    -- 【关键】让 Lazy 在检测到我们要打开目录时，提前加载插件
    init = function()
      if vim.fn.argc() == 1 then
        local stat = vim.loop.fs_stat(vim.fn.argv(0))
        if stat and stat.type == 'directory' then
          require 'neo-tree'
        end
      end
    end,

    keys = {
      { '<leader>e', '<cmd>Neotree toggle<cr>', desc = 'Explorer (Toggle)' },
      { '<leader>o', '<cmd>Neotree focus<cr>', desc = 'Explorer (Focus)' },
    },

    opts = {
      filesystem = {
        -- 【核心】hijack_netrw_behavior
        -- "open_default": 用 Neo-tree 替换 netrw，并在启动时像普通 buffer 一样打开
        -- 这就是你要的 LazyVim 同款体验
        hijack_netrw_behavior = 'open_default',

        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true, -- 自动检测文件变动
      },
      window = {
        position = 'left',
        width = 30,
      },
    },
  },
  -- ==========================================
  -- 2. 优雅关闭 Buffer (Mini.bufremove)
  -- ==========================================
  {
    'echasnovski/mini.bufremove',
    version = '*',
    config = function()
      require('mini.bufremove').setup()
    end,
    keys = {
      -- <leader>w: 关闭当前文件 (Tab)
      -- 逻辑：如果这是最后一个文件，行为会变成关闭窗口，触发 Neo-tree 退出逻辑
      {
        '<leader>w',
        function()
          local bd = require('mini.bufremove').delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(('Save changes to %q?'):format(vim.fn.bufname()), '&Yes\n&No\n&Cancel')
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = 'Delete Buffer',
      },
      -- 【新增】<leader>q: 强制关闭当前窗口 (Quit Window)
      -- 如果你觉得 Space+W 留个白板很烦，直接用 Space+Q 关掉窗口
      { '<leader>q', '<cmd>q<cr>', desc = 'Quit Window' },
    },
  },

  -- ==========================================
  -- 3. 顶部标签页 (Bufferline)
  -- ==========================================
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
      {
        '<leader>x',
        function()
          require('mini.bufremove').delete(0)
        end,
        desc = 'Delete Buffer',
      },
    },
    opts = {
      options = {
        mode = 'buffers',
        diagnostics = 'nvim_lsp',
        separator_style = 'slant',
        always_show_bufferline = false, -- 只有一个 tab 时不显示顶栏，看着更清爽
        offsets = {
          {
            filetype = 'neo-tree',
            text = 'File Explorer',
            highlight = 'Directory',
            text_align = 'left',
          },
        },
      },
    },
  },

  -- ==========================================
  -- 4. 浮动终端 (Toggleterm)
  -- ==========================================
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      size = 20,
      open_mapping = [[<c-\>]],
      direction = 'float',
      float_opts = {
        border = 'curved',
      },
    },
  },

  -- ==========================================
  -- 5. 炫酷命令行 (Noice)
  -- ==========================================
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    },
  },

  -- ==========================================
  -- 6. 图标库
  -- ==========================================
  { 'nvim-tree/nvim-web-devicons', lazy = true },
}
