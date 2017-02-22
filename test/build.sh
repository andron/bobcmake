#!/usr/bin/env sh

test -d build && rm -rf build
mkdir -p build
cd build
cmake -GNinja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=install ..
ninja -v
ninja install
tree install
