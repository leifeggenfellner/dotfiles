# Neovim flavour (D-052): the LOTM module loads through the theme-blind
# loader, applies its scheme and shows the start screen; an editor opened
# on a file gets no start screen; an unknown active theme changes nothing;
# Cyberpunk builds no module.
{ pkgs }:
let
  inherit (pkgs) lib;
  mk = name: import ./_neovim-lib.nix { inherit pkgs lib; } {
    themeName = name;
    theme = import (../themes + "/${name}/_theme.nix");
  };
in
assert mk "cyberpunk" == null;
pkgs.runCommand "rice-neovim"
{
  nativeBuildInputs = [ pkgs.neovim pkgs.gnugrep ];
}
  ''
    export HOME="$TMPDIR" XDG_CONFIG_HOME="$TMPDIR/config"
    mkdir -p "$XDG_CONFIG_HOME/nvim/lua/rice/themes" bin
    cp ${../nvim/rice/init.lua} "$XDG_CONFIG_HOME/nvim/lua/rice/init.lua"
    cp ${../nvim/rice/start.lua} "$XDG_CONFIG_HOME/nvim/lua/rice/start.lua"
    cp ${mk "lotm"} "$XDG_CONFIG_HOME/nvim/lua/rice/themes/lotm.lua"
    echo 'pcall(function() require("rice").setup() end)' > "$XDG_CONFIG_HOME/nvim/init.lua"
    printf '#!/bin/sh\necho "$RICE_ACTIVE"\n' > bin/rice-query
    chmod +x bin/rice-query
    export PATH="$PWD/bin:$PATH"

    probe='lua vim.defer_fn(function()
      local out = { vim.g.colors_name or "none", vim.bo.filetype }
      for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do table.insert(out, l) end
      vim.fn.writefile(out, "out.txt"); vim.cmd("qa!") end, 100)'

    RICE_ACTIVE=lotm nvim --headless -c "$probe"
    grep -qx rice-lotm out.txt
    grep -qx rice-start out.txt
    grep -q 'Above the Gray Fog' out.txt

    echo hello > file.txt
    RICE_ACTIVE=lotm nvim --headless -c "$probe" file.txt
    grep -qx rice-lotm out.txt
    ! grep -q 'Above the Gray Fog' out.txt

    RICE_ACTIVE=cyberpunk nvim --headless -c "$probe"
    grep -qx none out.txt
    ! grep -q rice-start out.txt
    touch $out
  ''
