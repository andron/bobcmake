// -*- mode:c++; indent-tabs-mode:nil; -*-

#include <cstdio>
#include <cstdlib>

int
main(int ac, char** av) {
  printf("%s:%s -- %d:%s\n", __FILE__, __FUNCTION__, ac, av[0]);
  return 0;
}
