# Variable for easy renaming.
set(target foobar)

# Create library using default guidelines.
bob_add_library(${target})

# Use plain CMake functions to tell all target linking this library that the
# compiler definition USE_THE_BANANA_MONKEY is set.
target_compile_definitions(${target}
  INTERFACE USE_THE_BANANA_MONKEY)

# Also require the constexpr and auto c++ features to be available, this
# because these are in the interface of the library, most likely.
target_compile_features(${target}
  PUBLIC cxx_constexpr cxx_auto_type)
