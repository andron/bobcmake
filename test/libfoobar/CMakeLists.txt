cmake_minimum_required(VERSION 3.0.2)

bob_add(
  _CXX11
  _TARGETS libfoobar
  _VERSION 1.0.0
  _DEFINES HAVE_STUFF HAVE_MORE_STUFF
  _SOURCES src/foobar.cpp
  )

bob_add(
  _CXX11
  _TARGETS foobar_plugin
  _SOURCES src/foobar_plugin.cpp
  )

bob_add_tests(
  _LIBS libfoobar
  )
