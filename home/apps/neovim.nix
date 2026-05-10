{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;

    extraPackages = with pkgs; [
      ripgrep
      fd
      lazygit
      gcc
      gnumake
      unzip
      nodejs
      python3
      curl
      wget
    ];

    extraWrapperArgs = [
      "--suffix" "PATH" ":" "${pkgs.gcc}/bin"
    ];

    initLua = /* lua */ ''
      -- Bootstrap lazy.nvim
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
          }, true, {})
          vim.fn.getchar()
          os.exit(1)
        end
      end
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        },
        defaults = {
          lazy = true,
          version = false,
        },
        install = { colorscheme = { "tokyonight", "habamax" } },
        checker = {
          enabled = true,
          notify = false,
        },
        change_detection = {
          notify = false,
        },
      })
    '';

    withRuby = false;
    withPython3 = false;
    defaultEditor = true;
    viAlias = true;
    vimAlias = false;
  };
}
