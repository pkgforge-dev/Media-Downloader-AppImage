#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm aria2 yt-dlp bun qt6ct kvantum lxqt-qtplugin

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini

# Comment this out if you need an AUR package
make-aur-package media-downloader

# yt-dlp-ejs archlinux package has a hard dependency on deno
# but this can actually use bun instead
pacman -Rdd --noconfirm deno || :

# yt-dlp also gives a warning that only deno is supported by default
sed -i -e "s|default=\['deno'\]|default=['bun']|" /usr/lib/python*/site-packages/yt_dlp/options.py 

# If the application needs to be manually built that has to be done down here

# if you also have to make nightly releases check for DEVEL_RELEASE = 1
#
# if [ "${DEVEL_RELEASE-}" = 1 ]; then
# 	nightly build steps
# else
# 	regular build steps
# fi
