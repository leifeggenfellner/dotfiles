# The browser dressed by the rice (D-060), generated at rebuild from the
# configured theme: Zen's chrome as a stylesheet over its own colour
# variables (when `integration.tools` lists `zen`), and a new-tab page
# laid out as a newspaper (when the theme has `widgets.newtab.settings`).
# Both are theme-blind: the theme supplies tokens and copy only.
#
# The page is static; the live part (weather, moon, the day's omen) comes
# from the script the shell writes at `feedPath` (modules/newtab). The
# date and the epigraph are worked out in the page itself, so it still
# reads true with no shell running.
{ pkgs, lib }:
{ theme, feedPath, links ? [ ] }:
let
  t = theme.tokens.colors;
  fonts = theme.tokens.typography.families;
  settings = theme.widgets.newtab.settings or null;
  label = theme.meta.displayName or theme.meta.name;
  # Dark or light by bg.base's luminance, as for the VS Code theme.
  dark =
    let channel = i: lib.fromHexString (builtins.substring i 2 t.bg.base) / 255.0; in
    0.2126 * channel 1 + 0.7152 * channel 3 + 0.0722 * channel 5 < 0.5;

  # A theme-authored manifest path (D-042's cross-widget read) or a list.
  listAt = v:
    if builtins.isList v then v
    else if builtins.isString v then lib.attrByPath (lib.splitString "." v) [ ] theme
    else [ ];

  # Data the page renders with textContent, never as markup; "</" is
  # escaped so nothing can close the script early.
  json = v: builtins.replaceStrings [ "</" ] [ "<\\/" ] (builtins.toJSON v);

  page = {
    title = settings.title or label;
    tagline = settings.tagline or "";
    epigraphs = listAt (settings.epigraphs or [ ]);
    labels = {
      weather = "Weather";
      moon = "Moon";
      omen = "Omen";
      links = "Links";
      offline = "The shell sent no dispatch";
      unavailable = "Weather unavailable";
    } // (settings.labels or { });
    inherit links;
  };

  newtab = pkgs.writeTextDir "index.html" ''
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>${lib.escapeXML page.title}</title>
    <style>
      :root {
        --paper: ${t.bg.base};
        --paper-deep: ${t.bg.sunken};
        --panel: ${t.bg.mantle};
        --rule: ${t.bg.surface2};
        --ink: ${t.fg.primary};
        --ink-muted: ${t.fg.muted};
        --ink-faint: ${t.fg.subtle};
        --accent: ${t.accent.primary};
        --accent-2: ${t.accent.secondary};
        --display: "${fonts.display}", Georgia, serif;
        --body: "${fonts.sans}", system-ui, sans-serif;
      }
      * { box-sizing: border-box; }
      html, body { margin: 0; min-height: 100%; }
      body {
        background: radial-gradient(ellipse at top, var(--panel), var(--paper-deep) 75%);
        color: var(--ink);
        font: 15px/1.5 var(--body);
        display: flex;
        justify-content: center;
        padding: 6vh 24px 48px;
      }
      main { width: min(920px, 100%); }
      .dateline {
        display: flex; justify-content: space-between; gap: 16px; flex-wrap: wrap;
        color: var(--ink-muted); font-size: 13px; letter-spacing: 0.08em; text-transform: uppercase;
        border-bottom: 1px solid var(--rule); padding-bottom: 6px;
      }
      h1 {
        font: 600 clamp(40px, 8vw, 76px)/1.05 var(--display);
        color: var(--accent); text-align: center; letter-spacing: 0.04em;
        margin: 18px 0 4px;
      }
      .tagline { text-align: center; font-style: italic; color: var(--ink-muted); margin: 0 0 14px; }
      .rule { border: 0; border-top: 3px double var(--rule); margin: 0 0 22px; }
      .columns { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0; }
      .column { padding: 0 20px; border-left: 1px solid var(--rule); }
      .column:first-child { border-left: 0; padding-left: 0; }
      .column:last-child { padding-right: 0; }
      h2 {
        font: 600 13px/1.3 var(--display); color: var(--accent);
        letter-spacing: 0.12em; text-transform: uppercase; margin: 0 0 8px;
      }
      .lead { font-size: 20px; margin: 0 0 4px; }
      #moon { text-transform: capitalize; }
      .note { color: var(--ink-faint); font-size: 13px; margin: 0; }
      blockquote {
        margin: 30px auto; max-width: 640px; text-align: center;
        font: italic 20px/1.5 var(--display); color: var(--ink);
        border-top: 1px solid var(--rule); border-bottom: 1px solid var(--rule); padding: 18px 8px;
      }
      blockquote::before, blockquote::after { color: var(--accent); }
      blockquote::before { content: "“"; }
      blockquote::after { content: "”"; }
      nav ul { list-style: none; padding: 0; margin: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(170px, 1fr)); gap: 8px; }
      nav a {
        display: block; padding: 8px 12px; border: 1px solid var(--rule); border-radius: 4px;
        color: var(--ink); text-decoration: none; background: color-mix(in srgb, var(--panel) 70%, transparent);
      }
      nav a:hover, nav a:focus-visible { border-color: var(--accent); color: var(--accent); outline: none; }
      [hidden] { display: none !important; }
    </style>
    </head>
    <body>
    <main>
      <div class="dateline"><span id="date"></span><span id="edition"></span></div>
      <h1 id="title"></h1>
      <p class="tagline" id="tagline"></p>
      <hr class="rule">
      <section class="columns">
        <div class="column"><h2 id="weather-label"></h2><p class="lead" id="weather"></p><p class="note" id="weather-note"></p></div>
        <div class="column"><h2 id="moon-label"></h2><p class="lead" id="moon"></p><p class="note" id="moon-note"></p></div>
        <div class="column" id="omen-column"><h2 id="omen-label"></h2><p class="lead" id="omen"></p></div>
      </section>
      <blockquote id="epigraph"></blockquote>
      <nav id="links-section"><h2 id="links-label"></h2><ul id="links"></ul></nav>
    </main>
    <script>window.riceNewtab = null;</script>
    <script src="${lib.escapeXML ("file://" + feedPath)}"></script>
    <script>
    (() => {
      const page = ${json page};
      const feed = window.riceNewtab;
      const $ = id => document.getElementById(id);
      const set = (id, text) => { $(id).textContent = text; };
      const now = new Date();

      set("title", page.title);
      set("tagline", page.tagline);
      $("tagline").hidden = page.tagline.length === 0;
      set("date", now.toLocaleDateString(undefined, { weekday: "long", day: "numeric", month: "long", year: "numeric" }));
      const start = new Date(now.getFullYear(), 0, 0);
      set("edition", "No. " + Math.floor((now - start) / 86400000));

      for (const key of ["weather", "moon", "omen", "links"])
        set(key + "-label", page.labels[key]);

      // The same pick as the dashboard epigraph: by day of the month.
      const lines = page.epigraphs;
      $("epigraph").hidden = lines.length === 0;
      if (lines.length > 0)
        set("epigraph", lines[(now.getDate() - 1) % lines.length]);

      if (!feed) {
        set("weather", page.labels.unavailable);
        set("weather-note", page.labels.offline);
        $("moon").parentElement.hidden = true;
        $("omen-column").hidden = true;
      } else {
        const asOf = "as of " + new Date(feed.updated).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" });
        const w = feed.weather;
        if (w) {
          set("weather", w.temperatureC + "°C, " + w.condition.toLowerCase());
          set("weather-note", [w.location, "feels like " + w.feelsLikeC + "°C", asOf].filter(Boolean).join(" · "));
        } else {
          set("weather", page.labels.unavailable);
          set("weather-note", asOf);
        }
        set("moon", feed.moon.name);
        set("moon-note", feed.moon.illumination + "% illuminated");
        $("omen-column").hidden = !feed.omen;
        set("omen", feed.omen || "");
      }

      $("links-section").hidden = page.links.length === 0;
      for (const link of page.links) {
        const a = document.createElement("a");
        a.href = link.url;
        a.textContent = link.label;
        const li = document.createElement("li");
        li.append(a);
        $("links").append(li);
      }
    })();
    </script>
    </body>
    </html>
  '';

  # Zen's chrome: only colour variables, no layout. They come from a user
  # sheet because Zen writes its workspace gradient, text and primary
  # colour inline on several of its own elements, and a user !important
  # beats inline styles; those few are set on every element.
  chrome = pkgs.writeText "rice-zen-chrome.css" ''
    @-moz-document url("chrome://browser/content/browser.xhtml") {
      :root, :root * {
        color-scheme: ${if dark then "dark" else "light"} !important;
        --zen-urlbar-background: ${t.bg.mantle} !important;
        --zen-urlbar-background-base: ${t.bg.mantle} !important;
        --zen-urlbar-background-transparent: ${t.bg.mantle} !important;
        --zen-main-browser-background: ${t.bg.sunken} !important;
        --zen-main-browser-background-toolbar: ${t.bg.sunken} !important;
        --zen-primary-color: ${t.accent.primary} !important;
        --toolbox-textcolor: ${t.fg.primary} !important;
      }
      :root {
        --toolbar-color-scheme: ${if dark then "dark" else "light"} !important;
        --zen-colors-primary: ${t.bg.surface1} !important;
        --zen-colors-secondary: ${t.bg.elevated} !important;
        --zen-colors-tertiary: ${t.bg.mantle} !important;
        --zen-colors-border: ${t.bg.surface1} !important;
        --zen-colors-border-contrast: ${t.bg.surface2} !important;
        --zen-colors-hover-bg: ${t.bg.elevated} !important;
        --zen-colors-input-bg: ${t.bg.sunken} !important;
        --zen-colors-primary-foreground: ${t.fg.primary} !important;
        --zen-themed-toolbar-bg-transparent: ${t.bg.sunken} !important;
        --zen-dialog-background: ${t.bg.mantle} !important;
        --toolbox-textcolor-inactive: ${t.fg.muted} !important;
        --toolbar-color: ${t.fg.primary} !important;
        --tab-selected-textcolor: ${t.fg.primary} !important;
        --tab-selected-outline-color: ${t.accent.primary} !important;
        --toolbar-field-background-color: ${t.bg.sunken} !important;
        --toolbar-field-focus-background-color: ${t.bg.mantle} !important;
        --toolbar-field-color: ${t.fg.primary} !important;
        --arrowpanel-background: ${t.bg.mantle} !important;
        --arrowpanel-color: ${t.fg.primary} !important;
        --arrowpanel-border-color: ${t.bg.surface1} !important;
        --focus-outline-color: ${t.accent.primary} !important;
      }
      .zen-current-workspace-indicator-name {
        font-family: "${fonts.display}", serif !important;
        color: ${t.accent.primary} !important;
      }
    }
  '';
in
{
  newtab = if settings != null then newtab else null;
  zenChrome = if lib.elem "zen" (theme.integration.tools or [ ]) then chrome else null;
}
