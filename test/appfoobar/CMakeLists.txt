# Use variable for easy renaming.
set(target appfoo)

# Create an exeutable following the "project" guidelines. I.e. no fancy
# schmancy stuff, just follow a plain simple file layout.
bob_add_executable(${target})

# Link with internal targets using the CMake standard way, i.e. using the
# target_link_libraries()-function. Compiler include options to header files
# and special compiler flags like defines comes from the linkee.
target_link_libraries(${target} foobar)
