#include <boost/describe.hpp>
#include <boost/mp11.hpp>
#include <boost/pfr.hpp>

#ifndef BOOSTPACK_HOST_DEPENDENCY
#error "The host FetchContent dependency was not linked"
#endif

struct Request {
  int retries;
  bool enabled;
};
BOOST_DESCRIBE_STRUCT(Request, (), (retries, enabled))

using Members = boost::describe::describe_members<
  Request, boost::describe::mod_public>;
static_assert(boost::mp11::mp_size<Members>::value == 2);

int main() {
  const Request request{3, true};
  return boost::pfr::get<0>(request) == 3 &&
         boost::pfr::get<1>(request) ? 0 : 1;
}
