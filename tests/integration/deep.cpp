#include <boost/archive/text_iarchive.hpp>
#include <boost/archive/text_oarchive.hpp>
#include <boost/iostreams/device/back_inserter.hpp>
#include <boost/iostreams/stream.hpp>
#include <boost/program_options.hpp>

#include <sstream>
#include <string>

int main() {
  namespace po = boost::program_options;
  po::options_description options("options");
  options.add_options()("answer", po::value<int>());

  char program[] = "test";
  char argument[] = "--answer=42";
  char* argv[] = {program, argument};
  po::variables_map values;
  po::store(po::parse_command_line(2, argv, options), values);
  po::notify(values);
  if (values["answer"].as<int>() != 42) return 1;

  std::stringstream archive;
  {
    boost::archive::text_oarchive output(archive);
    int saved = 42;
    output << saved;
  }
  {
    boost::archive::text_iarchive input(archive);
    int restored = 0;
    input >> restored;
    if (restored != 42) return 2;
  }

  std::string sink;
  {
    boost::iostreams::stream<boost::iostreams::back_insert_device<std::string>>
      out(boost::iostreams::back_inserter(sink));
    out << "ok";
    out.flush();
  }
  return sink == "ok" ? 0 : 3;
}
