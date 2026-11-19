cmake_minimum_required(VERSION 3.22)
project(BoostPackIntegration LANGUAGES CXX)
include(CTest)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
boostpack_add(VERSION 1.92.0 COMPONENTS pfr mp11 unordered container charconv)

add_executable(boostpack_smoke smoke.cpp)
target_compile_features(boostpack_smoke PRIVATE cxx_std_20)
target_link_libraries(boostpack_smoke PRIVATE
  Boost::pfr Boost::mp11 Boost::unordered Boost::container Boost::charconv)
add_test(NAME boostpack_smoke COMMAND boostpack_smoke)
