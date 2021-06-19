export PAGER="less"
## use termcap magic to highlight mandoc
# command or paragraph title, 'b' of 'mb' means blink
export LESS_TERMCAP_mb=$'\e[1;32m'   # bold, green
export LESS_TERMCAP_md=$'\e[1;32m'   # bold, green
export LESS_TERMCAP_me=$'\e[0m'      # normal
# search keyword
export LESS_TERMCAP_so=$'\e[30;47m'  # black with background white
export LESS_TERMCAP_se=$'\e[0m'      # normal
# link, email, some subcommand or option value
export LESS_TERMCAP_us=$'\e[1;4;31m' # bold, underlined, red
export LESS_TERMCAP_ue=$'\e[0m'      # normal
export MANPAGER="less"
export MANPATH="/usr/local/share/man:$MANPATH"

export TERM="screen-256color"

# config language environment
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

export EDITOR="vim"
export UNISON="/root/.unison"

# the number of commands stored in Bash History
export HISTSIZE=10000
alias historyc='echo "" > $HISTFILE & exec $SHELL -l'

## User specific aliases and functions
alias rm='trash'
alias cp='cp -i'
alias mv='mv -i'
alias ncdu='ncdu --color=dark'
alias ls='ls --color'
alias l='ls -alh'
alias lt='ls -ltr'
alias vi='vim'
alias df='df -h'
alias grep="grep --color"
alias opent="open -a 'Sublime Text'"
alias opena="open -a 'Aquamacs'"
alias opend="[ ! -f /tmp/A.txt ] && touch /tmp/A.txt; [ ! -f /tmp/B.txt ] && touch /tmp/B.txt; /usr/local/bin/ksdiff /tmp/A.txt /tmp/B.txt; open -a 'Sublime Text' /tmp/A.txt /tmp/B.txt"
alias diff="ksdiff"
alias ldd="otool -L"

# help doc for builtin commands
function help() {
    case "$(basename $SHELL)" in
        zsh)
            man zshbuiltins | less -p "^       $1 "
            ;;
        bash)
            man bash | less -p "^       $1 "
            ;;
        *)
            echo "Only support zsh/bash"
            ;;
    esac
}

# cd to ancestor with depth n
function mcd() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='mcd'
alias 'cdm'='mcd'

# update indexes of command `locate`
alias updatedb="sudo /usr/libexec/locate.updatedb"

alias redis-cli="rlwrap redis-cli --raw"
alias qrencode="qrterminal"
alias qrdecode="zbarimg"
alias hcat="source-highlight --out-format=esc -o STDOUT -i"
alias pycat='pygmentize -g -O style=emacs'

# convenient uncompress package commands
alias unrar='rar x'
alias untar='tar -xf'
alias untargz='tar -xzf'
alias untarbz2='tar -xjf'
function untarxz() {
    if [ -z $1 ]; then
        echo "Usage: untarxz [package.tar.xz], example: untarxz package.tar.xz";
    else
        unxz $1 | tar -xf -;
    fi
}
function un7z() {
    if [ -z $1 ]; then
        echo "Usage: 7za x [package.7z]";
    else
        echo "will unpack to path: ${1%.7z}";
        7za x $1 "-o${1%.7z}";
    fi
}

# find process who is using the port
function port() {
    if [ -z $1 ]; then
        echo "Usage: port [port], example: port 6379";
    else
        local port=$1;
        sudo lsof -i:$port | grep -v "PID";
    fi
}
function whichport () {
    if [ -z $1 ]; then
        echo "Get the ports of process is using.";
        echo "Usage: whichport [port]";
    else
        local port1="$1";
        local test1=`sudo lsof -i:$port1 | grep -v "PID" | awk '{print$2}'`;
        if [ -z $test1 ]; then
            echo "There is no process use port $port1";
        else
            ps aux | grep --color -v "grep" | grep --color "`sudo lsof -i:$port1 | grep -v "PID" | awk '{print$2}'`";
        fi;
    fi
}

#function title () {
#    echo -e '\033k'$1'\033\\';
#}
alias title="printf '\033]0;%s\007'"

export notifier=$HOME/Library/Workflows/Notification.workflow
function notify () {
    if [ -z $1 ]; then
        echo "Usage: notify \"I'm message\"";
        echo "Usage: notify \"I'm message\" \"I'm title\"";
        echo "Usage: notify \"I'm message\" \"I'm title\" \"I'm subtitle\"";
    else
        if [ -z $2 ]; then
            automator -D message="$1" "$notifier" > /dev/null 2>&1;
        else
            if [ -z $3 ]; then
                automator -D title="$1" -D message="$2" "$notifier" > /dev/null 2>&1;
            else
                automator -D title="$1" -D subtitle="$2" -D message="$3" "$notifier" > /dev/null 2>&1;
            fi;
        fi;
    fi
}

# wait some time and send notification
function timeout() {
    # handle parameters
    if [ -z "$1" ]; then
        local minutes=5;
    else
        local minutes=$1;
    fi
    local message="$2";
    if [ -z "$2" ]; then
        local message_prefix="without message";
    else
        local message_prefix="with message:";
    fi

    echo "Timeout ${minutes}m $message_prefix $message";
    for i in $(seq $(($minutes*60)) -1 1); do 
        printf "\r%02d:%02d:%02d" $((i/3600)) $(( (i/60)%60)) $((i%60)); 
        sleep 1;
    done
    printf "\n";
    /usr/local/bin/terminal-notifier -title "Timeout ${minutes}m" -message "$message"
}

# kill process by name of process ;; TODO how about `killall`
function killbyname () {
    if [ -z $1 ]; then
        echo "Usage: killbyname [name of process]";
    else
        local name=$1;
        ps aux | grep --color "$name" | grep --color -v "grep" | awk '{print $2}' | xargs sudo kill -9;
    fi
}

# ls with grep
function lsg () {
    ls | grep "$1";
}

# ls with grep
function lg () {
    ls -alh | grep "$1";
}

# get length of string
function length () {
    local var1=$1;
    echo "${#var1}"
}
alias len="length"

function append_path () {
    if ! eval test -z "\"\${$1##*:$2:*}\"" -o -z "\"\${$1%%*:$2}\"" -o -z "\"\${$1##$2:*}\"" -o -z "\"\${$1##$2}\""; then
        eval "$1=\$$1:$2";
    fi
}
function prepend_path () {
    if ! eval test -z "\"\${$1##*:$2:*}\"" -o -z "\"\${$1%%*:$2}\"" -o -z "\"\${$1##$2:*}\"" -o -z "\"\${$1##$2}\""; then
        eval "$1=$2:\$$1";
    fi
}

function randompassword() {
    if [ -z "$1" ]; then
        local length=16;
    else
        local length="$1";
    fi
    LC_ALL=C tr -dc "[:alnum:]" < /dev/urandom | head -c $length | pbcopy;
    echo "Random password with length $length has been copied to clipboard"
}

# tree with replace of empty string
function tree () {
    /usr/local/bin/tree "$@" | sed "s/聽/ /g" | ascii2uni -a K
}

##########################################################
## integrate with Finder

# cd to current directory in Finder
function cdf () {
    local path="`osascript -e 'tell application "Finder" to set myname to POSIX path of (target of window 1 as alias)' 2>/dev/null`";
    if [ -n "$path" ]; then
        echo "\e[32mcd $path\e[0m";
        cd "$path";
    else
        echo "Finder window finded";
    fi;
}

# return selected paths in Finder
function finder_selected_paths () {
    echo "`osascript \
               -e 'tell application \"Finder\"' \
               -e '    set selected_paths to selection as alias list' \
               -e '    repeat with selected_path in selected_paths' \
               -e '        set contents of selected_path to POSIX path of (contents of selected_path)' \
               -e '    end repeat' -e 'set text item delimiters of AppleScript to linefeed' \
               -e '    return selected_paths as text' \
               -e 'end tell' 2>/dev/null`";
}

# return selected files in Finder
function finder_selected_files () {
    echo "`osascript \
               -e 'tell application \"Finder\"' \
               -e '    set selected_files to {}' \
               -e '    set selected_paths to selection as alias list' \
               -e '    repeat with selected_path in selected_paths' \
               -e '        set contents of selected_path to POSIX path of contents of selected_path' \
               -e '        if contents of selected_path does not end with \"/\" then' \
               -e '            set the end of selected_files to contents of selected_path' \
               -e '        end if' \
               -e '    end repeat' \
               -e '    set text item delimiters of AppleScript to linefeed' \
               -e '    return selected_files as text' \
               -e 'end tell' 2>/dev/null`";
}

## return selected files in Finder
function finder_selected_dirs () {
    echo "`osascript \
               -e 'tell application \"Finder\"' \
               -e '    set selected_files to {}' \
               -e '    set selected_paths to selection as alias list' \
               -e '    repeat with selected_path in selected_paths' \
               -e '        set contents of selected_path to POSIX path of contents of selected_path' \
               -e '        if contents of selected_path end with \"/\" then' \
               -e '            set the end of selected_files to contents of selected_path' \
               -e '        end if' \
               -e '    end repeat' \
               -e '    set text item delimiters of AppleScript to linefeed' \
               -e '    return selected_files as text' \
               -e 'end tell' 2>/dev/null`";
}

alias ff="finder_selected_files"
alias fp="finder_selected_paths"
alias fd="finder_selected_dirs"

# rm current selected files/directories in Finder
function rmf () {
    local paths=`finder_selected_paths`;
    if [ -n "$paths" ]; then
        echo "selected files/directories:\n\e[32m$paths\e[0m\n";
        echo -n "should rm -rf above paths(y/n/sudo)? "
        read answer
        if [ "$answer" != "${answer#[Yy]}" ]; then
            OIFS="$IFS";
            IFS=";;;;;";
            for i in $(echo $paths | tr "\n" ";;;;;"); do
                if [[ -n "$i" ]]; then
                    echo "\e[32mrm -rf $i\e[0m";
                    /bin/rm -rf "$i";
                fi;
            done;
            IFS="$OIFS";
        elif [ "$answer" = "sudo" ]; then
            OIFS="$IFS";
            IFS=";;;;;";
            for i in $(echo $paths | tr "\n" ";;;;;"); do
                if [[ -n "$i" ]]; then
                    echo "\e[32msudo rm -rf $i\e[0m";
                    sudo /bin/rm -rf "$i";
                fi;
            done;
            IFS="$OIFS";
        fi;
    else
        echo "Please select files/directories in Finder first!"
    fi;
}

# generate md/hash of selected files in Finder
function hashf () {
    local paths=`finder_selected_files`;
    if [ -n "$paths" ]; then
        echo "selected files/directories:\n\e[32m$paths\e[0m\n";
        local message_digest="";
        if [ -z "$1" ]; then
            echo -n "should openssl md above paths(md5/sha1/sha256/...)? ";
            read message_digest;
            if [ -z "$message_digest" ]; then
                message_digest="sha1";
            fi;
        else
            message_digest="$1";
        fi;
        if [ ! -z "$message_digest" ]; then
            OIFS="$IFS";
            IFS=";;;;;";
            for i in $(echo $paths | tr "\n" ";;;;;"); do
                if [[ -n "$i" ]]; then
                    echo "\e[32mopenssl $message_digest $i\e[0m";
                    openssl $message_digest "$i";
                fi;
            done;
            IFS="$OIFS";
        else
            echo "Usage: hashf [ md5 | sha1 | sha256 | ... ]";
        fi;
    else
        echo "Please select files/directories in Finder first!"
    fi;
}
alias mdf="hashf"

# convert selected files in Finder from charset A to B
function iconvf () {
    local paths=`finder_selected_files`;
    if [ -n "$paths" ]; then
        echo "selected files/directories:\n\e[32m$paths\e[0m\n";

        local from_charset="";
        if [ -z "$1" ]; then
            echo -n "should iconv above paths from(gbk/...)? ";
            read from_charset;
            if [ -z "$from_charset" ]; then
                from_charset="gbk";
            fi;
        else
            from_charset="$1";
        fi;

        local to_charset="";
        if [ -z "$2" ]; then
            echo -n "should iconv above paths to(utf8/...)? ";
            read to_charset;
            if [ -z "$to_charset" ]; then
                to_charset="utf8";
            fi;
        else
            to_charset="$2";
        fi;
        if [ ! -z "$to_charset" ]; then
            OIFS="$IFS";
            IFS=";;;;;";
            for i in $(echo $paths | tr "\n" ";;;;;"); do
                if [[ -n "$i" ]]; then
                    echo "\e[32miconv -f $from_charset -t $to_charset $i > ${i%%.*}.$to_charset.${i##*.}\e[0m";
                    iconv -f $from_charset -t $to_charset "$i" > "${i%.*}.$to_charset.${i##*.}";
                fi;
            done;
            IFS="$OIFS";
        else
            echo "Usage: iconvf [ gbk | ... ] [ utf8 | ... ]";
        fi;
    else
        echo "Please select files/directories in Finder first!"
    fi;
}

##########################################################
## Network related

# alias urldecode='python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])"'
# alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1])"'

function urlencode () {
    if [ -z "$1" ]; then
        # read only 1 line from STDIN without EOF
        python -c "import sys, urllib as ul; print ul.quote_plus(sys.stdin.readline()[:-1])"
    else
        # use parameter
        python -c "import sys, urllib as ul; print ul.quote_plus(\"$1\")"
    fi;
}

## Query movie info from movie.douban.com
#    Note: require xargs, node, nightmare(install with npm), pup & jq
function movie () {
    echo "$1" | urlencode \
              | xargs -I NAME \
                  node -e "const Nightmare = require('nightmare'); const nightmare = new Nightmare({waitTimeout: 5000}); nightmare.goto(process.argv[1]).wait('.item-root').evaluate(() => {return document.body.outerHTML;}).end().then(body_html => {console.log(body_html);});" \
                       "https://search.douban.com/movie/subject_search?search_text=NAME&cat=1002" \
              | pup '.item-root json{}' \
              | jq 'map({"title": .children[1].children[0].children[0].text, "rating": .children[1].children[1].children[1].text, "meta_abstract": .children[1].children[2].text, "meta_abstract2": .children[1].children[3].text, "url": .children[1].children[0].children[0].href, "image": .children[0].children[0].src})'
}

## Query movie info from m.douban.com
#    Note: require xargs, curl, pup & jq
function movie_small () {
    echo "$1" | urlencode \
              | xargs -I NAME curl -s "https://m.douban.com/search/?query=NAME&type=movie" \
              | pup '.search_results_subjects li > a json{}' \
              | jq 'map({"src": ("https://m.douban.com" + .href), "title": .children[1].children[0].text, "rating": .children[1].children[1].children[-1].text})'
}
function movie_without_link () {
    echo "$1" | urlencode \
              | xargs -I NAME curl -s "https://m.douban.com/search/?query=NAME&type=movie" \
              | pup '.search_results_subjects li > a > .subject-info json{}' \
              | jq 'map({"title": .children[0].text, "rating": .children[1].children[-1].text})'
}

## Query book info from movie.douban.com
#    Note: require xargs, node, nightmare(install with npm), pup & jq
function book () {
    echo "$1" | urlencode \
              | xargs -I NAME \
                  node -e "const Nightmare = require('nightmare'); const nightmare = new Nightmare({waitTimeout: 5000}); nightmare.goto(process.argv[1]).wait('.item-root').evaluate(() => {return document.body.outerHTML;}).end().then(body_html => {console.log(body_html);});" \
                       "https://search.douban.com/book/subject_search?search_text=NAME&cat=1001" \
              | pup '.item-root json{}' \
              | jq 'map(select(.children[1].children[0].children[0].text != null)) | map({"title": .children[1].children[0].children[0].text, "rating": .children[1].children[1].children[1].text, "meta_abstract": .children[1].children[2].text, "url": .children[1].children[0].children[0].href, "image": .children[0].children[0].src})'
}

## Query book info from m.douban.com
#    Note: require xargs, curl, pup & jq
function book_without_link () {
    echo "$1" | urlencode \
              | xargs -I NAME curl -s "https://m.douban.com/search/?query=NAME&type=book" \
              | pup '.search_results_subjects li > a > .subject-info json{}' \
              | jq 'map({"title": .children[0].text, "rating": .children[1].children[-1].text})'
}

#########################################################
## Git configuration
function arcpatch() {
    if [ -z $1 ]; then
        echo "Usage: arcpatch [Diff], example: arcpatch D4309";
    else
        git checkout master && git pull && git branch | grep arcpatch | xargs git branch -D && arc patch $1;
    fi
}

export GIT_TERMINAL_PROMPT=1
function gittag() {
    if [ -z $1 ]; then
        echo "Usage: gittag [Task-ID], example: gittag T0001";
    else
        git tag -a PRD_$1 && git push origin --tags
    fi
}

########################################################
## Homebrew configuration
export HOMEBREW_NO_AUTO_UPDATE=1 # do NOT update homebrew every time

########################################################
## debug WAP with UC browser(through USB)
# link Android Phone to PC/Mac with USB
alias ucinspect="adb forward tcp:9998 tcp:9998" 
# execute `ucinspect`
# then visit URL `http://localhost:9998/` with Chrome/Safari and debug

export PATH="/Library/StartupItems/MySQLCOM:/usr/local/mysql/bin:/opt/X11/bin:$HOME/.roswell/bin:$HOME/git/arcanist/bin:/usr/local/bin/z_tools:/usr/local/sbin:$PATH"
export DYLD_LIBRARY_PATH="/usr/local/cuda/lib:$DYLD_LIBRARY_PATH"

########################################################
## Proxy config
# TODO ShadowVPN still available??
alias shadowvpnon="sudo shadowvpn -c /etc/shadowvpn/client.conf -s start"
alias shadowvpnoff="sudo shadowvpn -c /etc/shadowvpn/client.conf -s stop"
alias gfw="proxychains4 -q -f /etc/proxychains.conf"

# enable Gmail proxy in Mail
function gmail() {
    case "$1" in
        start|enable|on)
            # enable Gmail in Mail(require password)
            proximac start -c /etc/proximac.conf -d;
            open -a "Mail";
            ;;
        stop|disable|off)
            # disable Gmail in Mail
            pkill "Mail";
            proximac stop;
            ;;
        *)
            echo "Usage:";
            echo "  enable Gmail:  gmail [start | enable | on]";
            echo "  disable Gmail: gmail [stop | disable | off]";
            ;;
    esac
}

function proxy() {
    if [ -z "$1" ]; then
        local command="status";
    else
        local command="$1";
    fi;
    case "${command}" in
        enable|on)
            if [ -z "$2" ]; then
                local proxy_url="http://127.0.0.1:1087";
            else
                local proxy_url="$2";
            fi;
            export http_proxy="${proxy_url}"
            export HTTP_PROXY="${proxy_url}"
            export https_proxy="${proxy_url}"
            export HTTPS_PROXY="${proxy_url}"
            export ALL_PROXY="${proxy_url}"
            echo "HTTP/HTTPS proxy enabled, proxy URL: ${proxy_url}"
            ;;
        disable|off)
            unset http_proxy
            unset HTTP_PROXY
            unset https_proxy
            unset HTTPS_PROXY
            unset ALL_PROXY
            echo "HTTP/HTTPS proxy disabled."
            ;;
        status)
            echo http_proxy="${http_proxy}"
            echo HTTP_PROXY="${HTTP_PROXY}"
            echo https_proxy="${https_proxy}"
            echo HTTPS_PROXY="${HTTPS_PROXY}"
            echo ALL_PROXY="${ALL_PROXY}"
            ;;
        -h|--help)
            echo "usage: $0 [ status | enable | on | disable | off ] [<proxy URL>]*"
            ;;
        *)
            echo "usage: $0 [ status | enable | on | disable | off ] [<proxy URL>]*"
            ;;
    esac
}

function git_proxy() {
    if [ -z "$1" ]; then
        local command="status";
    else
        local command="$1";
    fi;
    case "${command}" in
        enable|on)
            if [ -z "$2" ]; then
                local proxy_url="socks5h://127.0.0.1:1080";
            else
                local proxy_url="$2";
            fi;
            git config --global http.proxy "${proxy_url}"
            echo "Git HTTP/HTTPS proxy enabled, proxy URL: ${proxy_url}"
            ;;
        disable|off)
            git config --global --unset http.proxy
            echo "Git HTTP/HTTPS proxy disabled."
            ;;
        status)
            echo git config --global http.proxy: `git config --global http.proxy`
            ;;
        -h|--help)
            echo "usage: $0 [ status | enable | on | disable | off ] [<proxy URL>]*"
            ;;
        *)
            echo "usage: $0 [ status | enable | on | disable | off ] [<proxy URL>]*"
            ;;
    esac
}

########################################################
# DNS configuration

dns() {
    case "$1" in
        *)
            echo "refreshing DNS config..."
            set -x
            sudo killall -HUP mDNSResponder;
            # sudo killall mDNSResponderHelper; # useless on macOS 10.14
            sudo dscacheutil -flushcache;
            ;;
    esac
}

########################################################
## Common Lisp configuration
alias ros="rlwrap ros"
alias sbcl="rlwrap sbcl"
alias gdbsbcl="sudo gdb `which sbcl` `ps aux | grep -v grep | grep -v gdb | grep sbcl | awk '{print $2}'`"
function sbclt() {
    if [ -z $1 ]; then
        echo "Usage: sbclt [system to be test]";
        echo "  Example: sbclt cl-ssdb"
    else
        echo sbcl --noinform --eval "(asdf:test-system '$1)" --quit
        sbcl --noinform --eval "(asdf:test-system '$1)" --quit
    fi
}
alias ccl="rlwrap ccl"
alias ecl="rlwrap ecl"
alias lisp="rlwrap lisp"
alias cmucl="rlwrap lisp"
alias alisp="rlwrap alisp"
alias clisp="rlwrap clisp"

########################################################
## OPAM configuration
#. $HOME/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

########################################################
## SQLite configuration
export PATH="/usr/local/opt/sqlite/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/sqlite/lib"
export CPPFLAGS="-I/usr/local/opt/sqlite/include"
export PKG_CONFIG_PATH="/usr/local/opt/sqlite/lib/pkgconfig:$PKG_CONFIG_PATH"

########################################################
## Ruby configuration
# rbenv config
# if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

########################################################
## Node.js configuration
export NODE_PATH=/usr/local/lib/node_modules:$HOME/.nvm/versions/node/v10.15.3/lib/node_modules
alias cnpm="npm --registry=https://registry.npm.taobao.org \
--cache=$HOME/.npm/.cache/cnpm \
--disturl=https://npm.taobao.org/dist \
--userconfig=$HOME/.cnpmrc"
alias sudocnpm="sudo npm --registry=https://registry.npm.taobao.org \
--cache=$HOME/.npm/.cache/cnpm \
--disturl=https://npm.taobao.org/dist \
--userconfig=$HOME/.cnpmrc"

# nvm config
export NVM_DIR="$HOME/.nvm"
#[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
#[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion
export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/dist # handle GFW network problem

########################################################
## Java configurations

# openjdk configuration
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/usr/local/opt/openjdk/include"

# jenv configuration
#eval "$(jenv init -)"
# alias for Java asmtools
export ASMTOOLSHOME="$HOME/git/asmtools-7.0-build/release/lib/asmtools.jar"
alias asmtools="java -jar ${ASMTOOLSHOME}"

########################################################
## Python configurations
export PKG_CONFIG_PATH="/usr/local/Library/Homebrew/pkgconfig:/usr/local/Cellar/libffi/3.2.1/lib/pkgconfig"
export INFOPATH=/sw/share/info:/sw/info:/usr/share/info
unset PYTHONPATH
export PATH="$PATH:/Users/muyinliu/Library/Python/3.9/bin"
export PATH="$PATH:/Users/muyinliu/.local/bin"
### enable pipx argument completion
eval "$(register-python-argcomplete pipx)"

########################################################
## portable shell commands
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/binutils/bin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gawk/libexec/gnubin:$PATH"

#################################################
## .private_profile
##   private configs like HOMEBREW_GITHUB_API_TOKEN
if [ -f ~/.private_profile ]; then . ~/.private_profile; fi
