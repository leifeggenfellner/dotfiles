# rice_ornaments: a Hyprland plugin that draws a theme's corner pieces on
# every window frame in the compositor's own render pass, so they follow
# window animations, drags and resizes frame by frame (D-075, spike).
# Built against the flake's Hyprland; the plugin refuses to load into
# any other build.
{ lib
, hyprland
, hyprlandPlugins
, meson
, ninja
, cairo
}:
hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "rice_ornaments";
  version = "0.1";
  src = ./src;
  inherit hyprland;

  # Hyprland's own nativeBuildInputs carry CMake, which would take over.
  nativeBuildInputs = [ meson ninja ];
  buildInputs = [ cairo ];

  meta = {
    description = "Theme corner ornaments on Hyprland window frames";
    platforms = lib.platforms.linux;
  };
}
