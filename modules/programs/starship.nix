_: {
  flake.homeModules.programs-starship =
    { lib, ... }:
    let
      lang = icon: color: {
        symbol = icon;
        format = "[$symbol ](${color})";
      };
    in
    {
      programs.starship = {
        enable = true;
        settings = {
          add_newline = true;
          format = lib.strings.concatStrings [
            "$directory"
            "$container"
            "$git_branch $git_status"
            "$python"
            "$nodejs"
            "$lua"
            "$rust"
            "$java"
            "$c"
            "$golang"
            "$cmd_duration"
            "$status"
            "\n$character"
          ];
          status = {
            symbol = "✗";
            not_found_symbol = "󰍉 Not Found";
            not_executable_symbol = " Can't Execute E";
            sigint_symbol = "󰂭 ";
            signal_symbol = "󱑽 ";
            success_symbol = "";
            format = "[$symbol](fg:red)";
            map_symbol = true;
            disabled = false;
          };
          cmd_duration = {
            min_time = 1000;
            format = "[$duration ](fg:yellow)";
          };
          character = {
            success_symbol = "[❯](bold purple)";
            error_symbol = "[❯](bold red)";
          };
          container = {
            symbol = " 󰏖";
            format = "[$symbol ](yellow dimmed)";
          };
          directory = {
            format = " [](fg:bright-black)[$path](bg:bright-black fg:white)[](fg:bright-black)";
            truncation_length = 4;
            truncation_symbol = "~/…/";
          };
          directory.substitutions = {
            "Documents" = " ";
            "Downloads" = " ";
            "Music" = " ";
            "Pictures" = " ";
            "Videos" = " ";
            "Projects" = "󱌢 ";
            "School" = "󰑴 ";
            "GitHub" = "";
            ".config" = " ";
            "Workflow" = "󱌢 ";
          };
          git_branch = {
            symbol = "";
            style = "";
            format = "[ $symbol $branch](fg:purple)(:$remote_branch)";
          };
          python = lang "" "yellow";
          nodejs = lang " " "yellow";
          lua = lang "󰢱" "blue";
          rust = lang "" "red";
          java = lang "" "red";
          c = lang "" "blue";
          golang = lang "" "blue";
        };
      };
    };
}
