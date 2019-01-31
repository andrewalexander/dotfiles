#!/bin/bash


TS=$(date +%s)

function create_link {
    [[ -z $1 ]] && echo "create_link: Needs argument"; exit 1

    if [ ! -h $HOME/$1 ]; then
        echo "Creating symbolic link: $1"
        ln -s $PWD/$1 $HOME/$1
    fi
}

function create_backup {
    [[ -z $1 ]] && echo "create_backup: Needs argument"; exit 1

    if [ -f $HOME/$1 ] || [ -d $HOME/$1 ]; then
        if [ ! -h $HOME/$1 ]; then
            echo "$HOME/$1 already exists"
            echo "Backing up $HOME/$1 to $HOME/.backup$1.$TS"
            mv $HOME/$1 $HOME/.backup$1.$TS
        fi
    fi
}

function create_local {
    [[ -z $1 ]] && echo "create_local: Needs argument"; exit 1

    if [ ! -f $HOME/$1 ]; then
        echo "Creating $HOME/$1 file "
        cp $PWD/$1 $HOME/$1
    fi
}

run() {
    for f in .vimrc .vimrc.local .vim .bashrc.* .curlrc .tmux.conf .ripgreprc
    do
        [[ $f == *".local" ]] && continue
        create_backup $f
        create_link $f
    done

    create_local .bashrc.local
    create_local .vimrc.local

    # Source new files in existing .bashrc
    for f in .bashrc.*
    do
        if ! grep "source \$HOME/$f" $HOME/.bashrc >/dev/null; then
            echo "Adding 'source \$HOME/$f' to .bashrc"
            echo "source \$HOME/$f" >> $HOME/.bashrc
        fi
    done
}

run
