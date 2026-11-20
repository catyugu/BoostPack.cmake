cmake_minimum_required(VERSION 3.22)
project(BoostPackCliReport LANGUAGES CXX)
include(CTest)

# All Boost DLLs and the example executable share a runtime directory on
# Windows; CMake supplies build-tree RPATHs for shared libraries on Unix.
set(BUILD_SHARED_LIBS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin")

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
boostpack_add(VERSION 1.92.0 COMPONENTS
  program_options filesystem regex serialization)

add_executable(boostpack_cli_report main.cpp)
target_compile_features(boostpack_cli_report PRIVATE cxx_std_17)
target_link_libraries(boostpack_cli_report PRIVATE
  Boost::program_options Boost::filesystem Boost::regex Boost::serialization)

if(BUILD_TESTING)
  add_test(NAME cli_report_example
    COMMAND boostpack_cli_report
      --root "${CMAKE_CURRENT_SOURCE_DIR}"
      --pattern "CMakeLists[.]txt")
endif()
