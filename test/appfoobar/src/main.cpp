// -*- mode:c++; -*-

#include "TheClass.h"

#include "foobar.h"

#include <cstdio>

int
main(int ac, char** av) {
  TheClass c;
  double d = 1.1f * ac;
  c.setValue(&d);

  auto anumber = foobar::getANumber(ac);

  printf("%s: num args: %d\nclass value: %.3f\nthe number:  %d\n",
         av[0], ac, *(c.value()), anumber);
  
  return ac % 2;
}
