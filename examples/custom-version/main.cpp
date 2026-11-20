#include <boost/describe.hpp>
#include <boost/mp11.hpp>
#include <boost/pfr.hpp>

#include <string_view>

struct User { int id; bool active; };
BOOST_DESCRIBE_STRUCT(User, (), (id, active))

using Fields = boost::describe::describe_members<User, boost::describe::mod_public>;
static_assert(boost::mp11::mp_size<Fields>::value == 2);

int main() {
  const User user{42, true};
  int described_id = 0;
  boost::mp11::mp_for_each<Fields>([&](auto field) {
    if (std::string_view(field.name) == "id")
      described_id = user.*field.pointer;
  });
  return described_id == boost::pfr::get<0>(user) &&
                 boost::pfr::get<1>(user) ? 0 : 1;
}
