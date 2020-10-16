#!/bin/bash

# create symbolic links
for i in `\ls -ld HOME/.* | awk '{print $9}' | cut -c 6-`; do
    # backup if config file already exits
    if [ -e $HOME/$i ]; then
        mv $HOME/$i $HOME/${i}.bak
    fi;
    ln -s "${PWD}/HOME/$i" "${HOME}/$i"
done;