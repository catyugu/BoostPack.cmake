cmake_minimum_required(VERSION 3.22)
project(BoostPackIntegration LANGUAGES CXX)
include(CTest)

set(BOOST_VERSION "1.92.0" CACHE STRING "Boost release to test")
option(BOOSTPACK_INTEGRATION_EXTENDED "Test complex upstream Boost CMake projects" OFF)
option(BOOSTPACK_INTEGRATION_DEEP "Test additional compiled Boost libraries" OFF)
option(BOOSTPACK_INTEGRATION_HEAVY "Test assembler-dependent Boost libraries" OFF)
include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
boostpack_add(VERSION "${BOOST_VERSION}" COMPONENTS pfr mp11 unordered container charconv)
boostpack_add(VERSION "${BOOST_VERSION}" COMPONENTS json url multi_index)

add_executable(boostpack_smoke smoke.cpp)
target_compile_features(boostpack_smoke PRIVATE cxx_std_20)
target_link_libraries(boostpack_smoke PRIVATE
  Boost::pfr Boost::mp11 Boost::unordered Boost::container Boost::charconv
  Boost::json Boost::url Boost::multi_index)
add_test(NAME boostpack_smoke COMMAND boostpack_smoke)

if(BOOSTPACK_INTEGRATION_EXTENDED)
  boostpack_add(VERSION "${BOOST_VERSION}"
    COMPONENTS asio filesystem regex stacktrace thread)
  add_executable(boostpack_extended extended.cpp)
  target_compile_features(boostpack_extended PRIVATE cxx_std_20)
  target_link_libraries(boostpack_extended PRIVATE
    Boost::asio Boost::filesystem Boost::regex Boost::stacktrace Boost::thread)
  add_test(NAME boostpack_extended COMMAND boostpack_extended)
endif()

if(BOOSTPACK_INTEGRATION_DEEP)
  boostpack_add(VERSION "${BOOST_VERSION}" COMPONENTS program_options serialization iostreams)
  add_executable(boostpack_deep deep.cpp)
  target_compile_features(boostpack_deep PRIVATE cxx_std_20)
  target_link_libraries(boostpack_deep PRIVATE
    Boost::program_options Boost::serialization Boost::iostreams)
  add_test(NAME boostpack_deep COMMAND boostpack_deep)
endif()

if(BOOSTPACK_INTEGRATION_HEAVY)
  boostpack_add(VERSION "${BOOST_VERSION}" COMPONENTS context coroutine fiber)
  add_executable(boostpack_heavy heavy.cpp)
  target_compile_features(boostpack_heavy PRIVATE cxx_std_20)
  target_link_libraries(boostpack_heavy PRIVATE
    Boost::context Boost::coroutine Boost::fiber)
  add_test(NAME boostpack_heavy COMMAND boostpack_heavy)
endif()
