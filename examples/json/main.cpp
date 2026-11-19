#include <boost/json.hpp>
#include <boost/url.hpp>

#include <iostream>
#include <string>

int main() {
  // Compiled Boost libraries and their transitive dependencies are selected
  // and built through upstream CMake targets.
  const auto settings = boost::json::parse(
      R"({"service":"analytics","endpoint":"https://example.org/api/v1"})");
  const auto& object = settings.as_object();
  const auto& text = object.at("endpoint").as_string();
  const auto endpoint = boost::urls::parse_uri(std::string(text.data(), text.size()));
  if (!endpoint || endpoint->host() != "example.org")
    return 1;

  std::cout << "Service: " << object.at("service").as_string()
            << ", host: " << endpoint->host() << '\n';
  return 0;
}
