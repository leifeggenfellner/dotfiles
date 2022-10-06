export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(git up zsh-autosuggestions zsh-syntax-highlighting colored-man-pages command-not-found docker npm pip pyenv python sudo npm pip pyenv python sudo copypath)

source $ZSH/oh-my-zsh.sh
source $HOME/.aliases
source $HOME/.zprofile

colorscript -r

fpath=( ~/.zfuncs "${fpath[@]}" )
autoload -Uz $fpath[1]/*(.:t)

if command -v pyenv 1>/dev/null 2>&1; then
	eval "$(pyenv init -)"
fi

eval $(thefuck --alias fuck)

eval "$(starship init zsh)"
