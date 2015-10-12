// -*- mode:c++; indent-tabs-mode:nil; -*-

#include "foobar.hh"

#include <cstdio>
#include <cstdlib>

int
main(int ac, char** av) {
  printf("%s:%s -- %d:%s\n", __FILE__, __FUNCTION__, ac, av[0]);
  auto thenumber = foobar::getTheNumber();
  printf("The number: %d\n", thenumber);
  return 0;
}
