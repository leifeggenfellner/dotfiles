# Terminal tool themes for `integration.tools` (D-051), generated at
# rebuild from the configured theme's colour tokens and legacy palette.
# The role mapping is theme-blind: every opted-in theme gets the same
# structure, coloured by its own tokens. Themes that do not opt in leave
# the host's tool configs untouched.
{ pkgs, lib }:
theme:
let
  t = theme.tokens.colors;
  p = lib.mapAttrs (_: v: "#${v}") (theme.palette.legacy or { });
  # Legacy keys a theme may lack fall back to the nearest token.
  pal = key: fallback: p.${key} or fallback;

  bronze = pal "overlay0" t.fg.subtle;
  parchment2 = pal "subtext1" t.fg.muted;
  peach = pal "peach" t.state.warn;
  rose = pal "rosewater" t.fg.primary;
  pink = pal "pink" t.accent.tertiary;
  lavender = pal "lavender" t.accent.secondary;
  teal = pal "teal" t.state.ok;

  btop = pkgs.writeText "rice-btop.theme" (lib.concatStrings (lib.mapAttrsToList
    (k: v: "theme[${k}]=\"${v}\"\n")
    {
      main_bg = "";
      main_fg = t.fg.primary;
      title = t.accent.primary;
      hi_fg = t.accent.primary;
      selected_bg = t.bg.surface1;
      selected_fg = t.fg.primary;
      inactive_fg = t.fg.subtle;
      graph_text = t.fg.muted;
      meter_bg = t.bg.elevated;
      proc_misc = t.accent.secondary;
      cpu_box = bronze;
      mem_box = bronze;
      net_box = bronze;
      proc_box = bronze;
      div_line = t.bg.surface2;
      temp_start = t.state.ok;
      temp_mid = t.state.warn;
      temp_end = t.state.danger;
      cpu_start = t.accent.secondary;
      cpu_mid = t.accent.primary;
      cpu_end = t.state.danger;
      free_start = teal;
      free_mid = t.state.ok;
      free_end = t.state.ok;
      cached_start = t.accent.secondary;
      cached_mid = t.accent.secondary;
      cached_end = lavender;
      available_start = t.state.ok;
      available_mid = teal;
      available_end = t.accent.secondary;
      used_start = t.accent.primary;
      used_mid = peach;
      used_end = t.state.danger;
      download_start = bronze;
      download_mid = t.accent.secondary;
      download_end = t.fg.primary;
      upload_start = bronze;
      upload_mid = t.accent.primary;
      upload_end = t.state.warn;
      process_start = t.accent.secondary;
      process_mid = t.accent.primary;
      process_end = t.state.danger;
    }));

  # TextMate theme for bat: one plist, scopes coloured by role.
  scope = name: scopes: fg: extra: ''
    <dict>
      <key>name</key><string>${name}</string>
      <key>scope</key><string>${scopes}</string>
      <key>settings</key><dict>
        <key>foreground</key><string>${fg}</string>${lib.optionalString (extra != "") "\n        <key>fontStyle</key><string>${extra}</string>"}
      </dict>
    </dict>
  '';
  bat = pkgs.writeText "rice.tmTheme" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key><string>rice</string>
      <key>settings</key>
      <array>
        <dict>
          <key>settings</key><dict>
            <key>background</key><string>${t.bg.base}</string>
            <key>foreground</key><string>${t.fg.primary}</string>
            <key>caret</key><string>${t.accent.primary}</string>
            <key>lineHighlight</key><string>${t.bg.elevated}</string>
            <key>selection</key><string>${t.bg.surface1}</string>
            <key>gutter</key><string>${t.bg.base}</string>
            <key>gutterForeground</key><string>${t.bg.surface2}</string>
          </dict>
        </dict>
    ${lib.concatStrings [
      (scope "Comment" "comment, punctuation.definition.comment" t.fg.subtle "italic")
      (scope "String" "string, punctuation.definition.string" t.state.ok "")
      (scope "Escape" "constant.character.escape, string.regexp" teal "")
      (scope "Number" "constant.numeric, constant.language, constant.other" peach "")
      (scope "Keyword" "keyword, storage.modifier, keyword.control" t.accent.primary "")
      (scope "Storage" "storage.type" t.accent.primary "italic")
      (scope "Operator" "keyword.operator, punctuation" t.fg.muted "")
      (scope "Function" "entity.name.function, support.function, meta.function-call" t.accent.secondary "")
      (scope "Type" "entity.name.type, entity.name.class, support.type, support.class" lavender "")
      (scope "Parameter" "variable.parameter" rose "italic")
      (scope "Variable" "variable, variable.other" t.fg.primary "")
      (scope "Builtin" "variable.language, support.constant" t.state.warn "")
      (scope "Tag" "entity.name.tag" pink "")
      (scope "Attribute" "entity.other.attribute-name" peach "")
      (scope "Key" "meta.mapping.key, support.type.property-name" parchment2 "")
      (scope "Heading" "markup.heading, entity.name.section" t.accent.primary "bold")
      (scope "Emphasis" "markup.italic" rose "italic")
      (scope "Strong" "markup.bold" rose "bold")
      (scope "Link" "markup.underline.link" t.accent.secondary "underline")
      (scope "Inserted" "markup.inserted" t.state.ok "")
      (scope "Deleted" "markup.deleted" t.state.danger "")
      (scope "Changed" "markup.changed" t.state.warn "")
      (scope "Invalid" "invalid" t.state.danger "")
    ]}  </array>
    </dict>
    </plist>
  '';

  yazi = {
    manager = {
      cwd = { fg = t.accent.primary; bold = true; };
      hovered = { bg = t.bg.surface1; };
      preview_hovered = { underline = true; };
      find_keyword = { fg = t.state.warn; bold = true; };
      find_position = { fg = t.accent.secondary; italic = true; };
      marker_selected = { fg = t.state.ok; bg = t.state.ok; };
      marker_copied = { fg = t.state.warn; bg = t.state.warn; };
      marker_cut = { fg = t.state.danger; bg = t.state.danger; };
      tab_active = { fg = t.bg.sunken; bg = t.accent.primary; bold = true; };
      tab_inactive = { fg = t.fg.muted; bg = t.bg.elevated; };
      border_symbol = "│";
      border_style = { fg = bronze; };
    };
    status = {
      separator_open = "";
      separator_close = "";
      separator_style = { fg = t.bg.elevated; bg = t.bg.elevated; };
      mode_normal = { fg = t.bg.sunken; bg = t.accent.primary; bold = true; };
      mode_select = { fg = t.bg.sunken; bg = t.accent.secondary; bold = true; };
      mode_unset = { fg = t.fg.primary; bg = t.accent.tertiary; bold = true; };
      progress_label = { fg = t.fg.primary; bold = true; };
      progress_normal = { fg = t.accent.primary; bg = t.bg.elevated; };
      progress_error = { fg = t.state.danger; bg = t.bg.elevated; };
      permissions_t = { fg = t.accent.secondary; };
      permissions_r = { fg = t.accent.primary; };
      permissions_w = { fg = t.state.danger; };
      permissions_x = { fg = t.state.ok; };
      permissions_s = { fg = t.fg.subtle; };
    };
    input = {
      border = { fg = t.accent.primary; };
      title = { };
      value = { };
      selected = { reversed = true; };
    };
    select = {
      border = { fg = t.accent.primary; };
      active = { fg = t.accent.primary; };
      inactive = { };
    };
  };

  # Bottom to top: umber, bronze, gold, bright gold, parchment — a flame.
  cava = lib.listToAttrs
    (lib.imap1
      (i: c: lib.nameValuePair "gradient_color_${toString i}" "'${c}'")
      [ t.bg.surface2 bronze t.accent.primary t.state.warn parchment2 t.fg.primary ])
  // { gradient = 1; gradient_count = 6; };
in
{
  inherit btop bat yazi cava;
}
