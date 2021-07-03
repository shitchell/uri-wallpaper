# uri-wallpaper
an .sh script for setting the desktop background using the url to an image

```
usage: uri-wallpaper [-qh] [-b blur] [-c options] url
set wallpaper from image url with optional blur

    -h/--help       show help info
    -b/--blur       set the sigma for the image blur. higher values increase the
                    fuzziness. 0 = no blur. defaults to 12
    -c/--convert    custom options to pass to the convert command
    -q/--quiet      hide all output
    -v/--verbose    show more output
```

*example*
```sh
$ uri-wallpaper.sh "https://i.imgur.com/UmqkrGt.jpg"
```

## options

### image blur
`-b/--blur`

by default, a blur is added to the specified image. this is done with the imagemagick command `convert -blur 0x$BLUR`, where the `$BLUR` value is set by the `--blur` option. run with `--blur 0` to turn the blur off

### custom image editing
`-c/--convert`

you can specify custom options to pass to the `convert` command using the `--convert` option. e.g.: to create a black & white version of the image, you could run

```bash
uri-wallpaper -c "-colorspace gray" "https://i.imgur.com/UmqkrGt.jpg"
```

### verbosity
`-q/--quiet`  
`-v/--verbose`

silence all output with `-q` or increase verbosity with one or more uses of `-v`. options are parsed in order, so `-q -v` will be verbose and `-v -q` will be quiet.

## dependencies
* `wget` or `curl`
* imagemagick (if using image editing options)

## demo
https://user-images.githubusercontent.com/621412/124342949-edbb0980-db95-11eb-95e0-4a393b007efb.mp4

## cron
in order to use `uri-wallpaper` in a crontab, you'll need to find a way to access the current dbus session. there's a couple of ways to do this, but i'll simply explain how i have it set up (based on [this stackoverflow answer](https://stackoverflow.com/a/54075726))

### save your env
edit your `~/.xinitrc` file to store your environment variables each time you login by adding this line to the bottom:

**~/.xinitrc**
```sh
env | grep -v '%s' > ~/.Xenv
```

### load your env
in your crontab, load the saved env file before running the `uri-wallpaper` command

```sh
*/30 * * * * env $(cat ~/.Xenv | xargs) /path/to/uri-wallpaper -q -b 15 "http://internet.com/wallpaper.png"
```

## limitations
currently this only supports cinnamon because that's what i use. i plan on adding support for other desktop managers whenever i get around to it
