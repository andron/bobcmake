#!/usr/bin/env sh

test -d build && rm -rf build
mkdir -p build
cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=install ..
ninja
ninja install
tree install
