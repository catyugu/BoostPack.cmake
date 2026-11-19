cmake_minimum_required(VERSION 3.22)
project(BoostPack VERSION 0.2.0 LANGUAGES CXX)

include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
