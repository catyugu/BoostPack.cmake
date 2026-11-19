cmake_minimum_required(VERSION 3.22)
project(BoostPackIntegration LANGUAGES CXX)
include(CTest)

set(BOOST_VERSION "1.92.0" CACHE STRING "Boost release to test")
include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
boostpack_add(VERSION "${BOOST_VERSION}" COMPONENTS pfr mp11 unordered container charconv)
# A second call must add only new targets, with no duplicate Boost targets.
boostpack_add(VERSION "${BOOST_VERSION}" COMPONENTS json url multi_index)

add_executable(boostpack_smoke smoke.cpp)
target_compile_features(boostpack_smoke PRIVATE cxx_std_20)
target_link_libraries(boostpack_smoke PRIVATE
  Boost::pfr Boost::mp11 Boost::unordered Boost::container Boost::charconv
  Boost::json Boost::url Boost::multi_index)
add_test(NAME boostpack_smoke COMMAND boostpack_smoke)