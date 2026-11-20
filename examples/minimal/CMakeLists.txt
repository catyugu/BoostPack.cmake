cmake_minimum_required(VERSION 3.22)
project(BoostPackExample LANGUAGES CXX)
include(CTest)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
boostpack_add(VERSION 1.92.0 COMPONENTS pfr)

add_executable(example main.cpp)
target_compile_features(example PRIVATE cxx_std_20)
target_link_libraries(example PRIVATE Boost::pfr)
if(BUILD_TESTING)
  add_test(NAME minimal_example COMMAND example)
endif()
