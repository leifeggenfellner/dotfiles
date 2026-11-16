# Cursor theme builder for `integration.cursor` (D-048). A theme names
# its cursor and supplies one square SVG per shape with a fractional
# hotspot; this builds one icon-theme directory carrying both a
# hyprcursor theme (scalable SVG, read by Hyprland) and an XCursor
# fallback (PNG sizes, read by XWayland and clients that draw their own
# cursor). The builder is theme-blind: shape names and their aliases
# are the CSS / cursor-shape-v1 vocabulary, never theme data.
{ pkgs, lib }:
let
  # Shape → the legacy X11 and freedesktop names that resolve to it.
  aliases = {
    default = [ "left_ptr" "arrow" "top_left_arrow" "left-arrow" ];
    pointer = [ "hand" "hand1" "hand2" "pointing_hand" "grab" "openhand" ];
    text = [ "xterm" "ibeam" "vertical-text" ];
    wait = [ "watch" "clock" ];
    progress = [ "left_ptr_watch" "half-busy" ];
    ns-resize = [ "sb_v_double_arrow" "v_double_arrow" "size_ver" "n-resize" "s-resize" "top_side" "bottom_side" "row-resize" ];
    ew-resize = [ "sb_h_double_arrow" "h_double_arrow" "size_hor" "e-resize" "w-resize" "left_side" "right_side" "col-resize" ];
    nwse-resize = [ "size_fdiag" "bd_double_arrow" "nw-resize" "se-resize" "top_left_corner" "bottom_right_corner" ];
    nesw-resize = [ "size_bdiag" "fd_double_arrow" "ne-resize" "sw-resize" "top_right_corner" "bottom_left_corner" ];
    move = [ "fleur" "all-scroll" "size_all" "grabbing" "closedhand" "dnd-move" ];
    crosshair = [ "cross" "tcross" "cross_reverse" "diamond_cross" ];
    not-allowed = [ "crossed_circle" "circle" "no-drop" "dnd-no-drop" "forbidden" ];
  };

  # The six shapes every cursor theme must draw (#80).
  required = [ "default" "pointer" "text" "wait" "ns-resize" "ew-resize" "move" ];

  # XCursor has no scalable images; these cover 1×–2× of the common sizes.
  xcursorSizes = [ 24 32 48 64 ];

  build = { themeName, cursor }:
    let
      shapes = lib.mapAttrsToList (shape: s: s // { inherit shape; }) cursor.shapes;
      hot = s: i: size: toString (builtins.floor ((builtins.elemAt s.hotspot i) * size + 0.5));
      meta = s: pkgs.writeText "${s.shape}-meta.hl" ''
        resize_algorithm = none
        hotspot_x = ${toString (builtins.elemAt s.hotspot 0)}
        hotspot_y = ${toString (builtins.elemAt s.hotspot 1)}
        ${lib.concatMapStrings (a: "define_override = ${a}\n") aliases.${s.shape}}
        define_size = 0, ${s.shape}.svg
      '';
      shapeScript = s: ''
        mkdir -p src/hyprcursors/${s.shape}
        cp ${s.svg} src/hyprcursors/${s.shape}/${s.shape}.svg
        cp ${meta s} src/hyprcursors/${s.shape}/meta.hl

        : > ${s.shape}.cfg
        ${lib.concatMapStrings (size: ''
          resvg --width ${toString size} --height ${toString size} ${s.svg} png/${s.shape}-${toString size}.png
          echo "${toString size} ${hot s 0 size} ${hot s 1 size} png/${s.shape}-${toString size}.png" >> ${s.shape}.cfg
        '') xcursorSizes}
        xcursorgen ${s.shape}.cfg "$theme/cursors/${s.shape}"
        ${lib.concatMapStrings (a: "ln -s ${s.shape} \"$theme/cursors/${a}\"\n") aliases.${s.shape}}
      '';
    in
    pkgs.runCommand "rice-${themeName}-cursor-${cursor.name}"
      { nativeBuildInputs = [ pkgs.resvg pkgs.xcursorgen pkgs.hyprcursor ]; }
      ''
        theme="$out/share/icons/${cursor.name}"
        mkdir -p "$theme/cursors" png src
        cat > src/manifest.hl <<'EOF'
        name = ${cursor.name}
        description = rice ${themeName} cursor
        version = 1
        cursors_directory = hyprcursors
        EOF
        ${lib.concatMapStrings shapeScript shapes}
        hyprcursor-util --create src --output .
        cp -r theme_${cursor.name}/. "$theme/"
        printf '[Icon Theme]\nName=%s\nComment=rice %s cursor\n' ${lib.escapeShellArg cursor.name} ${themeName} > "$theme/index.theme"
      '';
in
{
  inherit aliases required build;

  # Cursor package for a theme, or null when it names an external cursor
  # (no `shapes`) or has none.
  package = { themeName, theme }:
    let cursor = theme.integration.cursor or null; in
    if cursor == null || !(cursor ? shapes) then null
    else build { inherit themeName cursor; };
}
