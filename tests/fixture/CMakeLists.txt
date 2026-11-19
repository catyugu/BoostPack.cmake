cmake_minimum_required(VERSION 3.22)
project(BoostPackFixture LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
set(BOOSTPACK_OFFLINE ON)

# Provide a synthetic, header-only module for every entry in the registry.
# FetchContent's SOURCE_DIR override exercises the real dependency graph and
# CMake target wiring without accessing a network or installing Boost.
set(modules
  assert charconv config container container_hash core describe dynamic_bitset
  endian intrusive io move mp11 pfr predef preprocessor scope static_string
  throw_exception type_traits unordered utility uuid
)
foreach(module IN LISTS modules)
  set(dir "${CMAKE_CURRENT_BINARY_DIR}/fakes/${module}")
  file(MAKE_DIRECTORY "${dir}")
  file(WRITE "${dir}/CMakeLists.txt"
    "add_library(boost_${module} INTERFACE)\n"
    "add_library(Boost::${module} ALIAS boost_${module})\n"
  )
  string(TOUPPER "${module}" upper)
  set(FETCHCONTENT_SOURCE_DIR_BOOSTPACK_${upper} "${dir}")
endforeach()

if(TEST_CASE STREQUAL "minimal")
  boostpack_add(VERSION 1.92.0 COMPONENTS pfr mp11)
  get_property(loaded GLOBAL PROPERTY BOOSTPACK_MODULES)
  list(LENGTH loaded count)
  if(NOT count EQUAL 2 OR NOT TARGET Boost::pfr OR NOT TARGET Boost::mp11)
    message(FATAL_ERROR "Minimal dependency set is wrong: ${loaded}")
  endif()
elseif(TEST_CASE STREQUAL "full")
  boostpack_add(VERSION 1.92.0 COMPONENTS
    unordered container pfr mp11 describe endian scope container_hash charconv
    intrusive dynamic_bitset static_string uuid)
  get_property(loaded GLOBAL PROPERTY BOOSTPACK_MODULES)
  list(LENGTH loaded count)
  if(NOT count EQUAL 23)
    message(FATAL_ERROR "Expected 23 modules, got ${count}: ${loaded}")
  endif()
  foreach(module IN LISTS modules)
    if(NOT TARGET Boost::${module})
      message(FATAL_ERROR "Missing Boost::${module}")
    endif()
  endforeach()
elseif(TEST_CASE STREQUAL "incremental")
  boostpack_add(VERSION 1.92.0 COMPONENTS pfr)
  boostpack_add(VERSION 1.92.0 COMPONENTS unordered container pfr)
  get_property(loaded GLOBAL PROPERTY BOOSTPACK_MODULES)
  list(REMOVE_DUPLICATES loaded)
  list(LENGTH loaded count)
  if(NOT count EQUAL 13)
    message(FATAL_ERROR "Unexpected incremental closure (${count}): ${loaded}")
  endif()
elseif(TEST_CASE STREQUAL "reinclude")
  include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
  boostpack_add(VERSION 1.92.0 COMPONENTS mp11)
  boostpack_add(VERSION 1.92.0 COMPONENTS mp11)
elseif(TEST_CASE STREQUAL "collision")
  add_library(foreign_pfr INTERFACE)
  add_library(Boost::pfr ALIAS foreign_pfr)
  boostpack_add(VERSION 1.92.0 COMPONENTS pfr)
elseif(TEST_CASE STREQUAL "unsupported")
  boostpack_add(VERSION 1.92.0 COMPONENTS asio)
elseif(TEST_CASE STREQUAL "version_conflict")
  boostpack_add(VERSION 1.92.0 COMPONENTS pfr)
  boostpack_add(VERSION 1.91.0 COMPONENTS mp11)
elseif(TEST_CASE STREQUAL "missing_offline")
  unset(FETCHCONTENT_SOURCE_DIR_BOOSTPACK_PFR)
  set(BOOSTPACK_CACHE_DIR "${CMAKE_CURRENT_BINARY_DIR}/uncached")
  boostpack_add(VERSION 1.92.0 COMPONENTS pfr)
elseif(TEST_CASE STREQUAL "invalid_arguments")
  boostpack_add(VERSION 1.92.0)
else()
  message(FATAL_ERROR "Unknown TEST_CASE '${TEST_CASE}'")
endif()
