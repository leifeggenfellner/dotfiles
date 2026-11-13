{ pkgs }:
let
  packages = import ./_query-package.nix { inherit pkgs; };
  cyberManifest = pkgs.writeText "cyberpunk-manifest.json" (builtins.toJSON {
    meta = { name = "cyberpunk"; schemaVersion = 2; };
    tokens.colors.accent.primary = "#00e5ff";
  });
  lotmManifest = pkgs.writeText "lotm-manifest.json" (builtins.toJSON {
    meta = { name = "lotm"; schemaVersion = 2; };
    tokens.colors.accent.primary = "#c79a3a";
    widgets = {
      tarotDraw.settings.cards = [
        { id = "fool"; name = "The Fool"; sequence = "0"; }
        { id = "moon"; name = "The Moon"; sequence = "XVIII"; }
      ];
      terminal.settings = {
        greeting.daily = {
          record = "extras.tarotDraw.daily";
          catalog = "widgets.tarotDraw.settings.cards";
          format = "omen {sequence} {name}{missing}";
          pendingLabel = "face-down";
        };
        commandNotFound.format = "Unknown incantation: {command}";
      };
    };
  });
  index = pkgs.writeText "rice-themes.json" (builtins.toJSON {
    schemaVersion = 1;
    default = "cyberpunk";
    themes = {
      cyberpunk = { displayName = "Cyberpunk"; manifest = cyberManifest; wallpapers = [ ]; };
      lotm = { displayName = "LOTM"; manifest = lotmManifest; wallpapers = [ ]; };
    };
  });
  malformedIndex = pkgs.writeText "malformed-rice-themes.json" ''{"schemaVersion":1,"default":"missing","themes":{}}'';
in
pkgs.runCommand "rice-query"
{
  nativeBuildInputs = [ pkgs.shellcheck ];
} ''
  set -euo pipefail
  shellcheck -e SC2016 ${packages.riceQuery}/bin/rice-query
  shellcheck -e SC2016 ${packages.riceTerminal}/bin/rice-terminal

  query=${packages.riceQuery}/bin/rice-query
  terminal=${packages.riceTerminal}/bin/rice-terminal
  export HOME="$TMPDIR/home" XDG_STATE_HOME="$TMPDIR/state" RICE_INDEX=${index}
  mkdir -p "$XDG_STATE_HOME/rice"
  today="$(date +%F)"

  expect() {
    local expected="$1"; shift
    local actual
    actual="$("$@")"
    if [ "$actual" != "$expected" ]; then
      echo "expected '$expected' from $*, got '$actual'" >&2
      exit 1
    fi
  }
  expect_status() {
    local expected="$1"; shift
    local status=0
    "$@" > /dev/null 2>&1 || status=$?
    if [ "$status" != "$expected" ]; then
      echo "expected exit $expected from $*, got $status" >&2
      exit 1
    fi
  }

  # Pointer resolution: index default, valid pointer, unknown pointer.
  expect cyberpunk "$query" active
  expect '"cyberpunk"' "$query" --json active
  expect ${cyberManifest} "$query" manifest
  echo lotm > "$XDG_STATE_HOME/rice/active"
  expect lotm "$query" active
  echo bogus > "$XDG_STATE_HOME/rice/active"
  expect cyberpunk "$query" active
  echo lotm > "$XDG_STATE_HOME/rice/active"

  # get: raw strings, JSON values, array indices, unset and invalid paths.
  expect "The Moon" "$query" get widgets.tarotDraw.settings.cards.1.name
  expect '"The Moon"' "$query" --json get widgets.tarotDraw.settings.cards.1.name
  expect '{"id":"fool","name":"The Fool","sequence":"0"}' "$query" get widgets.tarotDraw.settings.cards.0
  expect_status 1 "$query" get widgets.nope
  expect_status 2 "$query" get widgets..nope
  expect_status 2 "$query" get .widgets
  expect_status 2 "$query" frobnicate

  # pref: missing file is unset; malformed file is an error.
  expect_status 1 "$query" pref extras
  printf '{"extras":{"tarotDraw":{"daily":{"date":"%s","id":"moon"}}}}' "$today" > "$XDG_STATE_HOME/rice/prefs.json"
  expect moon "$query" pref extras.tarotDraw.daily.id

  # greeting: by id, by index, legacy card field, stale date, no prefs.
  expect "omen XVIII The Moon" "$terminal" greeting
  printf '{"extras":{"tarotDraw":{"daily":{"date":"%s","id":"gone","index":0}}}}' "$today" > "$XDG_STATE_HOME/rice/prefs.json"
  expect "omen 0 The Fool" "$terminal" greeting
  printf '{"extras":{"tarotDraw":{"daily":{"date":"%s","card":1}}}}' "$today" > "$XDG_STATE_HOME/rice/prefs.json"
  expect "omen XVIII The Moon" "$terminal" greeting
  printf '{"extras":{"tarotDraw":{"daily":{"date":"2000-01-01","card":1}}}}' > "$XDG_STATE_HOME/rice/prefs.json"
  expect face-down "$terminal" greeting
  rm "$XDG_STATE_HOME/rice/prefs.json"
  expect face-down "$terminal" greeting

  # command-not-found ignores prefs entirely.
  echo garbage > "$XDG_STATE_HOME/rice/prefs.json"
  expect_status 2 "$query" pref extras
  expect_status 2 "$terminal" greeting
  expect "Unknown incantation: gti" "$terminal" command-not-found gti

  # Unconfigured theme: nothing rendered, exit 1 so callers fall back.
  echo cyberpunk > "$XDG_STATE_HOME/rice/active"
  expect_status 1 "$terminal" greeting
  expect_status 1 "$terminal" command-not-found gti

  # Broken environment.
  expect_status 2 env RICE_INDEX=${malformedIndex} "$query" active
  expect_status 2 env RICE_INDEX="$TMPDIR/missing.json" "$query" active
  printf '{}' > "$TMPDIR/mutable.json"
  expect_status 2 env RICE_INDEX="$TMPDIR/mutable.json" "$query" active

  # Read-only: nothing besides the fixtures this check wrote.
  test "$(find "$XDG_STATE_HOME/rice" -type f | sort | xargs -n1 basename | tr '\n' ' ')" = "active prefs.json "

  touch $out
''
