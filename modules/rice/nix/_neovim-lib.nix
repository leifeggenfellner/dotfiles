# Neovim flavour from `widgets.terminal.settings.neovim` (D-052). A theme
# opts into a colourscheme (highlight groups mapped from its colour tokens
# and legacy palette, one theme-blind mapping) and a start screen (title,
# an epigraph pool, a recent-files label). Each theme becomes a pure-data
# Lua module; Neovim loads the active theme's at startup (rice-query), so
# rice-switch reaches new editors without a rebuild.
{ pkgs, lib }:
{ themeName, theme }:
let
  settings = theme.widgets.terminal.settings.neovim or null;
  t = theme.tokens.colors;
  p = lib.mapAttrs (_: v: "#${v}") (theme.palette.legacy or { });
  pal = key: fallback: p.${key} or fallback;

  bronze = pal "overlay0" t.fg.subtle;
  parchment2 = pal "subtext1" t.fg.muted;
  peach = pal "peach" t.state.warn;
  rose = pal "rosewater" t.fg.primary;
  lavender = pal "lavender" t.accent.secondary;
  teal = pal "teal" t.state.ok;

  # Red is kept for errors and deletions (L-006 accent budget): no other
  # group uses state.danger.
  groups = {
    Normal = { fg = t.fg.primary; };
    NormalNC = { link = "Normal"; };
    NormalFloat = { fg = t.fg.primary; bg = t.bg.elevated; };
    FloatBorder = { fg = bronze; bg = t.bg.elevated; };
    FloatTitle = { fg = t.accent.primary; bg = t.bg.elevated; bold = true; };
    Cursor = { fg = t.bg.base; bg = t.accent.primary; };
    CursorLine = { bg = t.bg.elevated; };
    CursorLineNr = { fg = t.accent.primary; bold = true; };
    LineNr = { fg = t.bg.surface2; };
    SignColumn = { };
    ColorColumn = { bg = t.bg.mantle; };
    Folded = { fg = t.fg.muted; bg = t.bg.elevated; italic = true; };
    FoldColumn = { fg = t.bg.surface2; };
    NonText = { fg = t.bg.surface1; };
    Whitespace = { fg = t.bg.surface1; };
    EndOfBuffer = { fg = t.bg.base; };
    WinSeparator = { fg = bronze; };
    # The repo's statusline is a rule drawn in `─` (programs/neovim.nix).
    StatusLine = { fg = bronze; };
    StatusLineNC = { fg = t.bg.surface2; };
    TabLine = { fg = t.fg.muted; bg = t.bg.elevated; };
    TabLineSel = { fg = t.bg.sunken; bg = t.accent.primary; bold = true; };
    TabLineFill = { bg = t.bg.mantle; };
    Visual = { bg = t.bg.surface1; };
    Search = { fg = t.bg.sunken; bg = t.state.warn; };
    IncSearch = { fg = t.bg.sunken; bg = t.accent.primary; bold = true; };
    CurSearch = { link = "IncSearch"; };
    MatchParen = { fg = t.accent.primary; bold = true; underline = true; };
    Pmenu = { fg = t.fg.primary; bg = t.bg.elevated; };
    PmenuSel = { fg = t.accent.primary; bg = t.bg.surface1; bold = true; };
    PmenuSbar = { bg = t.bg.elevated; };
    PmenuThumb = { bg = bronze; };
    Title = { fg = t.accent.primary; bold = true; };
    Directory = { fg = t.accent.secondary; };
    Question = { fg = t.accent.secondary; };
    MoreMsg = { fg = t.state.ok; };
    ModeMsg = { fg = t.fg.muted; };
    WarningMsg = { fg = t.state.warn; };
    ErrorMsg = { fg = t.state.danger; bold = true; };

    Comment = { fg = t.fg.subtle; italic = true; };
    String = { fg = t.state.ok; };
    Character = { fg = teal; };
    Number = { fg = peach; };
    Boolean = { fg = peach; };
    Float = { fg = peach; };
    Constant = { fg = peach; };
    Identifier = { fg = t.fg.primary; };
    Function = { fg = t.accent.secondary; };
    Statement = { fg = t.accent.primary; };
    Keyword = { fg = t.accent.primary; };
    Conditional = { fg = t.accent.primary; };
    Repeat = { fg = t.accent.primary; };
    Exception = { fg = t.accent.primary; italic = true; };
    Operator = { fg = t.fg.muted; };
    PreProc = { fg = t.state.warn; };
    Include = { fg = t.accent.primary; italic = true; };
    Type = { fg = lavender; };
    StorageClass = { fg = t.accent.primary; italic = true; };
    Special = { fg = teal; };
    SpecialChar = { fg = teal; };
    Delimiter = { fg = t.fg.muted; };
    Underlined = { fg = t.accent.secondary; underline = true; };
    Todo = { fg = t.bg.sunken; bg = t.state.warn; bold = true; };
    Error = { fg = t.state.danger; };

    "@variable" = { fg = t.fg.primary; };
    "@variable.parameter" = { fg = rose; italic = true; };
    "@variable.member" = { fg = parchment2; };
    "@property" = { fg = parchment2; };
    "@variable.builtin" = { fg = t.state.warn; };
    "@constant.builtin" = { fg = peach; italic = true; };
    "@function.builtin" = { fg = t.accent.secondary; italic = true; };
    "@constructor" = { fg = lavender; };
    "@tag" = { fg = t.accent.primary; };
    "@tag.attribute" = { fg = peach; };
    "@tag.delimiter" = { fg = t.fg.muted; };
    "@punctuation" = { fg = t.fg.muted; };
    "@string.escape" = { fg = teal; };
    "@string.special" = { fg = teal; };
    "@markup.heading" = { fg = t.accent.primary; bold = true; };
    "@markup.strong" = { fg = rose; bold = true; };
    "@markup.italic" = { fg = rose; italic = true; };
    "@markup.link" = { fg = t.accent.secondary; underline = true; };
    "@markup.raw" = { fg = t.state.ok; };
    "@markup.list" = { fg = t.accent.primary; };
    "@comment.todo" = { link = "Todo"; };
    "@comment.note" = { fg = t.bg.sunken; bg = t.accent.secondary; bold = true; };
    "@comment.warning" = { fg = t.bg.sunken; bg = t.state.warn; bold = true; };
    "@comment.error" = { fg = t.bg.sunken; bg = t.state.danger; bold = true; };

    DiagnosticError = { fg = t.state.danger; };
    DiagnosticWarn = { fg = t.state.warn; };
    DiagnosticInfo = { fg = t.state.info; };
    DiagnosticHint = { fg = teal; };
    DiagnosticOk = { fg = t.state.ok; };
    DiagnosticUnderlineError = { sp = t.state.danger; undercurl = true; };
    DiagnosticUnderlineWarn = { sp = t.state.warn; undercurl = true; };
    DiagnosticUnderlineInfo = { sp = t.state.info; undercurl = true; };
    DiagnosticUnderlineHint = { sp = teal; undercurl = true; };
    DiagnosticVirtualTextError = { fg = t.state.danger; italic = true; };
    DiagnosticVirtualTextWarn = { fg = t.state.warn; italic = true; };
    DiagnosticVirtualTextInfo = { fg = t.state.info; italic = true; };
    DiagnosticVirtualTextHint = { fg = teal; italic = true; };
    LspReferenceText = { bg = t.bg.surface1; };
    LspReferenceRead = { bg = t.bg.surface1; };
    LspReferenceWrite = { bg = t.bg.surface1; underline = true; };
    LspInlayHint = { fg = t.bg.surface2; italic = true; };

    DiffAdd = { bg = t.bg.elevated; fg = t.state.ok; };
    DiffChange = { bg = t.bg.elevated; fg = t.state.warn; };
    DiffDelete = { bg = t.bg.elevated; fg = t.state.danger; };
    DiffText = { bg = t.bg.surface1; fg = t.state.warn; bold = true; };
    Added = { fg = t.state.ok; };
    Changed = { fg = t.state.warn; };
    Removed = { fg = t.state.danger; };

    TelescopeBorder = { link = "FloatBorder"; };
    TelescopeTitle = { link = "FloatTitle"; };
    TelescopeSelection = { link = "PmenuSel"; };
    TelescopeMatching = { fg = t.state.warn; bold = true; };

    # Start screen (rice/start.lua).
    RiceStartTitle = { fg = t.accent.primary; bold = true; };
    RiceStartEpigraph = { fg = t.fg.muted; italic = true; };
    RiceStartLabel = { fg = t.fg.subtle; };
    RiceStartKey = { fg = t.accent.primary; bold = true; };
    RiceStartPath = { fg = t.fg.primary; };
  };

  getPath = path: lib.attrByPath (lib.splitString "." path)
    (throw "rice theme '${themeName}': neovim.start.epigraphs '${path}' does not resolve")
    theme;
  start = settings.start or null;
  epigraphs =
    if start == null then [ ]
    else if builtins.isList (start.epigraphs or null) then start.epigraphs
    else getPath start.epigraphs;

  module = pkgs.writeText "rice-${themeName}.lua" ("return " + lib.generators.toLua { } (
    { name = themeName; }
      // lib.optionalAttrs (settings.colorscheme or false) { inherit groups; }
      // lib.optionalAttrs (start != null) {
      start = {
        title = start.title or "";
        recentLabel = start.recentLabel or "Recent files";
        inherit epigraphs;
      };
    }
  ));
in
if settings == null then null else module
