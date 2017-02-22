// -*- mode:c++; -*-

class TheClass {
 public:
  TheClass();
  TheClass(double const* value);

  virtual ~TheClass() {}

  double const* value() const;
  void setValue(double const* value);
  
 private:
  double const* _value;
};
