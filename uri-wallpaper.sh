#!/bin/bash

# keep the original as well as the blurry version
FILEPATH_ORIGINAL="/tmp/uri-wallpaper.orig.jpg"
FILEPATH_MODIFIED="/tmp/uri-wallpaper.jpg"

# helpful functions
##
help-usage() {
    echo "usage: $(basename "$0") [-qh] [-b blur] [-c options] url"
}

help-epilogue() {
    echo "set wallpaper from image url with optional blur"
}

help() {
    help-usage
    help-epilogue
    echo
    cat << EOF
    -h/--help       show help info
    -b/--blur       set the sigma for the image blur. higher values increase the
                    fuzziness. 0 = no blur. defaults to 12
    -c/--convert    custom options to pass to the convert command
    -q/--quiet      hide all output
    -v/--verbose    show more output
EOF
}

# echo based on verbosity level
# first word is colored based on verbosity and placed inside brackets
# e.g., to echo if verbosity is <= 1:
# echo-managed 1 hello world
echo-managed() {
    # don't echo shit if verbosity is 0
    if [ "$VERBOSITY" -eq 0 ]; then
        return
    fi
    
    # default global verbosity is 2
    # default message verbosity level is 2
    level=2
    
    # if the first arg is a number, use it as verbosity level
    if [ $1 -eq $1 ] 2>/dev/null; then
        level=$1
        shift
    fi
    
    # use the first word as a label
    label=$1
    shift

    # echo if message level <= global verbosity level
    if [ $level -le $VERBOSITY ]; then
        printf "\033[0;3${level}m[%s]\033[0m %s\n" "$label" "$*"
    fi
}

# default options
VERBOSITY=2
BLUR=12

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -h)
            help-usage
            help-epilogue
            echo
            echo "--help for more"
            exit
            ;;
        --help)
            help
            exit
            ;;
        -b|--blur)
            BLUR="$2"
            shift # past argument
            shift # past value
            ;;
        -c|--convert)
            CONVERT_OPTS="$2"
            shift # past argument
            shift # past value
            ;;
        -v|--verbose)   
            let VERBOSITY++
            shift # past argument
            ;;
        -q|--quiet)
            VERBOSITY=0
            shift # past argument
            ;;
        *) # unknown option
            # positional arguments are treated as a url.
            # only the last one given will be used.
            URI="$1"
            shift # past argument
            ;;
    esac
done

# require a URI
if [ -z "$URI" ]; then
    echo-managed 0 error no url provided 1>&2
    help-usage
    exit 1
fi

# determine download command
# (must happen *after* arguments are parsed in case a url is given)
if command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget $URI -O $FILEPATH_ORIGINAL"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl $URI -o $FILEPATH_ORIGINAL"
else
    echo-managed 0 error could not find wget or curl 1>&2
    exit 1
fi

# download image
echo-managed 1 download $URI
echo-managed 4 download "> $DOWNLOAD_CMD"
$DOWNLOAD_CMD >/dev/null 2>&1
echo-managed 3 download saved to "'$FILEPATH_ORIGINAL'"

# modify image
if [ "$BLUR" -ge 0 ] || [ -n "$CONVERT_OPTS" ]; then
    # check for imagemagick
    if ! command -v convert >/dev/null 2>&1; then
        echo-managed 3 error imagemagick not installed. cannot modify >&2
        # use original image
        FILEPATH_MODIFIED="$FILEPATH_ORIGINAL"
    else
        echo-managed 1 imagemagick editing image
        echo-managed 4 imagemagick "> convert '$FILEPATH_ORIGINAL' -blur 0x$BLUR $CONVERT_OPTS '$FILEPATH_MODIFIED'"
        convert "$FILEPATH_ORIGINAL" -blur 0x$BLUR $CONVERT_OPTS "$FILEPATH_MODIFIED"
        echo-managed 3 imagemagick modified file: $FILEPATH_MODIFIED
    fi
fi

# TODO: support changing the bg for different desktop managers

# set image as desktop background
echo-managed 1 dconf changing desktop background
echo-managed 4 dconf "> dconf write /org/cinnamon/desktop/background/picture-uri 'file://$FILEPATH_MODIFIED'"
dconf write /org/cinnamon/desktop/background/picture-uri "'file://$FILEPATH_MODIFIED'"
echo-managed 3 dconf desktop wallpaper set to $(dconf read /org/cinnamon/desktop/background/picture-uri)
