return {
  {
    'rebelot/kanagawa.nvim',
    priority = 1000, -- 确保最先加载
    config = function()
      require('kanagawa').setup {
        compile = true, -- 开启编译优化，启动更快
        commentStyle = { italic = true },
        transparent = true, -- 如果你的 Hyprland 终端是透明的，这里设为 true
        theme = 'wave', -- 可选: "wave" (默认), "dragon" (更黑), "lotus" (亮色)
        colors = {
          theme = {
            all = {
              ui = {
                bg_gutter = 'none',
              },
            },
          },
        },
      }
      -- 激活主题
      vim.cmd.colorscheme 'kanagawa'
    end,
  },
}
