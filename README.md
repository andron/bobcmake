This repository contains CMake build files for C++ projects.

# Example Module

In a your new project there should be main `CMakeLists.txt` containing following code.

    cmake_minimum_required(VERSION 2.8.12)

    # Sepecify project name here.
    project(PROJECT_NAME)

    # Include the main build file from this repository.
    include(bob.cmake)

    # Include all sub-directories containing "CMakeLists.txt" (see next example).
    bob_add_submodules()

Below is contents of `CMakeLists.txt` under some project subdirectory for building executables
`example`, `test.tmp.example` and shared library `libexample`.

    # Call bob_add() helper function to set properties for targets.
    bob_add(
    # Common target properties
      _TARGETS
        example
        libexample # Targets prefixed with "lib" are automatically build as shared libraries.
        test.tmp.example

      # Following sets preprocessor macros MODULE_NAME, MODULE_VERSION, MODULE_RELEASE.
      _NAME example
      _VERSION 1.0.1 # Required for libraries.
      _RELEASE 1

      _CXX11 # Use C++11; alias for "_CXX_FLAGS -std=c++11".

      _QT 5 # Use Qt 5 (compile ui/*.ui, resources/*.qrc and run moc on sources).

      _DEFINES
        BOOST_RESULT_OF_USE_DECLTYPE

      # Add runtime dependency.
      _USES example_plugin

    # Properties for executable and library
      _TARGETS
        example
        libexample

      _SOURCES
        src/*.cpp
        src/*.hh

      # Link with "spatial" and "commonapp", either from current project or LD_LIBRARY_PATH.
      _LIBS
        spatial
        commonapp

      # Link with "boost_program_options" and "boost_system" from "$BOOST_HOME/lib" and
      # add include path "$BOOST_HOME/include".
      _LIBS_AT BOOST_HOME
        boost_program_options
        boost_system

      # Add include path "$EIGEN_HOME/include"
      _LIBS_AT EIGEN_HOME

      # Add include and library path from "$TACSI_HOME".
      _LIBS_AT TACSI_HOME
        commgr
        log

      # Qt modules to use
      _QT_MODULES
        Xml
        Core
        Gui
        Widgets

    # Properties for executable
      _TARGETS
        example

      _SOURCES
        main.cpp

    # Properties for tests
      _TARGETS
        test.tmp.example

      _SOURCES
        tests/*.cpp
        tests/*.hh

      _LIBS
        libexample
        gtest
        gtest_main

      _QT_MODULES
        Test
    )

# Running CMake

You must first run `cmake` in project directory to generate build file for `make`, `ninja` or other
build systems.

## Build Project

To build your project you will usually run following commands.

    mkdir build
    cd build
    cmake -GNinja ..
    ninja -j4

It's necessary to re-run `cmake` manually if:

* new source files were added;
* `Q_OBJECT` macro was added to an existing file;
* new module or sub-module was created.

To re-run `cmake` with `make` (or `ninja`) command run `touch CMakeLists.txt` first.

## CMake Arguments

* `-GNinja`

  Generate build files for `ninja` (default is generating build files for `make`).

* `-DCMAKE_BUILD_TYPE=Debug`

   Build project with debug symbols without optimizations (default build type is `Release`).

   Supported build types from CMake are `Debug`, `Release`, `RelWithDebInfo` and `MinSizeRel`.
   Additional build types are `Profiling`, `Coverage` and `Gperftools`.

* `-DCMAKE_CXX_COMPILER=clang++`

   Use Clang to compile C++ source files (default compiler is usually `gcc`).

* `-DCMAKE_CXX_FLAGS=-pg`

   Add `-pg` compiler flag.

* `-DCMAKE_INSTALL_PREFIX=$PWD/install`

   Change install prefix (default is usually `/usr/local`).

