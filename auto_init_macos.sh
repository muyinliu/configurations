#!/bin/bash

## Auto init macOS for developer
##
## Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/muyinliu/configurations/master/auto_init_macos.sh)"
##   or with SS proxy: SS_SERVER_HOST=<host> SS_SERVER_PORT=<port> SS_SERVER_PASS=<pass> SS_SERVER_METHOD=<method> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/muyinliu/configurations/master/auto_init_macos.sh)"

GITHUB_USER=muyinliu
GITHUBUSERCONTENT_IP=199.232.68.133
UPDATE_SYSTEM=true
SPEEDUP=true
# TODO should move to ??
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
    printf "$style$1\e[0m\n"
}

function prompt_admin_password () {
    while :; do # Loop until valid input is entered or Cancel is pressed.
        adminpwd=$(osascript -e 'Tell application "System Events" to display dialog "Enter '$USER'’s administrator password:" with title "Administrator Password" with hidden answer default answer ""' -e 'text returned of result' 2>/dev/null)
        if (( $? )); then
            colored_echo 'User selected "Cancel" button, exiting script!' "\e[31m";
            # Abort, if user pressed Cancel.
            exit 1;
        fi
        name=$(echo -n "$adminpwd" | sed 's/^ *//' | sed 's/ *$//')  # Trim leading and trailing whitespace.
        if [[ -z "$adminpwd" ]]; then
            # The user left the password blank.
            osascript -e 'Tell application "System Events" to display alert "You must enter a non-blank password; please try again." as warning' >/dev/null;
            # Continue loop to prompt again.
        else
            echo -e "$adminpwd\n" | sudo -S echo ""
            result=$(sudo -n uptime 2>&1|grep "load"|wc -l);
            if [[ $result = "       1" ]]; then
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
    sudo /usr/sbin/softwareupdate -l &> $tmp_file
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
    if [ $recommended_updates_count = "0" ]; then
         colored_echo "  No new recommended updates found."
    else
        if [ $require_reboot_updates_count = "0" ]; then
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

    if [ $require_reboot_updates_count != "0" ]; then
        colored_echo "  Apple Software Updates requiring restart have been installed."
        colored_echo "  Please run this script again after restart."
        read -p "  Press any key to restart..." </dev/tty
        wait
        restart_system
    fi
}

function install_apple_command_line_tools () {
    echo ""
    colored_echo "Installing Apple Command Line Tools."
    colored_echo "  Checking to see if Apple Command Line Tools are installed."
    xcode-select -p &>/dev/null
    if [[ $? -ne 0 ]]; then
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

function install_brew () {
    echo ""
    colored_echo "Installing Homebrew."
    if test ! $(which brew); then
        # prevent `curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused`
        if $SPEEDUP; then
            sudo echo "" | sudo tee -a /etc/hosts
            sudo echo "$GITHUBUSERCONTENT_IP raw.githubusercontent.com" | sudo tee -a /etc/hosts
        fi;
        curl -o brew_install.sh -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh
        if $SPEEDUP; then
            colored_echo "  Speed up with mirrors"
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
    colored_echo "Enable mirror for brew."
    # TODO fatal: cannot change to '/usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask': No such file or directory
    git -C "$(brew --repo)" remote set-url origin https://mirrors.ustc.edu.cn/git/homebrew/brew.git
    git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
    if [ ! -d "$(brew --repo homebrew/cask)" ]; then
        mkdir -p "$(brew --repo homebrew/cask)"
        cd "$(brew --repo homebrew/cask)" >/dev/null
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

function enable_https_proxy () {
    # have to config proxy to speed up `brew cask install`(download a lot data from https://github.com/xxx/yyy/releases/zzz)
    echo ""
    colored_echo "Enable HTTPS_PROXY."
    if $SS_SERVER_HOST; then
        ss-local -s $SS_SERVER_HOST -p $SS_SERVER_PORT -k $SS_SERVER_PASS -m $SS_SERVER_METHOD -l 1080 &> /dev/null &
        export HTTPS_PROXY="socks5h://127.0.0.1:1080"
        colored_echo "  HTTPS_PROXY configured." 
    else
        colored_echo "  env SS_SERVER_HOST NOT set yet, skip."
    fi;
}

function disable_https_proxy () {
    echo ""
    colored_echo "Disable HTTPS_PROXY."
    unset HTTPS_PROXY
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
    # install utilities
    brew install git
    brew install tig
    brew install tmux
    brew install htop
    brew install tree
    brew install ncdu
    brew install vim
    brew install emacs
    brew install ag
    brew install jq
    brew install rmtrash
    brew install cloc
    brew install sbcl
    brew install roswell
    brew install leiningen
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
}

function install_software_with_brew_cask () {
    echo ""
    colored_echo "Installing software with brew cask."
    # see https://github.com/Homebrew/homebrew-cask/tree/master/Casks for more software
    brew cask install alfred
    brew cask install rectangle
    brew cask install karabiner-elements # require config ~/.config/karabiner
    brew cask install caffeine
    brew cask install iterm2
    brew cask install rar
    brew cask install the-unarvhiver
    brew cask install lasspass
    brew cask install google-chrome
    brew cask install aquamacs # require config ~/.emacs.d
    brew cask install oracle-jdk
    brew cask install qlmarkdown
    ## optional software
    # brew cask install istat-menus
    # brew cask install dingtalk
    # brew cask install telegram
    # brew cask install wechat
    # brew cask install qq
    # brew cask install bitbar
    # brew cask install shadowsocksx-ng
    # brew cask install sublime-text
    # brew cask install pennywise
    # brew cask install paragon-ntfs
    # brew cask install visual-studio-code
    # brew cask install daisydisk
    # brew cask install docker
    # brew cask install thunder
    # brew cask install baidunetdisk
    # brew cask install dozer
    # brew cask install kaleidoscope
    # brew cask install movist
    # brew cask install qqlive
    # brew cask install pdf-expert
    # brew cask install rocket-chat
    # brew cask install qqmusic
    # brew cask install neteasemusic
    # brew cask install typora
    
    ## TODO following software NOT support yet
    # brew cask install espanso
    # brew cask install vimac
}

function install_oh_my_zsh () {
    colored_echo "  Installing oh-my-zsh."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

function install_proximac () {
    colored_echo "  Installing proximac."
    curl -fsSL https://raw.githubusercontent.com/proximac-org/proximac-install/master/install.py | sudo python
}

function install_quicklisp () {
    colored_echo "  Installing quicklisp."
    if [ ! -d ~/quicklisp/ ]; then
        cd /tmp/
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

function install_other_software () {
    echo ""
    colored_echo "Installing other software."
    install_oh_my_zsh
    install_proximac
    install_quicklisp
    install_slime
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
    cd ~/
    git clone https://github.com/$GITHUB_USER/configurations
    cd configurations/
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

install_brew
if $SPEEDUP; then enable_mirror_for_brew; fi;
install_software_with_brew
if $SPEEDUP; then enable_https_proxy; fi;
install_software_with_brew_cask
if $SPEEDUP; then
    disable_https_proxy
    disable_mirror_for_brew
fi;
install_other_software

init_all_config

colored_echo "Auto init macOS finished!"
