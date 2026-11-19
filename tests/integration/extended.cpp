#include <boost/asio/io_context.hpp>
#include <boost/filesystem.hpp>
#include <boost/regex.hpp>
#include <boost/stacktrace.hpp>
#include <boost/thread.hpp>

int main() {
  boost::asio::io_context io;
  io.poll();
  boost::filesystem::path file("BoostPack.cmake");
  boost::regex expression("[a-z]+");
  boost::thread worker([] {});
  worker.join();
  const boost::stacktrace::stacktrace trace;
  return (!file.empty() && boost::regex_match("boost", expression) &&
          trace.size() < 4096) ? 0 : 1;
}
