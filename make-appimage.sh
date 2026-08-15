#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/pixmaps/media-downloader.png
export DESKTOP=/usr/share/applications/media-downloader.desktop
export DEPLOY_PYTHON=1

# Deploy dependencies
quick-sharun \
	/usr/bin/media-downloader \
	/usr/bin/wget             \
	/usr/bin/aria2c           \
	/usr/bin/yt-dlp           \
	/usr/bin/qjs*             \
	/usr/bin/ffmpeg

# media-downloader searches binaries in PATH in reversed order
echo 'PATH=${PATH}:${APPDIR}/bin' >> ./AppDir/.env

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
