#!/usr/bin/env bash

# Catppuccin Mocha colors
MAUVE="#cba6f7"
TEXT="#cdd6f4"
GREEN="#a6e3a1"
RED="#f38ba8"
BLUE="#89b4fa"

color_text() {
	gum style --foreground "$MAUVE" "$1"
}

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
	"$(color_text ' Git') Commit Helper"

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
