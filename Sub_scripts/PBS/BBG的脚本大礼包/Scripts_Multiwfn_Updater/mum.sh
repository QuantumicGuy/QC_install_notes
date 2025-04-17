#!/bin/bash

# MuM: Multiwfn Update Manager
# Author: Lazemare.

export TOP_PID=$$
EXIT(){
    trap 'exit $1' TERM
    kill -s TERM $TOP_PID
}

MUMDIR=""
NULL=/dev/null
DOWNLOADER=0

check_dep(){
    if [ "$(unzip 2> $NULL)" == "" ] ;then
        echo "unzip not found!" >&2
        EXIT 1
    fi
    if [ "$(curl --help 2> $NULL)" != "" ] ;then
        DOWNLOADER=1
    elif [ "$(wget --help 2> $NULL)" != "" ] ;then
        DOWNLOADER=2
    else
        echo "curl or wget not found!" >&2
        EXIT 1
    fi
}

# Check mum directory
check_mum_dir(){
    if test -f "$HOME"/.config/mum/latest ;then
        MUMDIR="$HOME"/.config/mum
        echo 0
    elif test -f "$HOME"/.mum/latest ;then
        MUMDIR="$HOME"/.mum
        echo 0
    else
        echo 1
    fi
}

# Make mum directory
make_mum_dir(){
    if [ "$(mkdir -p "$HOME"/.config/mum 2>&1)" != "" ] ;then
        if [ "$(mkdir -p "$HOME"/.mum 2>&1)" != "" ] ;then
            echo "Can not make mum directiry!" >&2
            EXIT 1
        else
            MUMDIR="$HOME"/.mum
        fi
    else
        MUMDIR="$HOME"/.config/mum
    fi
    mkdir -p "$MUMDIR"/download
    mkdir -p "$MUMDIR"/bak
    mkdir -p "$MUMDIR"/settings
}

# Check local Multiwfn version
check_local_version(){
    Multiwfn < /dev/null 2> $NULL | head -n 2 | tail -n 1 | sed "s/,/ /g" |
        sed "s/(dev)/ /g" | awk '{printf("%s %s",$2,$5)}' > "$MUMDIR"/tmp
    awk '{printf("%s ",$1)}' < "$MUMDIR"/tmp > "$MUMDIR"/version
    awk '{printf($2)}' < "$MUMDIR"/tmp |
        awk -F "-" '{printf("%s-%s-%s",$3,$2,$1)}' >> "$MUMDIR"/version
    rm "$MUMDIR"/tmp
}

# Find where is Multiwfn
find_multiwfn(){
    if [[ -v Multiwfnpath ]] && test -f "$Multiwfnpath"/"$1" ;then
        echo "$Multiwfnpath"
    elif test -f "$(which "$1")" ;then
        dirname "$(which "$1")"
    else
        echo "Multiwfn not installed!" >&2
        EXIT 1
    fi
}

# Backup Multiwfn
backup_multiwfn(){
    echo "Backing up ..." >&2
    P1=$(pwd)
    rm -rf "$MUMDIR"/bak/"$2"
    cd "$1" || EXIT 1
    tar -czvf "$2" ./* > "$NULL" 2> "$NULL"
    cp settings.ini "$MUMDIR"/settings/
    mv "$2" "$MUMDIR"/bak/
    cd "$P1" || EXIT 1
    echo "Multiwfn version $2 has been backed up."
}

# Roll back version
rollback_multiwfn(){
    echo "Rolling back ..." >&2
    rm -f "$MUMDIR"/bak/"$3"
    backup_multiwfn "$1" "$3"
    P2=$(pwd)
    rm -rf "${1:?}"/*
    cd "$1" || EXIT 1
    tar -xf "$MUMDIR"/bak/"$2"
    cd "$P2" || EXIT 1
    check_local_version
    echo "Now your Multiwfn version is $2."
}

# Inatall Multiwfn
install_multiwfn(){
    echo "Installing ..."
    P3=$(pwd)
    cd "$1" || EXIT 1
    rm -rf ./*
    unzip "$MUMDIR"/download/"$2".zip 2> $NULL > $NULL
    mv Multiwfn_*/* ./
    chmod +x Multiwfn
    rm -rf Multiwfn_*
    cp "$MUMDIR"/settings/settings.ini ./
    cd "$P3" || EXIT 1
    rm "$MUMDIR"/download/"$2".zip
    echo "Multiwfn version $2 has been installed."
}

# Check latest Multiwfn version. Return version number and update date.
check_online_version(){
    if [ "$1" -eq 1 ] ;then
        curl -s http://sobereva.com/multiwfn/download.html |
            grep Develop | sed "s/　/ /g" | sed "s/<\/h3>/ /g" |
            awk '{printf("%s %s", $3, $6)}' > "$MUMDIR"/tmp
    elif [ "$1" -eq 2 ] ;then
        wget -q -O - http://sobereva.com/multiwfn/download.html |
            grep Develop | sed "s/　/ /g" | sed "s/<\/h3>/ /g" |
            awk '{printf("%s %s", $3, $6)}' > "$MUMDIR"/tmp
    else
        echo "Unknown downloader!" >&2
        EXIT 1
    fi
    awk '{printf("%s ",$1)}' < "$MUMDIR"/tmp > "$MUMDIR"/latest
    awk '{printf($2)}' < "$MUMDIR"/tmp |
        awk -F "-" '{printf("%s-%s-%s",$3,$2,$1)}' >> "$MUMDIR"/latest
    rm "$MUMDIR"/tmp
}


# Compare latest and local Multiwfn version
compare_version(){
    date_latest=$(awk '{printf($2)}' < "$MUMDIR"/latest)
    date_local=$(awk '{printf($2)}' < "$MUMDIR"/version)
    version_latest=$(awk '{printf($1)}' < "$MUMDIR"/latest)
    version_local=$(awk '{printf($1)}' < "$MUMDIR"/version)
    if [[ ! "$date_local" < "$date_latest" ||
        "$version_local" > "$version_latest" ]]  ;then
        echo "Local Multiwfn version is up to date." >&2
        echo 0
    else
        echo "New version found: $version_latest - $date_latest" >&2
        echo "Local version: $version_local - $date_local" >&2
        echo 1
    fi
}

# http://sobereva.com/multiwfn/misc/Multiwfn_3.8_dev_bin_Linux.zip
# Download latest Multiwfn
download_multiwfn_latest(){
    version=$(awk '{printf($1)}' < "$MUMDIR"/latest)
    date=$(awk '{printf($2)}' < "$MUMDIR"/latest)
    echo "Downloading Multiwfn-$version-$date: "
    if [ "$1" -eq 1 ] ;then
        curl -o "$MUMDIR"/download/"$date".zip \
            http://sobereva.com/multiwfn/misc/Multiwfn_"$version"_dev_bin_Linux.zip
    elif [ "$1" -eq 2 ] ;then
        wget -o "$MUMDIR"/download/"$date".zip \
            http://sobereva.com/multiwfn/misc/Multiwfn_"$version"_dev_bin_Linux.zip
    else
        echo "Unknown downloader!" >&2
        EXIT 1
    fi
}

# Download latest manual
download_manual_latest(){
    version=$(awk '{printf($1)}' < "$MUMDIR"/latest)
    date=$(awk '{printf($2)}' < "$MUMDIR"/latest)
    echo "Downloading Multiwfn-manual-$version-$date: "
    if [ "$1" -eq 1 ] ;then
        curl -o "$MUMDIR"/download/Multiwfn_"$version"_dev.pdf \
            http://sobereva.com/multiwfn/misc/Multiwfn_"$version"_dev.pdf
    elif [ "$1" -eq 2 ] ;then
        wget -o "$MUMDIR"/download/Multiwfn_"$version"_dev.pdf \
            http://sobereva.com/multiwfn/misc/Multiwfn_"$version"_dev.pdf
    else
        echo "Unknown downloader!" >&2
        EXIT 1
    fi
    mv "$MUMDIR"/download/Multiwfn_"$version"_dev.pdf "$2"
}

print_help(){
    echo "mum: Multiwfn's Update Manager"
    echo "Usage: mum [c|u|l|r|d|m|h] (version)"
    echo "c|check:  check if there is update available."
    echo "u|update: update to latest version."
    echo "l|list:   list backed up version."
    echo "r|roll:   roll back to a backed up version."
    echo "d|delete: delete all backed up version."
    echo "m|manual: download latest manual."
    echo "h|help:   show help information then exit."
}

main(){
    if [ "$1" == "" ] ;then
        print_help
        exit 0
    fi
    if [ "$(check_mum_dir)" -eq 1 ] ;then
        make_mum_dir
    else
        check_mum_dir > $NULL
    fi
    # getopt
    if [ "$1" == "c" ] || [ "$1" == "check" ] ;then
        check_dep
        check_online_version "$DOWNLOADER"
        check_local_version
        compare_version > /dev/null
        exit 0
    elif [ "$1" == "u" ] || [ "$1" == "update" ] ;then
        check_dep
        path=$(find_multiwfn Multiwfn)
        check_online_version "$DOWNLOADER"
        check_local_version
        if [ "$(compare_version)" -eq 0 ] ;then
            exit 0
        else
            download_multiwfn_latest "$DOWNLOADER"
            date_latest=$(awk '{printf($2)}' < "$MUMDIR"/latest)
            date_local=$(awk '{printf($2)}' < "$MUMDIR"/version)
            backup_multiwfn  "$path" "$date_local"
            install_multiwfn "$path" "$date_latest"
        fi
        exit 0
    elif [ "$1" == "l" ] || [ "$1" == "list" ] ;then
        ls "$MUMDIR"/bak
    elif [ "$1" == "r" ] || [ "$1" == "rollback" ] ;then
        path=$(find_multiwfn Multiwfn)
        check_local_version
        date_local=$(awk '{printf($2)}' < "$MUMDIR"/version)
        if [ "$2" == "" ] ;then
            echo "Assign a version to roll back to!" >&2
            exit 1
        elif test -f "$MUMDIR"/bak/"$2" ;then
            rollback_multiwfn "$path" "$2" "$date_local"
        else
            echo "Version $2 does not exist!" >&2
            exit 1
        fi

    elif [ "$1" == "d" ] || [ "$1" == "delete" ] ;then
        read -rp "DO YOU REALLY WANT TO DO THIS? [Y|N] " answer
        if [ "$answer" == "Y" ] ;then
            rm -rf "$MUMDIR"/bak/*
            printf "%s\n" "All backed up files deleted."
            exit 0
        else
            printf "%s\n" "Never mind."
            exit 0
        fi
    elif [ "$1" == "m" ] || [ "$1" == "manual" ] ;then
        check_dep
        path=$(find_multiwfn Multiwfn)
        download_manual_latest "$DOWNLOADER" "$path"
    elif [ "$1" == "h" ] || [ "$1" == "help" ] ;then
        print_help
        exit 0
    else
        echo "Unknown command $1, try \`mem h' for information." >&2
        exit 0
    fi
}

main "$@"