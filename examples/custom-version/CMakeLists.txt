cmake_minimum_required(VERSION 3.22)
project(BoostPackCustomVersion LANGUAGES CXX)
include(CTest)

set(BOOST_VERSION "1.89.0" CACHE STRING "Boost release to download")
set(BOOST_MIRROR "https://github.com/boostorg" CACHE STRING "Module repository base URL")
include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
boostpack_add(VERSION "${BOOST_VERSION}" REPOSITORY "${BOOST_MIRROR}"
  COMPONENTS pfr mp11)

add_executable(example_custom_version main.cpp)
target_compile_features(example_custom_version PRIVATE cxx_std_17)
target_link_libraries(example_custom_version PRIVATE Boost::pfr Boost::mp11)
if(BUILD_TESTING)
  add_test(NAME custom_version_example COMMAND example_custom_version)
endif()