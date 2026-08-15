return {
  { "RRethy/base16-nvim", lazy = false, priority = 1000 },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        require("base16-colorscheme").setup({
          base00 = "{{ background }}",
          base01 = "{{ surface }}",
          base02 = "{{ selection_background }}",
          base03 = "{{ color8 }}",
          base04 = "{{ muted }}",
          base05 = "{{ foreground }}",
          base06 = "{{ cursor }}",
          base07 = "{{ color15 }}",
          base08 = "{{ color1 }}",
          base09 = "{{ warning }}",
          base0A = "{{ color3 }}",
          base0B = "{{ color2 }}",
          base0C = "{{ color6 }}",
          base0D = "{{ color4 }}",
          base0E = "{{ color5 }}",
          base0F = "{{ accent }}",
        })
      end,
    },
  },
}
