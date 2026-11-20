#include <boost/coroutine/all.hpp>
#include <boost/fiber/fiber.hpp>

int main() {
  int result = 0;
  boost::fibers::fiber worker([&result] { result = 7; });
  worker.join();

  using coroutine = boost::coroutines::coroutine<int>;
  coroutine::pull_type source([](coroutine::push_type& sink) {
    sink(5);
  });
  if (!source || source.get() != 5) return 1;
  return result == 7 ? 0 : 2;
}
