#include <boost/charconv.hpp>
#include <boost/container/small_vector.hpp>
#include <boost/mp11.hpp>
#include <boost/pfr.hpp>
#include <boost/unordered/unordered_flat_map.hpp>

#include <string>
#include <type_traits>

struct Record { int id; int value; };

int main() {
  static_assert(boost::mp11::mp_size<boost::mp11::mp_list<int, float>>::value == 2);
  static_assert(std::is_same_v<decltype(boost::pfr::get<0>(std::declval<Record&>())), int&>);

  boost::container::small_vector<int, 4> values{2, 4, 6};
  boost::unordered_flat_map<int, std::string> entries;
  Record record{7, values[0] + values[1]};
  entries.emplace(boost::pfr::get<0>(record), "ready");

  int parsed = 0;
  const auto *first = "42";
  auto result = boost::charconv::from_chars(first, first + 2, parsed);
  return (result.ec == std::errc{} && parsed == 42 &&
          entries.at(record.id) == "ready" && record.value == 6)
             ? 0 : 1;
}
