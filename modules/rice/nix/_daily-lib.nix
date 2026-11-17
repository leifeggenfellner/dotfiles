# jq definitions shared by the shell-side consumers of the daily record
# (D-042, D-054): rice-query, rice-terminal and rice-hyprland-theme. The
# shell's DailyAccentController resolves the same way in QML.
#
#   segments                    "a.0.b" → ["a", 0, "b"]
#   daily_entry($record; $catalog; $today)
#                               today's catalog entry for a record
#                               { date, id?, index? } (by id, then position;
#                               `card` is the pre-D-042 position), or null
#   daily($prefs; $today)       manifest → today's widgets.dailyAccent entry
#   daily_accent($prefs; $today)
#                               manifest → that entry's accent, or null
#   with_daily_accent($prefs; $today)
#                               manifest with accent.primary replaced by it
''
  def segments: split(".") | map(if test("^[0-9]+$") then tonumber else . end);
  def daily_entry($record; $catalog; $today):
    if ($record | type) == "object" and $record.date == $today and ($catalog | type) == "array" then
      (if $record.id != null then ([$catalog[] | select(.id == $record.id)] | first) else null end)
      // (($record.index // $record.card) as $i
          | if ($i | type) == "number" and $i >= 0 and $i < ($catalog | length) then $catalog[$i] else null end)
    else null end;
  def daily($prefs; $today):
    (.widgets.dailyAccent.settings // null) as $s |
    if ($s | type) != "object" or ($s.record | type) != "string" or ($s.catalog | type) != "string" then null
    else daily_entry(($prefs | getpath($s.record | segments)); getpath($s.catalog | segments); $today) end;
  def daily_accent($prefs; $today):
    daily($prefs; $today) | if type == "object" then .accent else null end
    | if type == "string" and test("^#[0-9a-fA-F]{6}$") then . else null end;
  def with_daily_accent($prefs; $today):
    daily_accent($prefs; $today) as $accent |
    if $accent == null then . else .tokens.colors.accent.primary = $accent end;
''
