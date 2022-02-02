# .bashrc

# User specific aliases and functions

export PS1='\[\033[01;34m\]\w\[\033[00m\]\$ '
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

if [ -f ~/.profile ]; then . ~/.profile; fi
