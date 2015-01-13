// -*- mode:c++; indent-tabs-mode:nil; -*-

#include "foobar.hh"

namespace foobar {

int getTheNumber() {
  return 42;
}

int getANumber(int input) {
  return getTheNumber() * input % 1<<30;
}

}
