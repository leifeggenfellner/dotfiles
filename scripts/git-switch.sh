#!/usr/bin/env bash

MAUVE="#cba6f7"
GREEN="#a6e3a1"
RED="#f38ba8"

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
