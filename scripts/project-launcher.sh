#!/usr/bin/env bash

MAUVE="#cba6f7"
GREEN="#a6e3a1"
BLUE="#89b4fa"

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
	"$(gum style --foreground "$GREEN" ' Project')  $PROJECT"

echo ""
echo "$(gum style --foreground "$BLUE" "󰿄") Opening in $(gum style --foreground "$MAUVE" "$EDITOR")..."
$EDITOR .
