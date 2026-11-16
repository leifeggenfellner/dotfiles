# Starship prompt flavour from `widgets.terminal.settings.prompt` (D-050).
# The mapping is closed and theme-blind: a theme supplies copy (labels,
# a glyph, a format) and a catalog path; this builds one Starship config
# and one fish snippet per theme at rebuild. The shell picks the active
# theme's pair at startup (rice-query), so rice-switch reaches new shells
# without a rebuild. Labels always sit beside the real value: the exit
# code and signal, the git counts, the workspace id.
{ pkgs, lib }:
{ themeName, theme, baseSettings }:
let
  prompt = theme.widgets.terminal.settings.prompt or null;
  accent = theme.tokens.colors.accent.primary;

  # Starship format strings treat these as syntax.
  escape = lib.replaceStrings [ "\\" "[" "]" "(" ")" "$" ] [ "\\\\" "\\[" "\\]" "\\(" "\\)" "\\$" ];
  # Fish single-quoted string.
  fishQuote = s: "'" + lib.replaceStrings [ "\\" "'" ] [ "\\\\" "\\'" ] s + "'";

  getPath = path: lib.attrByPath (lib.splitString "." path)
    (throw "rice theme '${themeName}': prompt.workspace.catalog '${path}' does not resolve")
    theme;
  fill = fields: format:
    builtins.replaceStrings (map (k: "{${k}}") (lib.attrNames fields)) (map toString (lib.attrValues fields)) format;

  workspace = prompt.workspace or null;
  wsGlyph = workspace.glyph or "";
  wsFormat = workspace.format or "{glyph} {label} {id}";
  # Unlisted workspaces still show their real name or id.
  wsLabel = fields: lib.trim (lib.replaceStrings [ "  " ] [ " " ] (fill ({ glyph = wsGlyph; label = ""; } // fields) wsFormat));

  overlay = lib.foldl' lib.recursiveUpdate { } [
    # The label stands beside the real counts, so every flag carries one.
    (lib.optionalAttrs (prompt ? git) {
      git_status = {
        format = "([${escape prompt.git.label} \\[$all_status$ahead_behind\\]]($style) )";
        conflicted = "=$count";
        stashed = "≡$count";
        deleted = "✘$count";
        renamed = "»$count";
        modified = "!$count";
        typechanged = "~$count";
        staged = "+$count";
        untracked = "?$count";
        ahead = "⇡$count";
        behind = "⇣$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
      };
    })
    (lib.optionalAttrs (prompt ? failure) {
      status.format = "[$symbol ${escape prompt.failure.label} · $status( $signal_name)](fg:red) ";
    })
    (lib.optionalAttrs (workspace != null) {
      format = "\${env_var.RICE_WORKSPACE}" + baseSettings.format;
      env_var.RICE_WORKSPACE = {
        variable = "RICE_WORKSPACE";
        format = "[$env_value ](fg:${accent})";
      };
    })
  ];

  toml = (pkgs.formats.toml { }).generate "starship-rice-${themeName}.toml"
    (lib.recursiveUpdate baseSettings overlay);

  # The terminal's workspace, read when the shell starts and whenever its
  # terminal regains focus (a moved window is refocused to be used), so
  # drawing a prompt costs no hyprctl call. Skipped outside Hyprland.
  workspaceFish = lib.optionalString (workspace != null) (lib.concatLines ([
    "if set -q HYPRLAND_INSTANCE_SIGNATURE"
    "    function __rice_prompt_workspace --on-event fish_focus_in"
    "        set -l ws (hyprctl activeworkspace 2>/dev/null | string match -rg '^workspace (-?\\d+) \\((.*)\\) on')"
    "        or begin"
    "            set -e RICE_WORKSPACE"
    "            return"
    "        end"
    "        switch $ws[1]"
  ]
  ++ lib.concatMap
    (item: [
      "            case ${toString item.id}"
      "                set -gx RICE_WORKSPACE ${fishQuote (wsLabel { inherit (item) id label; })}"
    ])
    (getPath workspace.catalog)
  ++ [
    "            case '*'"
    "                set -gx RICE_WORKSPACE (string replace -- '{name}' $ws[2] ${fishQuote (wsLabel { id = "{name}"; })})"
    "        end"
    "    end"
    "    __rice_prompt_workspace"
    "end"
  ]));

  fish = pkgs.writeText "starship-rice-${themeName}.fish" ''
    set -gx STARSHIP_CONFIG ${toml}
    ${workspaceFish}
  '';
in
if prompt == null then null else { inherit toml fish; }
