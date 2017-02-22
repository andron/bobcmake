# Running test build

Create a build directory (in the `test` directory is perfectly fine).

    mkdir build
    cd build

Then run cmake with a install prefix to be able to test installation as
well as. The install directory can point inside the `test/build`
directory.

    cmake .. -DCMAKE_INSTALL_PREFIX=install -GNinja
    ninja
    ninja install
    tree install

The output from tree should be a structure containing a `include`, `bin`
and a `lib` or `lib64` directory depending on architecture. I.e. the GNU
coding standards directory layout. If the structure is not suitable or
does not fit the current purpose use a post-processing script to change
the layout.
