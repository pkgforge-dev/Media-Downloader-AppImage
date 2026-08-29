#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	aria2          \
	cmake          \
	kvantum        \
	lxqt-qtplugin  \
	qt6-base       \
	qt6ct          \
	npm

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini

echo "Building quickjs..."
echo "---------------------------------------------------------------"
# build quickjs since archlinux only packages quickjs-ng
# This has performance issues with yt-dlp
# https://github.com/bellard/quickjs/issues/445#issuecomment-3350946013
git clone https://github.com/bellard/quickjs ./quickjs && (
	cd ./quickjs
	make -s
	make -s install PREFIX=/usr
)

# media-downloader expects the bundled quickjs under this name, otherwise
# it will download its own copy in HOME and will fail to work on musl systems
ln -sr /usr/bin/qjs /usr/bin/qjs-linux-"$ARCH"

# build yt-dlp and its dependencies since archlinuxarm is insanely out of date
# remove deno since we have quickjs already, npm is still needed to build yt-dlp-ejs
export PRE_BUILD_CMDS="sed -i -e 's|deno||g' -e '/^check() {/,/^}/d' ./PKGBUILD"
make-aur-package --archlinux-pkg yt-dlp-ejs
make-aur-package --archlinux-pkg yt-dlp
unset PRE_BUILD_CMDS

# yt-dlp gives a warning that only deno is supported by default
sed -i -e "s|default=\['deno'\]|default=['quickjs']|" /usr/lib/python*/site-packages/yt_dlp/options.py

# If the application needs to be manually built that has to be done down here
echo "Building media-downloader..."
echo "---------------------------------------------------------------"
git clone https://github.com/mhogomchungu/media-downloader ./media-downloader && (
	cd ./media-downloader

	git fetch --tags origin
	TAG=$(git tag --sort=-v:refname | grep -vi 'preview\|alpha\|beta' | head -1)
	git checkout "$TAG"

	git apply ../patches/always-use-bundled-binaries.patch

	cmake -S ./ -B ./build \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/usr \
		-D BUILD_WITH_QT6=ON
	cmake --build ./build
	cmake --install ./build

	echo "$TAG" > ~/version
)

