{ pkgs, lib, ... }:

let
  catppuccin = {
    mauve = "#cba6f7";
    green = "#a6e3a1";
    red = "#f38ba8";
    blue = "#89b4fa";
    text = "#cdd6f4";
  };

  mkGumScript = name: deps: text: pkgs.writeShellScriptBin name ''
    export PATH="${lib.makeBinPath deps}:$PATH"

    # Catppuccin Mocha colors
    MAUVE="${catppuccin.mauve}"
    GREEN="${catppuccin.green}"
    RED="${catppuccin.red}"
    BLUE="${catppuccin.blue}"
    TEXT="${catppuccin.text}"

    color_text() {
      gum style --foreground "$MAUVE" "$1"
    }

    ${text}
  '';

  system-cleanup = mkGumScript "system-cleanup" (with pkgs; [ gum nix docker sudo coreutils grep ]) ''
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(gum style --foreground "$MAUVE" ' System')  Cleanup"

    TASKS=$(gum choose --no-limit \
      --selected.foreground="$MAUVE" \
      --header="Select cleanup tasks:" \
      "Nix store optimization" \
      "Nix garbage collection" \
      "Old generations (keep last 3)" \
      "Docker cleanup" \
      "Clear package cache")

    if [ -z "$TASKS" ]; then
      echo "$(gum style --foreground "$RED" "✗") No tasks selected"
      exit 1
    fi

    # Check if any task needs sudo
    if echo "$TASKS" | grep -q "Old generations"; then
      echo "$(gum style --foreground "$MAUVE" "") Some tasks require sudo access..."
      sudo -v
      while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi

    echo ""

    while IFS= read -r task; do
      case "$task" in
        "Nix store optimization")
          gum spin --title "Optimizing Nix store..." -- nix-store --optimise
          ;;
        "Nix garbage collection")
          gum spin --title "Running garbage collection..." -- nix-collect-garbage
          ;;
        "Old generations (keep last 3 days)")
          gum spin --title "Removing old generations..." -- \
            sudo nix-collect-garbage --delete-older-than 3d
          ;;
        "Docker cleanup")
          gum spin --title "Cleaning Docker..." -- docker system prune -af
          ;;
        "Clear package cache")
          gum spin --title "Clearing cache..." -- rm -rf ~/.cache/nix
          ;;
      esac
    done <<< "$TASKS"

    echo ""
    echo "$(gum style --foreground "$GREEN" "") Cleanup completed!"
  '';

  project-launcher = mkGumScript "project-launcher" (with pkgs; [ gum findutils gnused coreutils ]) ''
    PROJECTS_DIR="$HOME/workspace"

    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(gum style --foreground "$MAUVE" ' Projects')  Launcher"

    PROJECT=$(find "$PROJECTS_DIR" -maxdepth 2 -type d -name ".git" | \
      sed "s|$PROJECTS_DIR/||;s|/.git||" | \
      gum filter --placeholder="Search projects..." \
      --indicator.foreground="$MAUVE")

    if [ -z "$PROJECT" ]; then
      exit 1
    fi

    clear

    cd "$PROJECTS_DIR/$PROJECT" || exit 1

    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$GREEN" \
      "$(gum style --foreground "$GREEN" ' Project')  $PROJECT"

    echo ""
    echo "$(gum style --foreground "$BLUE" "󰿄") Opening in $(gum style --foreground "$MAUVE" "$EDITOR")..."
    $EDITOR .
  '';

  git-switch = mkGumScript "gswitch" (with pkgs; [ gum git ]) ''
    git rev-parse --git-dir >/dev/null 2>&1 || {
      echo "$(gum style --foreground "$RED" "󱓌") Not a git repository"
      exit 1
    }

    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(gum style --foreground "$MAUVE" ' Git')  Branch Switcher"

    BRANCH=$(git branch --format="%(refname:short)" | \
      gum filter --placeholder="Search branches..." \
      --indicator.foreground="$MAUVE" \
      --match.foreground="$GREEN")

    if [ -n "$BRANCH" ]; then
      git switch "$BRANCH" && \
      echo "$(gum style --foreground "$GREEN" "󱓏") Switched to $BRANCH"
    else
      echo "$(gum style --foreground "$RED" "󱓌") No branch selected"
    fi
  '';

  git-commit-helper = mkGumScript "cm" (with pkgs; [ gum git coreutils ]) ''
    # Check if we're in a git repository
    git rev-parse --git-dir >/dev/null 2>&1

    if [ $? -ne 0 ]; then
      echo "$(gum style --foreground "$RED" "󱓌") Must be run in a $(color_text "git") repository"
      exit 1
    fi

    # Header
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(color_text ' Git') Commit Helper"

    # Select commit type
    TYPE=$(gum choose \
      --selected.foreground="$MAUVE" \
      --cursor.foreground="$BLUE" \
      --header="Select commit type:" \
      "feat" "fix" "docs" "style" "refactor" "perf" "test" "build" "ci" "chore" "revert")

    if [ -z "$TYPE" ]; then
      echo "$(gum style --foreground "$RED" "󱓌") No commit type selected"
      exit 1
    fi

    # Enter commit message
    SUMMARY=$(gum input \
      --prompt="$(color_text "$TYPE: ")" \
      --prompt.foreground="$MAUVE" \
      --cursor.foreground="$BLUE" \
      --placeholder="Summary of this change" \
      --width=80)

    if [ -z "$SUMMARY" ]; then
      echo "$(gum style --foreground "$RED" "󱓌") No commit message provided"
      exit 1
    fi

    # Build commit message
    FULL_SUMMARY="$TYPE: $SUMMARY"

    # Ask for body (default: yes)
    BODY=""
    if gum confirm \
      --default=true \
      --selected.foreground="$GREEN" \
      --unselected.foreground="$RED" \
      --prompt.foreground="$MAUVE" \
      "Add body?"; then
      BODY=$(gum write \
        --placeholder="Details of this change (CTRL+D to finish)" \
        --cursor.foreground="$BLUE" \
        --width=80 \
        --height=8)
    fi

    # Ask for footer (default: no)
    FOOTER=""
    if gum confirm \
      --default=false \
      --selected.foreground="$GREEN" \
      --unselected.foreground="$RED" \
      --prompt.foreground="$MAUVE" \
      "Add footer?"; then
      FOOTER=$(gum write \
        --placeholder="Footer (e.g., 'Fixes #123') (CTRL+D to finish)" \
        --cursor.foreground="$BLUE" \
        --width=80 \
        --height=3)
    fi

    # Clear screen and show preview
    clear

    # Build preview content
    PREVIEW_CONTENT="$(gum style --foreground "$MAUVE" --bold "$FULL_SUMMARY")"

    if [ -n "$BODY" ]; then
      PREVIEW_CONTENT="$PREVIEW_CONTENT"$'\n\n'"$(gum style --foreground "$TEXT" "$BODY")"
    fi

    if [ -n "$FOOTER" ]; then
      PREVIEW_CONTENT="$PREVIEW_CONTENT"$'\n\n'"$(gum style --foreground "$BLUE" "$FOOTER")"
    fi

    # Show preview in same style as header
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(color_text '󱓊 Git') Commit Preview"$'\n\n'"$PREVIEW_CONTENT"

    echo ""

    # Commit
    if [ -z "$BODY" ] && [ -z "$FOOTER" ]; then
      gum confirm \
        --default=true \
        --selected.foreground="$GREEN" \
        --unselected.foreground="$RED" \
        --prompt.foreground="$MAUVE" \
        "Commit changes?" && \
      git commit -m "$FULL_SUMMARY" && \
      echo "$(gum style --foreground "$GREEN" "󱓏") Committed successfully!"
    elif [ -z "$FOOTER" ]; then
      gum confirm \
        --default=true \
        --selected.foreground="$GREEN" \
        --unselected.foreground="$RED" \
        --prompt.foreground="$MAUVE" \
        "Commit changes?" && \
      git commit -m "$FULL_SUMMARY" -m "$BODY" && \
      echo "$(gum style --foreground "$GREEN" "󱓏") Committed successfully!"
    else
      gum confirm \
        --default=true \
        --selected.foreground="$GREEN" \
        --unselected.foreground="$RED" \
        --prompt.foreground="$MAUVE" \
        "Commit changes?" && \
      git commit -m "$FULL_SUMMARY" -m "$BODY" -m "$FOOTER" && \
      echo "$(gum style --foreground "$GREEN" "󱓏") Committed successfully!"
    fi

    if [ $? -ne 0 ]; then
      echo "$(gum style --foreground "$RED" "󱓌") Commit cancelled or failed"
      exit 1
    fi
  '';

in
{
  system-cleanup = system-cleanup;
  project-launcher = project-launcher;
  git-switch = git-switch;
  git-commit-helper = git-commit-helper;
}
