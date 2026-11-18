# Tool and app themes for `integration.tools` (D-051, D-059), generated at
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

  # Syntax roles shared by bat and VS Code, so code reads the same in both.
  roles = [
    { name = "Comment"; scope = "comment, punctuation.definition.comment"; fg = t.fg.subtle; style = "italic"; }
    { name = "String"; scope = "string, punctuation.definition.string"; fg = t.state.ok; }
    { name = "Escape"; scope = "constant.character.escape, string.regexp"; fg = teal; }
    { name = "Number"; scope = "constant.numeric, constant.language, constant.other"; fg = peach; }
    { name = "Keyword"; scope = "keyword, storage.modifier, keyword.control"; fg = t.accent.primary; }
    { name = "Storage"; scope = "storage.type"; fg = t.accent.primary; style = "italic"; }
    { name = "Operator"; scope = "keyword.operator, punctuation"; fg = t.fg.muted; }
    { name = "Function"; scope = "entity.name.function, support.function, meta.function-call"; fg = t.accent.secondary; }
    { name = "Type"; scope = "entity.name.type, entity.name.class, support.type, support.class"; fg = lavender; }
    { name = "Parameter"; scope = "variable.parameter"; fg = rose; style = "italic"; }
    { name = "Variable"; scope = "variable, variable.other"; fg = t.fg.primary; }
    { name = "Builtin"; scope = "variable.language, support.constant"; fg = t.state.warn; }
    { name = "Tag"; scope = "entity.name.tag"; fg = pink; }
    { name = "Attribute"; scope = "entity.other.attribute-name"; fg = peach; }
    { name = "Key"; scope = "meta.mapping.key, support.type.property-name"; fg = parchment2; }
    { name = "Heading"; scope = "markup.heading, entity.name.section"; fg = t.accent.primary; style = "bold"; }
    { name = "Emphasis"; scope = "markup.italic"; fg = rose; style = "italic"; }
    { name = "Strong"; scope = "markup.bold"; fg = rose; style = "bold"; }
    { name = "Link"; scope = "markup.underline.link"; fg = t.accent.secondary; style = "underline"; }
    { name = "Inserted"; scope = "markup.inserted"; fg = t.state.ok; }
    { name = "Deleted"; scope = "markup.deleted"; fg = t.state.danger; }
    { name = "Changed"; scope = "markup.changed"; fg = t.state.warn; }
    { name = "Invalid"; scope = "invalid"; fg = t.state.danger; }
  ];

  # TextMate theme for bat: one plist, scopes coloured by role.
  scope = { name, scope, fg, style ? "" }: ''
    <dict>
      <key>name</key><string>${name}</string>
      <key>scope</key><string>${scope}</string>
      <key>settings</key><dict>
        <key>foreground</key><string>${fg}</string>${lib.optionalString (style != "") "\n        <key>fontStyle</key><string>${style}</string>"}
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
    ${lib.concatMapStrings scope roles}  </array>
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

  # ANSI colours for VS Code's terminal, by the same roles.
  ansi = {
    Black = t.bg.surface1;
    Red = t.state.danger;
    Green = t.state.ok;
    Yellow = t.state.warn;
    Blue = t.accent.secondary;
    Magenta = pink;
    Cyan = teal;
    White = t.fg.muted;
    BrightBlack = bronze;
    BrightRed = peach;
    BrightGreen = t.state.ok;
    BrightYellow = t.accent.primary;
    BrightBlue = lavender;
    BrightMagenta = rose;
    BrightCyan = t.state.info;
    BrightWhite = t.fg.primary;
  };

  # "#rrggbb" + two hex digits of alpha.
  alpha = c: a: "${c}${a}";
  # Relative luminance from "#rrggbb", to tell a dark theme from a light one.
  luminance = c:
    let channel = i: lib.fromHexString (builtins.substring i 2 c) / 255.0; in
    0.2126 * channel 1 + 0.7152 * channel 3 + 0.0722 * channel 5;
  dark = luminance t.bg.base < 0.5;
  label = theme.meta.displayName or theme.meta.name;

  # VS Code: a colour theme extension built by Nix. The workbench wears the
  # bar's surfaces (sunken chrome, mantle sidebars, base editor) and the
  # accent marks focus and the active tab; code uses the roles above.
  vscodeTheme = {
    name = label;
    type = if dark then "dark" else "light";
    semanticHighlighting = true;
    colors = {
      foreground = t.fg.primary;
      descriptionForeground = t.fg.muted;
      disabledForeground = t.fg.subtle;
      errorForeground = t.state.danger;
      focusBorder = alpha t.accent.primary "99";
      "widget.shadow" = alpha t.bg.sunken "aa";
      "selection.background" = alpha t.accent.primary "55";
      "textLink.foreground" = t.accent.secondary;
      "textLink.activeForeground" = t.accent.primary;

      "editor.background" = t.bg.base;
      "editor.foreground" = t.fg.primary;
      "editorCursor.foreground" = t.accent.primary;
      "editor.lineHighlightBackground" = alpha t.bg.elevated "88";
      "editor.selectionBackground" = alpha t.accent.primary "40";
      "editor.inactiveSelectionBackground" = alpha t.accent.primary "22";
      "editor.selectionHighlightBackground" = alpha t.accent.secondary "26";
      "editor.wordHighlightBackground" = alpha t.accent.secondary "22";
      "editor.findMatchBackground" = alpha t.state.warn "55";
      "editor.findMatchHighlightBackground" = alpha t.state.warn "26";
      "editorLineNumber.foreground" = t.bg.surface2;
      "editorLineNumber.activeForeground" = t.accent.primary;
      "editorIndentGuide.background1" = t.bg.surface1;
      "editorIndentGuide.activeBackground1" = t.bg.surface2;
      "editorWhitespace.foreground" = t.bg.surface1;
      "editorBracketMatch.background" = alpha t.accent.primary "22";
      "editorBracketMatch.border" = alpha t.accent.primary "88";
      "editorGutter.background" = t.bg.base;
      "editorGutter.addedBackground" = t.state.ok;
      "editorGutter.modifiedBackground" = t.state.warn;
      "editorGutter.deletedBackground" = t.state.danger;
      "editorError.foreground" = t.state.danger;
      "editorWarning.foreground" = t.state.warn;
      "editorInfo.foreground" = t.state.info;
      "editorHint.foreground" = t.fg.subtle;
      "editorWidget.background" = t.bg.mantle;
      "editorWidget.border" = t.bg.surface1;
      "editorHoverWidget.background" = t.bg.mantle;
      "editorHoverWidget.border" = t.bg.surface1;
      "editorSuggestWidget.background" = t.bg.mantle;
      "editorSuggestWidget.border" = t.bg.surface1;
      "editorSuggestWidget.selectedBackground" = t.bg.surface1;
      "editorSuggestWidget.highlightForeground" = t.accent.primary;
      "editorGroup.border" = t.bg.surface1;
      "editorGroupHeader.tabsBackground" = t.bg.mantle;
      "editorRuler.foreground" = t.bg.surface1;
      "editorOverviewRuler.border" = t.bg.mantle;
      "minimap.background" = t.bg.base;
      "scrollbarSlider.background" = alpha t.bg.surface2 "55";
      "scrollbarSlider.hoverBackground" = alpha t.bg.surface2 "88";
      "scrollbarSlider.activeBackground" = alpha t.accent.primary "66";

      "tab.activeBackground" = t.bg.base;
      "tab.activeForeground" = t.fg.primary;
      "tab.activeBorderTop" = t.accent.primary;
      "tab.inactiveBackground" = t.bg.mantle;
      "tab.inactiveForeground" = t.fg.subtle;
      "tab.border" = t.bg.mantle;
      "tab.hoverBackground" = t.bg.elevated;
      "tab.unfocusedActiveBorderTop" = bronze;

      "titleBar.activeBackground" = t.bg.sunken;
      "titleBar.activeForeground" = t.fg.muted;
      "titleBar.inactiveBackground" = t.bg.sunken;
      "titleBar.inactiveForeground" = t.fg.subtle;
      "activityBar.background" = t.bg.sunken;
      "activityBar.foreground" = t.accent.primary;
      "activityBar.inactiveForeground" = t.fg.subtle;
      "activityBar.activeBorder" = t.accent.primary;
      "activityBarBadge.background" = t.accent.primary;
      "activityBarBadge.foreground" = t.bg.sunken;
      "sideBar.background" = t.bg.mantle;
      "sideBar.foreground" = t.fg.muted;
      "sideBar.border" = t.bg.sunken;
      "sideBarTitle.foreground" = t.accent.primary;
      "sideBarSectionHeader.background" = t.bg.mantle;
      "sideBarSectionHeader.foreground" = t.fg.primary;
      "statusBar.background" = t.bg.sunken;
      "statusBar.foreground" = t.fg.muted;
      "statusBar.border" = t.bg.sunken;
      "statusBar.debuggingBackground" = t.accent.tertiary;
      "statusBar.debuggingForeground" = t.fg.primary;
      "statusBar.noFolderBackground" = t.bg.sunken;
      "statusBarItem.remoteBackground" = t.accent.primary;
      "statusBarItem.remoteForeground" = t.bg.sunken;
      "statusBarItem.hoverBackground" = t.bg.elevated;
      "panel.background" = t.bg.mantle;
      "panel.border" = t.bg.surface1;
      "panelTitle.activeForeground" = t.accent.primary;
      "panelTitle.activeBorder" = t.accent.primary;
      "panelTitle.inactiveForeground" = t.fg.subtle;
      "breadcrumb.foreground" = t.fg.subtle;
      "breadcrumb.focusForeground" = t.fg.primary;

      "list.activeSelectionBackground" = t.bg.surface1;
      "list.activeSelectionForeground" = t.fg.primary;
      "list.inactiveSelectionBackground" = t.bg.elevated;
      "list.hoverBackground" = alpha t.bg.elevated "aa";
      "list.focusOutline" = alpha t.accent.primary "66";
      "list.highlightForeground" = t.accent.primary;
      "list.errorForeground" = t.state.danger;
      "list.warningForeground" = t.state.warn;
      "tree.indentGuidesStroke" = t.bg.surface1;
      "input.background" = t.bg.sunken;
      "input.foreground" = t.fg.primary;
      "input.border" = t.bg.surface1;
      "input.placeholderForeground" = t.fg.subtle;
      "inputOption.activeBorder" = t.accent.primary;
      "dropdown.background" = t.bg.mantle;
      "dropdown.border" = t.bg.surface1;
      "quickInput.background" = t.bg.mantle;
      "quickInputList.focusBackground" = t.bg.surface1;
      "button.background" = t.accent.primary;
      "button.foreground" = t.bg.sunken;
      "button.hoverBackground" = t.state.warn;
      "button.secondaryBackground" = t.bg.surface1;
      "button.secondaryForeground" = t.fg.primary;
      "badge.background" = t.accent.primary;
      "badge.foreground" = t.bg.sunken;
      "progressBar.background" = t.accent.primary;
      "notifications.background" = t.bg.mantle;
      "notifications.border" = t.bg.surface1;
      "notificationCenterHeader.background" = t.bg.sunken;
      "menu.background" = t.bg.mantle;
      "menu.foreground" = t.fg.primary;
      "menu.selectionBackground" = t.bg.surface1;
      "menu.separatorBackground" = t.bg.surface1;

      "gitDecoration.addedResourceForeground" = t.state.ok;
      "gitDecoration.modifiedResourceForeground" = t.state.warn;
      "gitDecoration.deletedResourceForeground" = t.state.danger;
      "gitDecoration.untrackedResourceForeground" = teal;
      "gitDecoration.ignoredResourceForeground" = t.fg.subtle;
      "gitDecoration.conflictingResourceForeground" = pink;
      "diffEditor.insertedTextBackground" = alpha t.state.ok "22";
      "diffEditor.removedTextBackground" = alpha t.state.danger "22";

      "terminal.background" = t.bg.base;
      "terminal.foreground" = t.fg.primary;
      "terminalCursor.foreground" = t.accent.primary;
      "terminal.selectionBackground" = alpha t.accent.primary "40";
    } // lib.mapAttrs' (n: lib.nameValuePair "terminal.ansi${n}") ansi;
    tokenColors = map
      (r: {
        inherit (r) name scope;
        settings = { foreground = r.fg; } // lib.optionalAttrs (r ? style) { fontStyle = r.style; };
      })
      roles;
    semanticTokenColors = {
      namespace = lavender;
      "variable.readonly" = peach;
      "property" = parchment2;
      "enumMember" = peach;
      "macro" = t.state.warn;
    };
  };

  vscode = pkgs.vscode-utils.buildVscodeExtension {
    pname = "rice-theme";
    version = "1.0.0";
    vscodeExtPublisher = "rice";
    vscodeExtName = "rice-theme";
    vscodeExtUniqueId = "rice.rice-theme";
    src = pkgs.linkFarm "rice-vscode-theme" {
      "package.json" = pkgs.writeText "package.json" (builtins.toJSON {
        name = "rice-theme";
        publisher = "rice";
        displayName = "${label} (rice)";
        version = "1.0.0";
        engines.vscode = "^1.70.0";
        categories = [ "Themes" ];
        contributes.themes = [{
          inherit label;
          uiTheme = if dark then "vs-dark" else "vs";
          path = "./themes/rice-color-theme.json";
        }];
      });
      "themes/rice-color-theme.json" = pkgs.writeText "rice-color-theme.json" (builtins.toJSON vscodeTheme);
    };
    sourceRoot = "rice-vscode-theme";
  };

  # Spotify (Spicetify colour.ini keys, no "#"): sunken sidebar and player
  # around a base main view, gold for buttons and the active tab.
  spotify = lib.mapAttrs (_: lib.removePrefix "#") {
    text = t.fg.primary;
    subtext = t.fg.muted;
    main = t.bg.base;
    main-elevated = t.bg.elevated;
    highlight = t.bg.surface1;
    highlight-elevated = t.bg.surface2;
    sidebar = t.bg.sunken;
    player = t.bg.mantle;
    card = t.bg.elevated;
    shadow = t.bg.sunken;
    selected-row = t.fg.muted;
    button = t.accent.primary;
    button-active = t.state.warn;
    button-disabled = t.bg.surface2;
    tab-active = t.bg.surface1;
    notification = t.bg.elevated;
    notification-error = t.state.danger;
    misc = t.fg.subtle;
  };

  # Discord (a Vencord theme for Vesktop). Only Discord's own colour
  # variables are overridden, no class selectors, so a client update can at
  # worst leave a surface stock. Applies to Discord's dark appearances.
  discord = pkgs.writeText "rice.css" ''
    /**
     * @name ${label} (rice)
     * @description Generated from the rice theme's colour tokens (D-059).
     * @author rice
     * @version 1.0.0
     */
    .theme-dark, .theme-darker, .theme-midnight, .visual-refresh.theme-dark {
      --background-base-lowest: ${t.bg.sunken};
      --background-base-lower: ${t.bg.mantle};
      --background-base-low: ${t.bg.base};
      --background-surface-high: ${t.bg.elevated};
      --background-surface-higher: ${t.bg.elevated};
      --background-surface-highest: ${t.bg.surface1};
      --background-primary: ${t.bg.base};
      --background-secondary: ${t.bg.mantle};
      --background-secondary-alt: ${t.bg.sunken};
      --background-tertiary: ${t.bg.sunken};
      --background-floating: ${t.bg.mantle};
      --background-nested-floating: ${t.bg.elevated};
      --background-accent: ${t.bg.surface1};
      --background-mod-subtle: ${alpha t.bg.surface1 "66"};
      --background-mod-normal: ${alpha t.bg.surface1 "99"};
      --background-mod-strong: ${t.bg.surface1};
      --background-modifier-hover: ${alpha t.bg.surface1 "66"};
      --background-modifier-active: ${alpha t.bg.surface1 "99"};
      --background-modifier-selected: ${t.bg.surface1};
      --background-modifier-accent: ${alpha t.bg.surface2 "66"};
      --chat-background-default: ${t.bg.base};
      --channeltextarea-background: ${t.bg.elevated};
      --modal-background: ${t.bg.mantle};
      --modal-footer-background: ${t.bg.sunken};
      --input-background: ${t.bg.sunken};
      --border-subtle: ${t.bg.surface1};
      --border-normal: ${t.bg.surface1};
      --border-strong: ${t.bg.surface2};

      --text-default: ${t.fg.primary};
      --text-normal: ${t.fg.primary};
      --text-strong: ${t.fg.primary};
      --text-muted: ${t.fg.subtle};
      --text-secondary: ${t.fg.muted};
      --text-link: ${t.accent.secondary};
      --text-brand: ${t.accent.primary};
      --text-positive: ${t.state.ok};
      --text-warning: ${t.state.warn};
      --text-danger: ${t.state.danger};
      --text-feedback-critical: ${t.state.danger};
      --header-primary: ${t.accent.primary};
      --header-secondary: ${t.fg.muted};
      --channels-default: ${t.fg.subtle};
      --channel-icon: ${t.fg.subtle};
      --interactive-normal: ${t.fg.muted};
      --interactive-hover: ${t.fg.primary};
      --interactive-active: ${t.accent.primary};
      --interactive-muted: ${t.bg.surface2};
      --icon-default: ${t.fg.muted};
      --icon-strong: ${t.fg.primary};
      --icon-muted: ${t.fg.subtle};

      --brand-experiment: ${t.accent.primary};
      --brand-500: ${t.accent.primary};
      --brand-560: ${t.state.warn};
      --button-filled-brand-background: ${t.accent.primary};
      --button-filled-brand-background-hover: ${t.state.warn};
      --button-filled-brand-text: ${t.bg.sunken};
      --mention-foreground: ${t.accent.primary};
      --mention-background: ${alpha t.accent.primary "26"};
      --info-danger-foreground: ${t.state.danger};
      --status-positive: ${t.state.ok};
      --status-warning: ${t.state.warn};
      --status-danger: ${t.state.danger};
      --scrollbar-thin-thumb: ${t.bg.surface2};
      --scrollbar-auto-thumb: ${t.bg.surface2};
      --scrollbar-auto-track: ${t.bg.mantle};
    }
  '';
in
{
  inherit btop bat yazi cava vscode spotify discord;
  vscodeThemeName = label;
}
