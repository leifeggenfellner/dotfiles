#!/usr/bin/env bash

# Catppuccin Mocha colors
export GUM_INPUT_CURSOR_FOREGROUND="#89b4fa"
export GUM_INPUT_PROMPT_FOREGROUND="#cba6f7"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="#585b70"
export GUM_INPUT_FOREGROUND="#cdd6f4"

export GUM_CHOOSE_CURSOR_FOREGROUND="#89b4fa"
export GUM_CHOOSE_SELECTED_FOREGROUND="#cba6f7"
export GUM_CHOOSE_ITEM_FOREGROUND="#cdd6f4"

export GUM_CONFIRM_PROMPT_FOREGROUND="#cba6f7"
export GUM_CONFIRM_SELECTED_FOREGROUND="#a6e3a1"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#f38ba8"

export GUM_WRITE_PROMPT_FOREGROUND="#cba6f7"
export GUM_WRITE_PLACEHOLDER_FOREGROUND="#585b70"
export GUM_WRITE_CURSOR_FOREGROUND="#89b4fa"
export GUM_WRITE_FOREGROUND="#cdd6f4"

# Select commit type
TYPE=$(gum choose "feat" "fix" "docs" "style" "refactor" "perf" "test" "build" "ci" "chore" "revert" --header "Select commit type: 󱓊")

if [ -z "$TYPE" ]; then
  echo "No commit type selected. Exiting."
  exit 1
fi

# Enter commit message
MESSAGE=$(gum input --placeholder "Enter commit message" --prompt "> " --width 80)

if [ -z "$MESSAGE" ]; then
  echo "No commit message provided. Exiting."
  exit 1
fi

# Build the commit message
COMMIT_MSG="${TYPE}: ${MESSAGE}"

# Ask if body should be included (default: yes)
if gum confirm "Add body?" --default=true; then
  BODY=$(gum write --placeholder "Enter commit body (Ctrl+D to finish)" --width 80 --height 5)
  if [ -n "$BODY" ]; then
    COMMIT_MSG="${COMMIT_MSG}\n\n${BODY}"
  fi
fi

# Ask if footer should be included (default: no)
if gum confirm "Add footer?" --default=false; then
  FOOTER=$(gum write --placeholder "Enter footer (e.g., 'Fixes #123') (Ctrl+D to finish)" --width 80 --height 3)
  if [ -n "$FOOTER" ]; then
    COMMIT_MSG="${COMMIT_MSG}\n\n${FOOTER}"
  fi
fi

# Preview the commit message
echo ""
gum style --border rounded --padding "1 2" --border-foreground "#cba6f7" "$(echo -e "$COMMIT_MSG")"
echo ""

# Confirm commit
if gum confirm "Commit with this message?"; then
  echo -e "$COMMIT_MSG" | git commit -F -
  echo "✓ Committed successfully!" | gum style --foreground "#a6e3a1"
else
  echo "✗ Commit cancelled." | gum style --foreground "#f38ba8"
  exit 1
fi
