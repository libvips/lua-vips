#!/usr/bin/env bash

version=$VIPS_VERSION
pre_version=$VIPS_PRE_VERSION
tag_version=$version${pre_version:+-$pre_version}
vips_tarball=https://github.com/libvips/libvips/releases/download/v$tag_version/vips-$tag_version.tar.gz

set -e

# Do we already have the correct vips built?
if [ -d "$HOME/vips/bin" ]; then
    installed_version=$($HOME/vips/bin/vips --version | awk -F- '{print $2}')
    echo "Need vips $version"
    echo "Found vips $installed_version"

    if [ "$installed_version" = "$version" ]; then
        echo "Using cached vips directory"
        exit 0
    fi
fi

mkdir -p "$HOME/vips"

echo "Installing vips $version"

curl -Ls $vips_tarball | tar xz
cd vips-$version
./configure --prefix="$HOME/vips" "$@"
make -j$JOBS && make install

# Clean-up build directory
cd ../
rm -rf vips-$version
