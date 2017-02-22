// -*- mode:c++; -*-

#include "TheClass.h"

TheClass::TheClass()
    : _value(nullptr) {
}

TheClass::TheClass(double const* value)
    : _value(value) {
}

double const*
TheClass::value() const {
  return _value;
}

void
TheClass::setValue(double const* value) {
  if (value != nullptr)
    _value = value;
}
