cmake_minimum_required(VERSION 3.22)
project(BoostPackJsonExample LANGUAGES CXX)
include(CTest)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
boostpack_add(VERSION 1.92.0 COMPONENTS json url)

add_executable(boostpack_json_example main.cpp)
target_compile_features(boostpack_json_example PRIVATE cxx_std_20)
target_link_libraries(boostpack_json_example PRIVATE Boost::json Boost::url)

if(BUILD_TESTING)
  add_test(NAME json_url_example COMMAND boostpack_json_example)
endif()
