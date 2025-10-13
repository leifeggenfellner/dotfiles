{ pkgs, lib, colorScheme, ... }:

let
  # Access colors from your colorScheme config
  inherit (colorScheme) palette;

  catppuccin = {
    mauve = "#${palette.base0E}"; # Mauve / Magenta
    green = "#${palette.base0B}"; # Green
    red = "#${palette.base08}"; # Red
    blue = "#${palette.base0D}"; # Blue
    text = "#${palette.base05}"; # Text (main fg)
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

  system-cleanup = mkGumScript "system-cleanup" (with pkgs; [ gum nix docker sudo coreutils gnugrep ]) ''
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(gum style --foreground "$MAUVE" ' System')  Cleanup"

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
      /run/wrappers/bin/sudo -v
      while true; do /run/wrappers/bin/sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
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
            /run/wrappers/bin/sudo nix-collect-garbage --delete-older-than 3d
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
      "$(gum style --foreground "$MAUVE" ' Projects')  Launcher"

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
      "$(gum style --foreground "$GREEN" ' Project')  $PROJECT"

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
      "$(gum style --foreground "$MAUVE" ' Git')  Branch Switcher"

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

    # Show preview header
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(color_text '󱓊 Git') Commit Preview"

    echo ""

    # Show preview content
    gum style --foreground "$MAUVE" --bold "$FULL_SUMMARY"

    if [ -n "$BODY" ]; then
      echo ""
      gum style --foreground "$TEXT" "$BODY"
    fi

    if [ -n "$FOOTER" ]; then
      echo ""
      gum style --foreground "$BLUE" "$FOOTER"
    fi

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

  git-add-selector = mkGumScript "gadd" (with pkgs; [ gum git coreutils gawk gnugrep ]) ''
    # Check if we're in a git repository
    git rev-parse --git-dir >/dev/null 2>&1

    if [ $? -ne 0 ]; then
      echo "$(gum style --foreground "$RED" "󱓌") Not a $(color_text "git") repository"
      exit 1
    fi

    # Get the git root directory
    GIT_ROOT=$(git rev-parse --show-toplevel)

    # Header
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(color_text ' Git') File Selector"

    # Get list of modified, untracked, and deleted files (relative to git root)
    FILES=$(git -C "$GIT_ROOT" status --porcelain | awk '{print $2}')

    # Check if there are any files to add
    if [ -z "$FILES" ]; then
      echo "$(gum style --foreground "$GREEN" "󱓏") No files to add!"
      exit 0
    fi

    # Show current status
    echo ""
    gum style --foreground "$MAUVE" --bold "Current Status:"
    git status --short
    echo ""

    # Let user select files to add
    SELECTED=$(echo "$FILES" | gum choose --no-limit \
      --selected.foreground="$MAUVE" \
      --cursor.foreground="$BLUE" \
      --header="Select files to stage (Space to select, Enter to confirm):")

    # Check if any files were selected
    if [ -z "$SELECTED" ]; then
      echo "$(gum style --foreground "$YELLOW" "󰋼") No files selected"
      exit 0
    fi

    # Add selected files from git root
    echo ""
    echo "$SELECTED" | while IFS= read -r file; do
      git -C "$GIT_ROOT" add -- "$file" && \
      echo "$(gum style --foreground "$GREEN" "󱓏") Added: $(gum style --foreground "$TEXT" "$file")" || \
      echo "$(gum style --foreground "$RED" "󱓌") Failed to add: $(gum style --foreground "$TEXT" "$file")"
    done

    echo ""

    # Show updated status
    gum style --foreground "$MAUVE" --bold "Updated Status:"
    git status --short

    echo ""

    # Ask if user wants to commit
    if gum confirm \
      --default=true \
      --selected.foreground="$GREEN" \
      --unselected.foreground="$RED" \
      --prompt.foreground="$MAUVE" \
      "Commit these changes?"; then

      # Get commit message
      COMMIT_MSG=$(gum input \
        --prompt="$(gum style --foreground "$MAUVE" "󰏫 Commit message: ")" \
        --cursor.foreground="$BLUE" \
        --placeholder="Enter commit message" \
        --width=80)

      if [ -n "$COMMIT_MSG" ]; then
        git commit -m "$COMMIT_MSG" && \
        echo "$(gum style --foreground "$GREEN" "󱓏") Changes committed!"
      else
        echo "$(gum style --foreground "$YELLOW" "󰋼") No commit message provided. Skipping commit."
      fi
    else
      echo "$(gum style --foreground "$YELLOW" "󰋼") Commit skipped"
    fi
  '';

  git-log-viewer = mkGumScript "glog" (with pkgs; [ gum git coreutils gnused gawk ]) ''
    # Check if we're in a git repository
    git rev-parse --git-dir >/dev/null 2>&1

    if [ $? -ne 0 ]; then
      echo "$(gum style --foreground "$RED" "󱓌") Not a $(color_text "git") repository"
      exit 1
    fi

    # Header
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(color_text ' Git') Log Viewer"

    # Get number of commits to show
    LIMIT=$(gum input \
      --prompt="$(gum style --foreground "$MAUVE" "󰦨 Number of commits: ")" \
      --cursor.foreground="$BLUE" \
      --placeholder="50" \
      --value="50" \
      --width=20)

    # Default to 50 if empty
    LIMIT=''${LIMIT:-50}

    echo ""
    gum style --foreground "$BLUE" "󰁯 Loading commits..."
    echo ""

    # Get formatted log with hash, date, author, and message
    LOG=$(git log -n "$LIMIT" --pretty=format:"%h|%ar|%an|%s" | \
      awk -F'|' '{printf "%-8s %-20s %-25s %s\n", $1, $2, substr($3,1,25), $4}')

    # Let user select a commit
    SELECTED=$(echo "$LOG" | gum filter \
      --indicator.foreground="$MAUVE" \
      --match.foreground="$GREEN" \
      --placeholder="Search commits..." \
      --height=20)

    if [ -z "$SELECTED" ]; then
      echo "$(gum style --foreground "$YELLOW" "󰋼") No commit selected"
      exit 0
    fi

    # Extract commit hash (first word)
    COMMIT_HASH=$(echo "$SELECTED" | awk '{print $1}')

    clear

    # Show commit header
    gum style \
      --border rounded \
      --margin "1" \
      --padding "1 2" \
      --border-foreground "$MAUVE" \
      "$(color_text '󰜘 Commit') $COMMIT_HASH"

    echo ""

    # Show full commit details
    gum style --foreground "$MAUVE" --bold "Commit Details:"
    git show --stat --pretty=format:"%C(bold)Hash:%C(reset)    %H%n%C(bold)Author:%C(reset)  %an <%ae>%n%C(bold)Date:%C(reset)    %ar (%ai)%n%C(bold)Subject:%C(reset) %s%n" "$COMMIT_HASH" --color=always

    echo ""
    echo ""

    # Ask what to do with this commit
    ACTION=$(gum choose \
      --selected.foreground="$MAUVE" \
      --cursor.foreground="$BLUE" \
      --header="What would you like to do?" \
      "View full diff" \
      "Copy commit hash" \
      "Checkout this commit" \
      "Cherry-pick this commit" \
      "Revert this commit" \
      "Show files changed" \
      "Exit")

    case "$ACTION" in
      "View full diff")
        clear
        gum style \
          --border rounded \
          --margin "1" \
          --padding "1 2" \
          --border-foreground "$GREEN" \
          "$(gum style --foreground "$GREEN" '󰖷 Diff') $COMMIT_HASH"
        echo ""
        git show "$COMMIT_HASH" --color=always | less -R
        ;;

      "Copy commit hash")
        echo -n "$COMMIT_HASH" | xclip -selection clipboard 2>/dev/null || \
        echo -n "$COMMIT_HASH" | pbcopy 2>/dev/null || \
        echo -n "$COMMIT_HASH" | wl-copy 2>/dev/null || \
        echo "$COMMIT_HASH"
        echo "$(gum style --foreground "$GREEN" "󱓏") Copied $(color_text "$COMMIT_HASH") to clipboard"
        ;;

      "Checkout this commit")
        if gum confirm \
          --default=false \
          --selected.foreground="$GREEN" \
          --unselected.foreground="$RED" \
          --prompt.foreground="$MAUVE" \
          "Checkout commit $COMMIT_HASH? (detached HEAD)"; then
          git checkout "$COMMIT_HASH" && \
          echo "$(gum style --foreground "$GREEN" "󱓏") Checked out $(color_text "$COMMIT_HASH")"
        else
          echo "$(gum style --foreground "$YELLOW" "󰋼") Checkout cancelled"
        fi
        ;;

      "Cherry-pick this commit")
        if gum confirm \
          --default=true \
          --selected.foreground="$GREEN" \
          --unselected.foreground="$RED" \
          --prompt.foreground="$MAUVE" \
          "Cherry-pick commit $COMMIT_HASH?"; then
          git cherry-pick "$COMMIT_HASH" && \
          echo "$(gum style --foreground "$GREEN" "󱓏") Cherry-picked $(color_text "$COMMIT_HASH")" || \
          echo "$(gum style --foreground "$RED" "󱓌") Cherry-pick failed"
        else
          echo "$(gum style --foreground "$YELLOW" "󰋼") Cherry-pick cancelled"
        fi
        ;;

      "Revert this commit")
        if gum confirm \
          --default=false \
          --selected.foreground="$GREEN" \
          --unselected.foreground="$RED" \
          --prompt.foreground="$MAUVE" \
          "Revert commit $COMMIT_HASH?"; then
          git revert "$COMMIT_HASH" && \
          echo "$(gum style --foreground "$GREEN" "󱓏") Reverted $(color_text "$COMMIT_HASH")" || \
          echo "$(gum style --foreground "$RED" "󱓌") Revert failed"
        else
          echo "$(gum style --foreground "$YELLOW" "󰋼") Revert cancelled"
        fi
        ;;

      "Show files changed")
        clear
        gum style \
          --border rounded \
          --margin "1" \
          --padding "1 2" \
          --border-foreground "$BLUE" \
          "$(gum style --foreground "$BLUE" '󰈙 Files Changed') $COMMIT_HASH"
        echo ""
        git show --name-status --pretty=format:"" "$COMMIT_HASH" | grep -v '^$' | \
          while IFS= read -r line; do
            STATUS=$(echo "$line" | awk '{print $1}')
            FILE=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ //')
            case "$STATUS" in
              A) echo "$(gum style --foreground "$GREEN" "󰐕 $STATUS") $FILE" ;;
              M) echo "$(gum style --foreground "$BLUE" "󰏫 $STATUS") $FILE" ;;
              D) echo "$(gum style --foreground "$RED" "󰍶 $STATUS") $FILE" ;;
              R*) echo "$(gum style --foreground "$YELLOW" "󰁔 $STATUS") $FILE" ;;
              *) echo "$(gum style --foreground "$TEXT" "  $STATUS") $FILE" ;;
            esac
          done
        ;;

      "Exit")
        exit 0
        ;;
    esac
  '';
in
{
  inherit system-cleanup;
  inherit project-launcher;
  gswitch = git-switch;
  cm = git-commit-helper;
  gadd = git-add-selector;
  glog = git-log-viewer;
}
