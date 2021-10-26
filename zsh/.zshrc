export TERM="xterm-256color"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH=/home/$USER/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
export ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=1

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git catimg command-not-found common-aliases node npm pip python sudo supervisor golang archlinux colorize cp docker-compose git-flow github systemd vscode kubectl)

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# export POWERLEVEL9K_MODE="awesome-fontconfig"
export POWERLEVEL9K_PROMPT_ON_NEWLINE=true
export POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
export POWERLEVEL9K_BATTERY_VERBOSE=true
export POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="↱"
export POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="↳ "

export POWERLEVEL9K_MODE="nerdfont-complete"
export POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(root_indicator context dir rbenv vcs nodeenv virtualenv anaconda pyenv)
export POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs history battery time)
export POWERLEVEL9K_CONTEXT_TEMPLATE=$'\ue795'
export POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='201'
export POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND='017'
export POWERLEVEL9K_DIR_HOME_FOREGROUND='044'
export POWERLEVEL9K_DIR_HOME_BACKGROUND='025'
export POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND='044'
export POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND='025'
export POWERLEVEL9K_DIR_ETC_FOREGROUND='044'
export POWERLEVEL9K_DIR_ETC_BACKGROUND='025'
export POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='044'
export POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='025'
export POWERLEVEL9K_STATUS_OK_BACKGROUND='017'
export POWERLEVEL9K_HISTORY_BACKGROUND='013'
export POWERLEVEL9K_HISTORY_FOREGROUND='044'
export POWERLEVEL9K_TIME_BACKGROUND='201'
export POWERLEVEL9K_TIME_FOREGROUND='255'
export POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'

eval "$(thefuck --alias)"
# You can use whatever you want as an alias, like for Mondays:
eval "$(thefuck --alias fuck)"

source $ZSH/oh-my-zsh.sh

source $HOME/.aliases

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

# If it's a zsh terminal session, use curses for pinentry over the default GUI
GPG_TTY=$(tty)
export GPG_TTY
export PINENTRY_USER_DATA="curses"

# Use vscodium when code is run
alias code='codium'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

