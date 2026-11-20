cmake_minimum_required(VERSION 3.22)
project(BoostPack VERSION 0.3.3 LANGUAGES NONE)

include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
