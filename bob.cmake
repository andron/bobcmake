# Create new build type.
macro(bob_add_build_type build_type base_build_type comment compiler_flags linker_flags)
  foreach (compiler_language "C" "CXX")
    set(CMAKE_${compiler_language}_FLAGS_${build_type}
      "${CMAKE_${compiler_language}_FLAGS_${base_build_type}} ${compiler_flags}")
  endforeach()

  foreach (output_type "EXE" "SHARED" "MODULE")
    set(CMAKE_${output_type}_LINKER_FLAGS_${build_type}
      "${CMAKE_${output_type}_LINKER_FLAGS_${base_build_type}} ${linker_flags}")
  endforeach()

  string(TOUPPER ${build_type} build_type_upper)
  bob_append(bob_build_types ${build_type_upper})
  bob_append(bob_build_types_help "\n  ${build_type_upper}\n    ${comment}")
endmacro()

function(bob_test_valid_build_type)
  if (CMAKE_BUILD_TYPE)
    bob_get(bob_build_types bob_build_types)
    string(TOUPPER ${CMAKE_BUILD_TYPE} bob_build_type)
    list(FIND bob_build_types ${bob_build_type} found_index)
    if (found_index EQUAL -1)
      bob_get(bob_build_types_help bob_build_types_help)
      message(FATAL_ERROR "Unknown build type \"${CMAKE_BUILD_TYPE}\"!"
        " Use bob_add_build_type() to add new build types."
        " Valid build types are: Debug, Release, RelWithDebInfo and MinSizeRel and${bob_build_types_help}\n")
    endif()
  endif()
endfunction(bob_test_valid_build_type)

# Append string (usually file path) to global variable.
function(bob_append variable_name)
  set_property(GLOBAL APPEND PROPERTY ${variable_name} ${ARGN})
endfunction()

# Clear global variable.
function(bob_reset variable_name)
  set_property(GLOBAL PROPERTY ${variable_name})
endfunction()

# Get global variable value.
function(bob_get target_variable_name property_name)
  get_property(${target_variable_name} GLOBAL PROPERTY ${property_name})
  if (NOT ${target_variable_name})
    set(${target_variable_name} ${ARGN})
  endif()
  set(${target_variable_name} ${${target_variable_name}} PARENT_SCOPE)
endfunction()

# Use:
#   bob_add_libs(mytarget boost boost_system boost_regex)
# to add include directory and library directory from BOOST_HOME to "mytarget" target
# and (optionally) link with boost_system and boost_regex.
function(bob_add_libs target home_var_name)
  set(home_prefix "$ENV{${home_var_name}}")

  if (NOT home_prefix)
    message(FATAL_ERROR "${home_var_name} environment variable is not set!")
  endif()

  if (NOT EXISTS "${home_prefix}/")
    message(FATAL_ERROR "${home_var_name} path does not exist!")
  endif()

  if (EXISTS "${home_prefix}/include")
    bob_append(${target}_INCLUDES ${home_prefix}/include)
  endif()

  if (ARGN)
    if (EXISTS "${home_prefix}/lib64")
      foreach (lib ${ARGN})
        find_library(${home_var_name}_${lib} ${lib} PATHS "${home_prefix}/lib64/" NO_DEFAULT_PATH)
        bob_append(${target}_LIBS ${${home_var_name}_${lib}})
      endforeach()
      elseif (EXISTS "${home_prefix}/lib")
        foreach (lib ${ARGN})
          find_library(${home_var_name}_${lib} ${lib} PATHS "${home_prefix}/lib/" NO_DEFAULT_PATH)
	  bob_append(${target}_LIBS ${${home_var_name}_${lib}})
	endforeach()
    else()
      message(FATAL_ERROR "Cannot link libraries from ${home_var_name} (prefix doesn't contain \"libs\" directory)!")
    endif()
  endif()
endfunction(bob_add_libs)

# Append value to global variable for all targets (format for variable name is TARGET_VARIABLE).
function(bob_targets_variable_append variable value)
  if (NOT ARGN)
    message(FATAL_ERROR "Missing _TARGETS tag!")
  endif()

  if (NOT variable)
    message(FATAL_ERROR "Variable name mustn't be empty!")
  endif()

  # If argument contains asterisk, use this as patter to find files recursively.
  if (value MATCHES "\\*")
    file(GLOB_RECURSE values "${value}")
  else()
    set(values "${value}")
  endif()

  foreach (target ${ARGN})
    bob_append(${target}${variable} ${values})
  endforeach()
endfunction(bob_targets_variable_append)

# Creates library if target starts with "lib" or ends with "_plugin", otherwise creates executable.
# Rest of the arguments are sources and objects to compile and link.
function(bob_add_library_or_executable target target_version)
  # Add all header files so they can be accessed as project files from an IDE.
  file(GLOB_RECURSE headers "*.hh" "*.h")

  if (target MATCHES "^lib|_plugin$")
    if (ARGN)
      # Create target for shared library.
      add_library(${target} SHARED ${ARGN} ${headers})

      if (NOT target_version)
        message(FATAL_ERROR "Version is not set for library ${target}.")
      endif()

      # The plugins are now in tacsiextensions called libFoo. Need another check to see if it was a plugin.
      if (target MATCHES "_plugin$")
        install(TARGETS ${target} DESTINATION "share/tacsi/plugins")
      else()
        install(TARGETS ${target} DESTINATION "lib64")
        set_property(TARGET ${target} PROPERTY VERSION ${target_version})
        if (NOT EXISTS target_soversion)
          set(target_soversion ${target_version})
        endif()
        string(REPLACE "." ";" version_list ${target_soversion})
        list(GET version_list 0 version_major)
        set_property(TARGET ${target} PROPERTY SOVERSION ${version_major})
      endif()

      set_property(TARGET ${target} PROPERTY PREFIX "")
    else()
      # Create target for header-only library.
      add_library(${target} INTERFACE)
    endif()

    # If other targets links this library, they should be able to access headers in "include/".
    target_include_directories(${target} INTERFACE
      "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>"
      "$<INSTALL_INTERFACE:include>"
    )
  else()
    # Create target for executable.
    add_executable(${target} ${ARGN} ${headers})
    # Skip installation of tests.
    if (NOT target MATCHES "^test\\.")
      install(TARGETS ${target} DESTINATION "bin")
    endif()
  endif()
endfunction()

# Find sources containing Q_OBJECT macro and run moc on them.
macro(bob_add_mocced_sources target target_qt target_sources_var_name)
  foreach (source ${ARGN})
    file(STRINGS "${source}" found REGEX "Q_OBJECT")
    if (found)
      set(target_source ${CMAKE_CURRENT_BINARY_DIR}/moc_${target}/${source}.cpp)
      list(APPEND ${target_sources_var_name} ${target_source})
      if (target_qt EQUAL 5)
        qt5_generate_moc(${source} ${target_source})
      else()
        qt4_generate_moc(${source} ${target_source})
      endif()
    endif()
  endforeach()
endmacro()

# Generate source files (*.pb.cc and *.pb.hh) from specified protobuf files (*.proto).
#
# Requires protoc utility which is part of Google Protocol Buffers package.
#
# The target should be linked with protobuf library -- e.g. by specifying:
#
#   bob_add(
#   # ...
#   _PROTOBUF proto/*.proto
#   _LIBS_AT PROTOBUF_HOME protobuf
#   # ...
#   )
#
# in build file of target.
macro(bob_add_protobuf target_protobuf_outputs_var_name)
  foreach (protobuf ${ARGN})
    string(REGEX REPLACE "^.*/|\\.proto$" "" protobuf_output_basename ${protobuf})
    set(protobuf_output ${CMAKE_CURRENT_BINARY_DIR}/proto/${protobuf_output_basename}.pb.cc)

    add_custom_command(
      OUTPUT ${protobuf_output}
      COMMAND "protoc"
        --cpp_out=${CMAKE_CURRENT_BINARY_DIR}
        --proto_path=${CMAKE_CURRENT_LIST_DIR}
        ${protobuf}
      DEPENDS ${protobuf}
      WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )

    list(APPEND ${target_protobuf_outputs_var_name} ${protobuf_output})
  endforeach()
endmacro()

# Create new target to build.
function(bob_add_target target)
  # mytarget_NAME - name of module
  bob_get(target_name ${target}_NAME ${NAME})
  # mytarget_VERSION - version (format is MAJOR.MINOR.PATCH)
  bob_get(target_version ${target}_VERSION ${VERSION})
  # mytarget_RELEASE - release number
  bob_get(target_release ${target}_RELEASE ${RELEASE})
  # mytarget_SOURCES - source files to compile
  bob_get(target_sources ${target}_SOURCES)
  # mytarget_INCLUDES - include paths
  bob_get(target_includes ${target}_INCLUDES)
  # mytarget_HEADERS - headers containing Q_OBJECT function without .cpp file in same directory
  bob_get(target_headers ${target}_HEADERS)
  # mytarget_LIBS - search paths for libraries (e.g. -L$ENV{BOOST_HOME}/lib),
  #               libraries to link (e.g. -lboost_system) or other modules to link (e.g. spatial)
  #               NOTE: For linking and including headers from Boost and other libraries it's
  #                     better to use bob_add_libs(mytarget boost boost_lib1 ...)
  bob_get(target_libs ${target}_LIBS)
  # mytarget_CXX_FLAGS - additional flags for compiler
  bob_get(target_cxx_flags ${target}_CXX_FLAGS)
  # mytarget_DEFINES - macro definitions for preprocessor
  bob_get(target_defines ${target}_DEFINES)
  # mytarget_QT - Qt version (5, 4 or 3)
  bob_get(target_qt ${target}_QT)
  # mytarget_QT_MODULES - Qt modules to use (Core, Gui, Widgets, Xml etc.)
  bob_get(target_qt_modules ${target}_QT_MODULES)
  # mytarget_COMPILE - other stuff to compile
  bob_get(target_compile ${target}_COMPILE)
  # mytarget_USES - non-compile time module dependencies
  bob_get(target_uses ${target}_USES)
  # mytarget_PROTOBUF - protobuf source files
  bob_get(target_protobuf ${target}_PROTOBUF)

  # Header-only library can leave out sources otherwise build fails.
  if (NOT target_sources)
    if (NOT target MATCHES "^lib" OR NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/include/")
      message(FATAL_ERROR "No source files set for target ${target}.")
    endif()
  endif()

  # For Qt, run moc, uic and rcc.
  if (target_qt)
    # Override executable names for Qt utilities for current Qt version.
    if (target_qt EQUAL 5)
      set(QT_QMAKE_EXECUTABLE qmake)
      set(QT_MOC_EXECUTABLE moc)
      set(QT_UIC_EXECUTABLE uic)
    elseif (target_qt EQUAL 4)
      set(QT_QMAKE_EXECUTABLE qmake-qt4)
      set(QT_MOC_EXECUTABLE moc-qt4)
      set(QT_UIC_EXECUTABLE uic-qt4)
    elseif (target_qt EQUAL 3)
      set(QT_QMAKE_EXECUTABLE qmake-qt3)
      set(QT_MOC_EXECUTABLE moc-qt3)
      set(QT_UIC_EXECUTABLE uic-qt3)
    else()
      message(FATAL_ERROR "Only Qt versions 3, 4 and 5 are supported.")
    endif()

    if (target_qt EQUAL 3)
      # Qt 3 (CMake functions for Qt can be used either for Qt 4 or Qt 3, but not both)
      bob_add_libs(${target} QT_HOME qt-mt)
      bob_get(target_includes ${target}_INCLUDES)
      bob_get(target_libs ${target}_LIBS)
    else()
      file(GLOB target_forms *.ui ui/*.ui)
      file(GLOB target_resources *.qrc ui/*.qrc resources/*.qrc)

      if (target_qt EQUAL 5)
        # Qt 5
        qt5_wrap_ui(target_forms_headers ${target_forms})
        qt5_add_resources(target_resources_rcc ${target_resources})
      elseif (target_qt EQUAL 4)
        # Qt 4
        qt4_wrap_ui(target_forms_headers ${target_forms})
        qt4_add_resources(target_resources_rcc ${target_resources})

        list(APPEND target_includes ${QT_INCLUDES})
        list(APPEND target_cxx_flags ${QT_DEFINITIONS})
      endif()

      # Run moc on source files containing Q_OBJECT.
      bob_add_mocced_sources(${target} ${target_qt} target_sources ${target_sources} ${target_headers})
    endif()
  endif()

  # Add "src" and "include" module subdirectories to include paths.
  foreach (subdir "include" "src")
    if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${subdir}/")
      list(INSERT target_includes 0 "${CMAKE_CURRENT_LIST_DIR}/${subdir}")
    endif()
  endforeach()

  # Compile protobuf files.
  bob_add_protobuf(target_protobuf_outputs ${target_protobuf})

  list(APPEND sources
    ${target_compile}
    ${target_sources}
    ${target_forms_headers}
    ${target_resources_rcc}
    ${target_protobuf_outputs}
    )

  # Create executable, shared library or header-only library.
  bob_add_library_or_executable(${target} "${target_version}" ${sources})

  # Add module dependencies.
  if (target_uses)
    add_dependencies(${target} ${target_uses})
  endif()

  # Use Qt modules.
  if (target_qt EQUAL 5)
    qt5_use_modules(${target} Core ${target_qt_modules})
  elseif (target_qt EQUAL 4)
    qt4_use_modules(${target} Core ${target_qt_modules})
  endif()

  if (sources)
    # Define macros.
    set_property(TARGET ${target} PROPERTY COMPILE_DEFINITIONS
      ${target_defines}
      MODULE_NAME="${target_name}"
      MODULE_VERSION="${target_version}"
      MODULE_RELEASE="${target_release}"
    )

    # Only include paths relative to PROJECT_SOURCE_DIR are included using -I
    # (otherwise -isystem is used silencing all compiler warnings in headers).
    foreach (include_path ${target_includes})
      if (include_path MATCHES "^([^/]|${PROJECT_SOURCE_DIR})")
        target_include_directories(${target} BEFORE PRIVATE ${include_path})
      else()
        target_include_directories(${target} SYSTEM PRIVATE ${include_path})
      endif()
    endforeach()

    # Set compilation flags for target.
    foreach (compile_flag ${target_cxx_flags})
      set_property(TARGET ${target} APPEND_STRING PROPERTY COMPILE_FLAGS "${compile_flag} ")
    endforeach()

    # Link target.
    target_link_libraries(${target} ${target_libs})
  endif()

  # Install everything under "include" and "share" directories.
  foreach (subdir "include" "share")
    if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${subdir}/")
      install(DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/${subdir}/" DESTINATION "${subdir}")
    endif()
  endforeach()
endfunction(bob_add_target)

# Helper function to create targets.
function(bob_add)
  set(tag)
  set(targets)
  set(all_targets)

  foreach (arg ${ARGN} "_END")
    if (arg MATCHES "^_[A-Z][0-9A-Z_]*$")
      if (tag STREQUAL "_LIBS_AT")
        foreach (target ${targets})
          bob_get(libs ${target}_LIBS_AT)
          if (libs)
            bob_add_libs(${target} ${libs})
            bob_reset(${target}_LIBS_AT)
          endif()
        endforeach()
      endif()

      set(tag ${arg})
      if (tag MATCHES "^_TARGETS?$")
        set(targets)
      endif()
    elseif (tag)
      if (tag MATCHES "^_TARGETS?$")
        list(APPEND targets ${arg})
        list(APPEND all_targets ${arg})
      else()
        bob_targets_variable_append(${tag} "${arg}" ${targets})
      endif()
    else()
      message(FATAL_ERROR "Missing tag (_NAME, _VERSION, _RELEASE, _TARGETS or other) before \"${arg}\"!")
    endif()
  endforeach()

  list(REMOVE_DUPLICATES all_targets)
  foreach(target ${all_targets})
    if (BOB_COMMON_LIBS_AT)
      bob_add_libs(${target} ${BOB_COMMON_LIBS_AT})
    endif()
    bob_add_target(${target})
  endforeach()
endfunction(bob_add)

# Helper function to add all sub-directories containing "CMakeLists.txt".
function(bob_add_submodules)
  file(GLOB dirs */)
  foreach (dir ${dirs})
    if (EXISTS "${dir}/CMakeLists.txt")
      add_subdirectory("${dir}")
    endif()
  endforeach()
endfunction(bob_add_submodules)

find_package(Qt4 REQUIRED)
find_package(Qt5Widgets REQUIRED) # Qt5Widgets is used instead of Qt5Core for qt5_wrap_ui() to work.
find_package(Qt5Xml REQUIRED)

# This allows source files to find headers generated by uic (ui_*.h).
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# Run moc utility on any file containing Q_OBJECT or #include "<FILE>.moc"
# FIXME: This doesn't work for headers in "include/" or headers without cpp file.
#set(CMAKE_AUTOMOC ON)

# Set default compilation flags.
set(CMAKE_C_FLAGS              "-pedantic -Wall -Wextra -Wno-long-long ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "-std=c++11 -pedantic -Wall -Wextra -Wno-long-long ${CMAKE_CXX_FLAGS}")

# custom build types
bob_append(bob_build_types DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
bob_add_build_type(PROFILING RELEASE
  "Use gprof program to analyze call graph and times after compile application is run"
  "-g -pg" "-pg")
bob_add_build_type(COVERAGE RELEASE
  "Use gcov or gcovr to analyze code coverage after compiled tests are run"
  "--coverage" "--coverage")
bob_add_build_type(SANITIZE_THREAD RELEASE
  "Enable ThreadSanitizer, a fast data race detector"
  "-fsanitize=thread -g -fPIE" "-fsanitize=thread -pie")
bob_add_build_type(SANITIZE_MEMORY RELEASE
  "Enable AddressSanitizer, a fast memory error detector"
  "-fsanitize=memory -fsanitize-memory-track-origins -g -fno-omit-frame-pointer -fPIE"
  "-fsanitize=memory -fsanitize-memory-track-origins -pie")
bob_add_build_type(SANITIZE_ADDRESS RELEASE
  "Enable LeakSanitizer, a memory leak detector"
  "-fsanitize=address -g -fno-omit-frame-pointer" "-fsanitize=address")
bob_add_build_type(SANITIZE_UNDEFINED RELEASE
  "Enable UndefinedBehaviorSanitizer, a fast undefined behavior detector"
  "-fsanitize=undefined -g -fno-omit-frame-pointer" "-fsanitize=undefined")
bob_add_build_type(PROFILE_GENERATE RELEASE
  "Produce profile useful for later recompilation with profile feedback based optimization (PROFILE_USE)"
  "-fprofile-generate" "-fprofile-generate")
bob_add_build_type(PROFILE_USE RELEASE
  "Use profile feedback directed optimizations (after build and run with PROFILE_GENERATE)"
  "-fprofile-use" "-fprofile-use")
bob_add_build_type(GPERFTOOLS RELEASE
  "Use pprof program (from gperftools) to print CPU and heap profile information"
  "-fno-omit-frame-pointer" "")
string(TOUPPER "${CMAKE_BUILD_TYPE}" bob_build_type)
if (bob_build_type STREQUAL "GPERFTOOLS")
  list(APPEND BOB_COMMON_LIBS_AT gperftools tcmalloc_and_profiler)
endif()

bob_test_valid_build_type()
