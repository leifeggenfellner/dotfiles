# Shared rice theme package discovery. Bundled themes live under
# modules/rice/themes; external theme packages are supplied by
# `rice.themes.<name>.package` and use the same _theme.nix contract.
{ lib }:
let
  bundledThemesDir = ../themes;

  validBundledTheme = name: type:
    type == "directory" && builtins.pathExists (bundledThemesDir + "/${name}/_theme.nix");

  bundledThemePackages = lib.mapAttrs
    (name: _: bundledThemesDir + "/${name}")
    (lib.filterAttrs validBundledTheme (builtins.readDir bundledThemesDir));

  configuredThemePackages = cfg:
    lib.mapAttrs
      (_: theme: theme.package)
      (lib.filterAttrs (_: theme: (theme.package or null) != null) (cfg.themes or { }));
in
{
  inherit bundledThemePackages;

  themePackages = cfg:
    bundledThemePackages // configuredThemePackages cfg;

  themeNames = cfg:
    lib.attrNames (bundledThemePackages // configuredThemePackages cfg);

  themePackage = cfg: themeName:
    let packages = bundledThemePackages // configuredThemePackages cfg; in
      packages.${themeName} or (throw "rice: theme '${themeName}' is not packaged");
}
