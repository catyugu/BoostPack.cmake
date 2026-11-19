#include <boost/mp11.hpp>
#include <boost/pfr.hpp>

struct User { int id; bool active; };

int main() {
  static_assert(boost::mp11::mp_size<boost::mp11::mp_list<int, bool>>::value == 2);
  const User u{42, true};
  return boost::pfr::get<0>(u) == 42 && boost::pfr::get<1>(u) ? 0 : 1;
}