cmake_minimum_required(VERSION 2.8.12)

bob_add(

_CXX11

_TARGETS
  libfoobar

_VERSION
  1.0.0

_DEFINES
  HAVE_STUFF
  HAVE_MORE_STUFF

_SOURCES
  src/*.cpp
  include/*.hh

)
