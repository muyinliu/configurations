#!/bin/bash

## Auto init macOS for developer
##
## Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/muyinliu/configurations/master/auto_init_macos.sh)"
##   or with SS proxy: SS_SERVER_HOST=<host> SS_SERVER_PORT=<port> SS_SERVER_PASS=<pass> SS_SERVER_METHOD=<method> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/muyinliu/configurations/master/auto_init_macos.sh)"

GITHUB_USER=muyinliu
GITHUBUSERCONTENT_IP=199.232.68.133
UPDATE_SYSTEM=true
SPEEDUP=true
SS_SERVER_HOST=${SS_SERVER_HOST}
SS_SERVER_PORT=${SS_SERVER_PORT:-8080}
SS_SERVER_PASS=${SS_SERVER_PASS:-password}
SS_SERVER_METHOD=${SS_SERVER_METHOD:-aes-256-gcm}

function colored_echo () {
    if [ -z "$2" ]; then
        style="\e[1;32m"
    else
        style="$2"
    fi;
    printf "$style%s\e[0m\n" "$1"
}

function prompt_admin_password () {
    while :; do # Loop until valid input is entered or Cancel is pressed.
        adminpwd=$(osascript -e "Tell application \"System Events\" to display dialog \"Enter ${USER}’s administrator password:\" with title \"Administrator Password\" with hidden answer default answer \"\"" -e "text returned of result" 2>/dev/null)
        if [[ "$?" != "0" ]]; then
            colored_echo 'User selected "Cancel" button, exiting script!' "\e[31m";
            # Abort, if user pressed Cancel.
            exit 1;
        fi
        if [[ -z "$adminpwd" ]]; then
            # The user left the password blank.
            osascript -e 'Tell application "System Events" to display alert "You must enter a non-blank password; please try again." as warning' >/dev/null;
            # Continue loop to prompt again.
        else
            echo -e "$adminpwd\n" | sudo -S echo ""
            result="$(sudo -n uptime 2>&1 | grep -c "load")"
            if [[ "$result" = "1" ]]; then
                colored_echo "Admin password is correct...";
                # Valid password: exit loop and continue.
                unset adminpwd;
                break;
            else
                # The admin password is incorect.
                unset adminpwd;
                colored_echo "The admin password was incorrect!";
                osascript -e 'Tell application "System Events" to display alert "The admin password was incorrect!" as warning' >/dev/null;
                # Continue loop to prompt again.
            fi
        fi
    done
}

function activate_terminal_window () {
    osascript -e 'tell application "Terminal" to activate'
}

function restart_system () {
    echo ""
    colored_echo "Restarting..."
    sudo /sbin/shutdown -r now
}

function update_system () {
    echo ""
    colored_echo "Updating system."
    tmp_file=".softwareupdate.$$"
    colored_echo "  Checking Apple Software Update Server for available updates,"
    colored_echo "  Please be patient. This process may take a while to complete..."
    sudo /usr/sbin/softwareupdate -l | sudo tee $tmp_file
    wait
    echo -e "\n"
    require_reboot_updates_count=$(/usr/bin/grep "restart" $tmp_file | /usr/bin/wc -l | xargs)
    colored_echo "  $require_reboot_updates_count updates require a reboot."
    /usr/bin/grep "restart" $tmp_file
    echo ""
    not_require_reboot_updates_count=$(/usr/bin/grep -v "restart" $tmp_file | grep "recommended" | /usr/bin/wc -l | xargs)
    colored_echo "  $not_require_reboot_updates_count updates do not require a reboot."
    /usr/bin/grep -v "restart" $tmp_file | grep "recommended"
    echo ""
    recommended_updates_count=$(/usr/bin/grep "recommended" $tmp_file | /usr/bin/wc -l | xargs)
    if [[ "$recommended_updates_count" = "0" ]]; then
         colored_echo "  No new recommended updates found."
    else
        if [[ "$require_reboot_updates_count" = "0" ]]; then
          colored_echo "  Updates found, but no reboot required. Installing now."
          colored_echo "  Please be patient. This process may take a while to complete."
          sudo /usr/sbin/softwareupdate -ia
          wait
          colored_echo "  Finished with all Apple Software Update installations."
        else
          colored_echo "  Updates found, reboot required. Installing now."
          colored_echo "  Please be patient. This process may take a while to complete."
          colored_echo "  Once complete, this machine will automatically restart."
          sudo /usr/sbin/softwareupdate -ia
          wait
          colored_echo "  Finished with all Apple Software Update installations."
        fi
    fi

    # cleaning up temp files before possible reboot
    /bin/rm -rf $tmp_file

    if [[ "$require_reboot_updates_count" != "0" ]]; then
        colored_echo "  Apple Software Updates requiring restart have been installed."
        colored_echo "  Please run this script again after restart."
        read -pr "  Press any key to restart..." </dev/tty
        wait
        restart_system
    fi
}

function install_apple_command_line_tools () {
    echo ""
    colored_echo "Installing Apple Command Line Tools."
    colored_echo "  Checking to see if Apple Command Line Tools are installed."
    xcode-select -p &>/dev/null
    if [[ "$?" != "0" ]]; then
        colored_echo "  Apple Command Line Utilities not installed. Installing..."
        colored_echo "  Please be patient. This process may take a while to complete."
        # Tell software update to also install OSX Command Line Tools without prompt
        ## As per https://sector7g.be/posts/installing-xcode-command-line-tools-through-terminal-without-any-user-interaction
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        sudo /usr/sbin/softwareupdate -ia
        wait
        /bin/rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        colored_echo "  Finished installing Apple Command Line Tools."
    else
        colored_echo "  Apple Command Line Tools already installed."
    fi
}

function install_rosetta() {
    /usr/sbin/softwareupdate --install-rosetta
}

function install_brew () {
    echo ""
    colored_echo "Installing Homebrew."
    if test ! "$(command -v brew)"; then
        # prevent `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused`
        if $SPEEDUP; then
            sudo echo "" | sudo tee -a /etc/hosts
            sudo echo "$GITHUBUSERCONTENT_IP raw.githubusercontent.com" | sudo tee -a /etc/hosts
        fi;
        curl -o brew_install.sh -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh
        if $SPEEDUP; then
            colored_echo "  Speed up Hombrew installation with ustc mirror."
            # speed up git clone of brew.git (/usr/local/Homebrew)
            # options -i of BSD's sed is slightly different from Linux
            sed -i "" "s/BREW_REPO=\"https:\/\/github.com\/Homebrew\/brew\"/BREW_REPO=\"https:\/\/mirrors.ustc.edu.cn\/brew.git\"/g" brew_install.sh
            # speed up brew update (/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core)
            export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git
            # avoid Error: Failure while executing; `git clone https://github.com/Homebrew/homebrew-core /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core` exited with 128.
            export HOMEBREW_CORE_GIT_REMOTE=https://mirrors.ustc.edu.cn/homebrew-core.git
        fi;
        yes | /bin/bash brew_install.sh
        colored_echo "  Checking Homebrew."
        brew doctor
        colored_echo "  Homebrew installed."
    else
        echo "  Homebrew already installed."
    fi
}

function enable_mirror_for_brew () {
    echo ""
    colored_echo "Enable ustc mirror for brew."
    git -C "$(brew --repo)" remote set-url origin https://mirrors.ustc.edu.cn/git/homebrew/brew.git
    git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
    # avoid fatal: cannot change to '/usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask': No such file or directory
    if [ ! -d "$(brew --repo homebrew/cask)" ]; then
        mkdir -p "$(brew --repo homebrew/cask)"
        cd "$(brew --repo homebrew/cask)" >/dev/null || return
        git init -q
        git config "remote.origin.url" https://mirrors.ustc.edu.cn/homebrew-cask.git
        git config "remote.origin.fetch" "+refs/heads/*:refs/remotes/origin/*"
        git config "core.autocrlf" false
        git fetch origin --force
        git fetch origin --tags --force
        git reset --hard origin/master
    else
        git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git
    fi;
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
}

function disable_mirror_for_brew () {
    echo ""
    colored_echo "Disable mirror for brew."
    git -C "$(brew --repo)" remote set-url origin https://github.com/Homebrew/brew.git
    git -C "$(brew --repo homebrew/core)" remote set-url origin https://github.com/Homebrew/homebrew-core.git
    git -C "$(brew --repo homebrew/cask)" remote set-url origin https://github.com/Homebrew/homebrew-cask.git
    export HOMEBREW_BOTTLE_DOMAIN=https://homebrew.bintray.com/homebrew-bottles
}

function enable_proxy () {
    # have to config proxy to speed up `brew install --cask`(download a lot data from https://github.com/xxx/yyy/releases/zzz)
    echo ""
    colored_echo "Enable proxy."
    if [[ -n "$SS_SERVER_HOST" ]]; then
        ss-local -s "$SS_SERVER_HOST" -p "$SS_SERVER_PORT" -k "$SS_SERVER_PASS" -m "$SS_SERVER_METHOD" -l 1080 &> /dev/null &
        export ALL_PROXY="socks5h://127.0.0.1:1080"
        colored_echo "  ALL_PROXY configured." 
    else
        colored_echo "  env SS_SERVER_HOST NOT set yet, skip."
    fi;
}

function disable_proxy () {
    echo ""
    colored_echo "Disable proxy."
    unset ALL_PROXY
}

function install_software_with_brew () {
    echo ""
    colored_echo "Installing software with brew."
    # install portable shell commands
    brew install coreutils
    brew install binutils
    brew install gnu-sed
    brew install findutils
    brew install grep
    brew install gawk
    # install zsh-syntax-highlighting
    brew install zsh-syntax-highlighting
    # install fasd
    brew install fasd
    # install utilities
    brew install git
    brew install tig
    brew install tmux
    brew install htop
    brew install tree
    brew install ncdu
    brew install rlwrap
    brew install vim
    brew install emacs
    brew install ag
    brew install jq
    brew install pup
    brew install trash
    brew install cloc
    brew install iproute2mac
    brew install uni2ascii
    brew install mdp/tap/qrterminal
    brew install zbar
    # install program language
    brew install sbcl
    brew install roswell
    brew install openjdk@11
    brew install maven
    brew install leiningen
    brew install automake
    brew install golang
    brew install node
    # install network tools
    brew install mosh
    brew install autossh
    brew install wget
    brew install curl
    brew install telnet
    brew install netcat
    brew install proxychains-ng
    brew install libuv
    brew install shadowsocks-libev
    brew install frpc
}

function install_software_with_brew_cask () {
    echo ""
    colored_echo "Installing software with brew cask."
    # see https://github.com/Homebrew/homebrew-cask/tree/master/Casks for more software
    brew install --cask alfred
    brew install --cask rectangle
    brew install --cask karabiner-elements # require config ~/.config/karabiner
    brew install --cask caffeine
    brew install --cask iterm2
    brew install --cask rar
    brew install --cask the-unarchiver
    brew install --cask lastpass
    brew install --cask google-chrome
    brew install --cask aquamacs # require config ~/.emacs.d
    brew install --cask oracle-jdk
    brew install --cask qlmarkdown
    brew install --cask --no-quarantine syntax-highlight
    brew tap federico-terzi/espanso && brew install espanso
    brew install --cask dozer
    ## optional software
    # brew install --cask istat-menus
    # brew install --cask dingtalk
    # brew install --cask telegram
    # brew install --cask wechat
    # brew install --cask qq
    # brew install --cask bitbar
    # brew install --cask shadowsocksx-ng
    # brew install --cask sublime-text
    # brew install --cask pennywise
    # brew install --cask paragon-ntfs
    # brew install --cask visual-studio-code
    # brew install --cask daisydisk
    # brew install --cask docker
    # brew install --cask thunder
    # brew install --cask baidunetdisk
    # brew install --cask kaleidoscope
    # brew install --cask movist
    # brew install --cask qqlive
    # brew install --cask pdf-expert
    # brew install --cask rocket-chat
    # brew install --cask qqmusic
    # brew install --cask neteasemusic
    # brew install --cask typora
    
    ## TODO following software NOT support yet
    # brew install --cask vimac
}

function install_oh_my_zsh () {
    colored_echo "  Installing oh-my-zsh."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    # install plugin zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
}

# FIXME: should compile with Xcode?
function install_proximac () {
    colored_echo "  Installing proximac."
    curl -fsSL https://raw.githubusercontent.com/proximac-org/proximac-install/master/install.py | sudo python
}

function install_quicklisp () {
    colored_echo "  Installing quicklisp."
    if [ ! -d ~/quicklisp/ ]; then
        cd /tmp/ || exit
        curl -o quicklisp.lisp http://beta.quicklisp.org/quicklisp.lisp && \
        sbcl --load quicklisp.lisp \
             --eval '(quicklisp-quickstart:install)' \
             --eval '(ql-util:without-prompting (ql:add-to-init-file))' \
             --eval '(quit)'
        /bin/rm -rf /tmp/quicklisp.lisp
    fi;
}

function initall_slime () {
    colored_echo "  Installing slime."
    sbcl --eval "(ql:quickload 'swank)"
}

function install_node_utils() {
    colored_echo "  Installing Node.js utils."
    npm install -g wscat
}

function install_python_utils() {
    colored_echo "  Installing Python utils."
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
    pipx install pipenv
}

function install_other_software () {
    echo ""
    colored_echo "Installing other software."
    install_oh_my_zsh
    install_proximac
    install_quicklisp
    install_slime
    install_node_utils
    install_python_utils
}

function init_macos_configs () {
    colored_echo "Init macOS configs."
    # disable swipe scroll direction for mouse or trackpad
    defaults write -g com.apple.swipescrolldirection -bool FALSE;
}

function init_emacs_config () {
    colored_echo "  Init Emacs config."
    if [ -f ~/.emacs ]; then
        mv ~/.emacs ~/.emacs.bak
    fi;
    if [ -f ~/.emacs.d ]; then
        mv ~/.emacs.d ~/.emacs.bak
    fi;
    git clone --recursive https://github.com/$GITHUB_USER/.emacs.d.git ~/.emacs.d
}

function init_aquamacs_config () {
    colored_echo "  Init Aquamacs config."
    # force Aquamacs use ~/.emacs.d
    mv ~/Library/Preferences/Aquamacs\ Emacs/Packages ~/Library/Preferences/Aquamacs\ Emacs/Packages.bak
    ln -s ~/.emacs.d ~/Library/Preferences/Aquamacs\ Emacs/Packages
    mv ~/Library/Preferences/Aquamacs\ Emacs/Preferences.el ~/Library/Preferences/Aquamacs\ Emacs/Preferences.el.bak
    ln -s ~/.emacs.d/init.el ~/Library/Preferences/Aquamacs\ Emacs/Preferences.el
}

function init_other_configs () {
    colored_echo "  Init other configs."
    cd ~/ || exit
    git clone https://github.com/$GITHUB_USER/configurations
    cd configurations/ || exit
    /bin/bash ./init.sh
}

function init_all_configs () {
    echo ""
    colored_echo "Init all configs."
    init_macos_configs
    init_emacs_config
    init_aquamacs_config
    init_other_configs
}

## Main commands

prompt_admin_password

activate_terminal_window
if $UPDATE_SYSTEM; then update_system; fi;
install_apple_command_line_tools
if [[ "$(sysctl -n machdep.cpu.brand_string)" == *M1* ]]; then install_rosetta; fi;

install_brew
if $SPEEDUP; then enable_mirror_for_brew; fi;
install_software_with_brew
if $SPEEDUP; then enable_proxy; fi;
install_software_with_brew_cask
if $SPEEDUP; then
    disable_proxy
    disable_mirror_for_brew
fi;
install_other_software

init_all_config

colored_echo "Auto init macOS finished!"
