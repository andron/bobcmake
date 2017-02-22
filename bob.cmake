# -*- mode:cmake -*-

# Setup rpath for installed artifacts, works on systems that support it.
# NOTE: Using $ORIGIN and relative rpaths is a security risk.
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib64;$ORIGIN/../lib")
set(CMAKE_BUILD_WITH_INSTALL_RPATH    NO)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH NO)

# Use user writable location when install prefix is not set explicitly, this
# is usually what you want. System installation should go via proper packaging
# systems, like RPM and MSI.
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "install"
    CACHE PATH "The default install directory" FORCE)
endif()

# Build DSOs by default
if (NOT DEFINED BUILD_SHARED_LIBS)
  set(BUILD_SHARED_LIBS YES
    CACHE BOOL "Build DSOs by default" FORCE)
endif()

# Useful default CXX flags.
if (CMAKE_COMPILER_IS_GNUCXX)
  string(APPEND CMAKE_CXX_FLAGS "-pedantic -Wall -g")
endif()

# Lets adhere to some standard install directory structure... It might not be
# your way, it is a better way, despite your arguments.
include(GNUInstallDirs)


# Utility functions to make life eaiser within this file.
# ============================================================================
macro(_tgtinfo message)
  message(STATUS "[${target}] ${message}")
endmacro()


# Function for adding a single exeutable
# ============================================================================
function(bob_add_executable target)
  set(opts QT4)
  set(args COMPONENT)
  set(mulv SOURCES)
  # Parse options with CMake *built-in* options parser.
  cmake_parse_arguments(_ARG
    "${opts}" "${args}" "${mulv}" ${ARGN})

  # If the install component is not specified, default all executables to be
  # categorized as "apps". Another useful default is to have "nocomponent" or
  # similar and then discard that component from packaging, that will coerce
  # developers to specify their applications.
  if (NOT _ARG_COMPONENT)
    set(_ARG_COMPONENT apps)
    _tgtinfo("COMPONENT: ${_ARG_COMPONENT} [default]")
  endif()

  # Make life easy for the smart lazy devs, dump all source files that shall
  # be built in subdirectory 'src'. Just adjust for file suffix and be
  # done. Else, let the monkeys create their own list of files and pass as
  # argument SOURCES.
  if (NOT _ARG_SOURCES)
    file(GLOB_RECURSE files_src "src/*.h" "src/*.cpp")
    _tgtinfo("SOURCES: src/*.h src/*.cpp")
  else()
    list(APPEND files_src ${_ARG_SOURCES})
  endif()

  # If there is a directory named 'ui', this is a Qt application that has user
  # interface files. Assume Qt5 unless option QT4 is set.
  if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/ui)
    file(GLOB files_uic ui/*.ui)
    if (_ARG_QT4)
      qt4_wrap_ui(files_uic_src ${files_uic})
    else()
      qt5_wrap_ui(files_uic_src ${files_uic})
    endif()
    list(APPEND files_src ${files_uic_src})
    _tgtinfo("SRC_UIC: ${files_uic_src}")
  endif()

  # If there is a directory named 'qrc', there are Qt resources that should be
  # processed. Same as for user interface files, assume Qt5.
  if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/qrc)
    file(GLOB files_qrc qrc/*.qrc)
    if (_ARG_QT4)
      qt4_add_resources(files_qrc_src ${files_qrc})
    else()
      qt5_add_resources(files_qrc_src ${files_qrc})
    endif()
    list(APPEND files_src ${files_qrc_src})
    _tgtinfo("SRC_QRC: ${files_qrc_src}")
  endif()

  # Add executables using CMake add_executable.
  add_executable(${target} ${files_src})

  # Set suitable properties on the target.
  set_property(TARGET ${target} PROPERTY AUTOMOC ON)

  # Install directive that installs executables in the "bin" directory for all
  # platforms. Adjust location by specifying CMAKE_INSTALL_BINDIR during
  # installation instead of messing around with target specific
  # settings. These will just be a pain to update. In the general case, the
  # executables of a software suite should not need to be spread over a
  # plethora of arbitrary directories.
  install(TARGETS ${target}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT ${_ARG_COMPONENT})
endfunction()


# Function for adding a single library (DSO or Archive)
# ============================================================================
function(bob_add_library target)
  set(opts QT4 STATIC SHARED)
  set(args COMPONENT VERSION)
  set(mulv SOURCES)
  cmake_parse_arguments(_ARG
    "${opts}" "${args}" "${mulv}" ${ARGN})

  # Same as for executable
  if (NOT _ARG_COMPONENT)
    set(_ARG_COMPONENT runtime)
    _tgtinfo("COMPONENT: ${_ARG_COMPONENT} [default]")
  endif()

  # Same as for executable
  if (NOT _ARG_SOURCES)
    file(GLOB_RECURSE files_src "src/*.h" "src/*.cpp" "include/*.h")
    _tgtinfo("SOURCES: src/*.h src/*.cpp include/*.h")
  else()
    list(APPEND files_src ${_ARG_SOURCES})
  endif()

  # Assume 1.0.0 is a good version number until otherwise specified.
  if (NOT _ARG_VERSION)
    set(_ARG_VERSION "1.0.0")
  endif()
  # Also assume the API version is reflected by the build version. The cases
  # where this it *not* case are and should be very rare. Only make the
  # workaround when forced to. It is most likely the result of a unstructured
  # mind. And the workaround: use set_property() after the call to
  # bob_add_library().
  string(REGEX MATCH "[0-9]+" apiversion ${_ARG_VERSION})

  _tgtinfo("BLD VERSION: ${_ARG_VERSION}")
  _tgtinfo("API VERSION: ${apiversion}")

  # Build DSOs by default. If this becomes an archive switch install component
  # to "devel". Archives are not part of a runtime environment.
  if (_ARG_STATIC AND NOT _ARG_SHARED)
    set(libtype STATIC)
    set(_ARG_COMPONENT "devel")
  elseif(_ARG_SHARED AND NOT _ARG_STATIC)
    set(libtype STATIC)
    set(_ARG_COMPONENT "devel")
  elseif(_ARG_SHARED AND _ARG_STATIC)
    # Make adjustments to build both STATIC and SHARED library.
  else()
    set(libtype)
  endif()

  # CMake default
  add_library(${target} ${libtype} ${files_src})

  # Setup
  target_include_directories(${target}
    PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    PUBLIC $<INSTALL_INTERFACE:include>)

  # Suitable properties.
  set_property(TARGET ${target} PROPERTY AUTOMOC ON)
  set_property(TARGET ${target} PROPERTY SOVERSION "${apiversion}")
  set_property(TARGET ${target} PROPERTY VERSION   "${_ARG_VERSION}")

  # Install libraries with both runtime, library and archive location
  # specified. This actually differs between platforms and is nicely solved by
  # CMake. On Windows DSOs (DLLs) are installed into the RUNTIME destination,
  # which is the same as executables. Thus exec and DLLs end up in the same
  # directory, and voila no missing DLL errors, and no trumpty-dumpty
  # all-stuff-in-a-single directory on Unix. This also makes OSX-installs a
  # breeze. (https://cmake.org/cmake/help/latest/command/install.html)
  install(TARGETS ${target}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    COMPONENT ${_ARG_COMPONENT})

  # Install the public interface headers files into the install include
  # directory. Doing all things right the layout of your include directory
  # should be ready to go verbatim into the include directory. Why not?
  # Non-interface files goes into the 'src' directory. And now the project
  # have a very simple way of separating important interface files from plain
  # internal dittos. How about: 'gitk -- libfoobar/include'?
  install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    COMPONENT "devel"
    PATTERN "*~" EXCLUDE)
endfunction()


# Function for adding a single MODULE library (i.e. a plugin).
# ============================================================================
function(bob_add_plugin target)
  set(opts QT4)
  set(args COMPONENT)
  set(mulv SOURCES)
  cmake_parse_arguments(_ARG
    "${opts}" "${args}" "${mulv}" ${ARGN})
  # TODO
endfunction()
