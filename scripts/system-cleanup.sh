#!/usr/bin/env bash

MAUVE="#cba6f7"
GREEN="#a6e3a1"
RED="#f38ba8"

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
	echo "$(gum style --foreground "$RED" "󱟁") No tasks selected"
	exit 1
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
		"Old generations (keep last 3)")
			gum spin --title "Removing old generations..." -- \
				sudo nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system
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
echo "$(gum style --foreground "$GREEN" "") Cleanup completed!"
