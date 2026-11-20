#include <boost/archive/text_iarchive.hpp>
#include <boost/archive/text_oarchive.hpp>
#include <boost/filesystem.hpp>
#include <boost/program_options.hpp>
#include <boost/regex.hpp>
#include <boost/serialization/string.hpp>
#include <boost/serialization/vector.hpp>

#include <algorithm>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

int main(int argc, char* argv[]) {
  namespace fs = boost::filesystem;
  namespace po = boost::program_options;

  try {
    po::options_description options("File report");
    options.add_options()
      ("root", po::value<std::string>()->required(), "directory to scan")
      ("pattern", po::value<std::string>()->required(), "filename regex");

    po::variables_map arguments;
    po::store(po::parse_command_line(argc, argv, options), arguments);
    po::notify(arguments);

    const fs::path root(arguments["root"].as<std::string>());
    const boost::regex pattern(arguments["pattern"].as<std::string>());
    std::vector<std::string> matches;

    for (const auto& item : fs::directory_iterator(root)) {
      const auto name = item.path().filename().string();
      if (fs::is_regular_file(item.status()) && boost::regex_match(name, pattern))
        matches.push_back(name);
    }
    std::sort(matches.begin(), matches.end());

    // Exercise the compiled Serialization library with an actual round trip.
    std::stringstream report;
    {
      boost::archive::text_oarchive out(report);
      out << matches;
    }

    std::vector<std::string> restored;
    {
      boost::archive::text_iarchive in(report);
      in >> restored;
    }
    if (restored != matches || matches.empty())
      return 1;

    for (const auto& name : restored)
      std::cout << name << '\n';
    return 0;
  } catch (const std::exception& e) {
    std::cerr << e.what() << '\n';
    return 2;
  }
}
