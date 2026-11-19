#include <boost/pfr.hpp>

struct Point { int x; int y; };

int main() {
  Point point{2, 3};
  return boost::pfr::get<0>(point) + boost::pfr::get<1>(point) == 5 ? 0 : 1;
}
