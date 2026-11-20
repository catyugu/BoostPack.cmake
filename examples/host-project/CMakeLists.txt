cmake_minimum_required(VERSION 3.22)
project(BoostPackHostProject LANGUAGES CXX)
include(CTest)
include(FetchContent)

# The host owns its native FetchContent settings and dependencies. Even a
# similarly named FetchContent declaration remains independent of BoostPack.
set(FETCHCONTENT_BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}/host-deps")
set(FETCHCONTENT_FULLY_DISCONNECTED ON)
FetchContent_Declare(boostpack_pfr
  SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/host-dependency")
FetchContent_MakeAvailable(boostpack_pfr)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
# Keep this example's archive cache and lockfile inside its build directory.
# Values supplied by the consumer (or CI) still take precedence.
if(NOT BOOSTPACK_CACHE_DIR)
  set(BOOSTPACK_CACHE_DIR "${CMAKE_CURRENT_BINARY_DIR}/archive-cache")
endif()
if(NOT BOOSTPACK_LOCKFILE)
  set(BOOSTPACK_LOCKFILE "${CMAKE_CURRENT_BINARY_DIR}/boostpack.lock.json")
endif()

boostpack_add(VERSION 1.92.0 COMPONENTS pfr)
boostpack_add(VERSION 1.92.0 COMPONENTS describe mp11 pfr)

FetchContent_GetProperties(boostpack_pfr)
if(NOT boostpack_pfr_POPULATED OR NOT TARGET host_dependency
    OR NOT FETCHCONTENT_FULLY_DISCONNECTED
    OR NOT FETCHCONTENT_BASE_DIR STREQUAL "${CMAKE_CURRENT_BINARY_DIR}/host-deps")
  message(FATAL_ERROR "BoostPack interfered with the host's FetchContent")
endif()
foreach(module IN ITEMS pfr describe mp11)
  if(NOT TARGET Boost::${module})
    message(FATAL_ERROR "Missing Boost::${module} after incremental calls")
  endif()
endforeach()

add_executable(host_example main.cpp)
target_compile_features(host_example PRIVATE cxx_std_17)
target_link_libraries(host_example PRIVATE
  host_dependency Boost::pfr Boost::describe Boost::mp11)

if(BUILD_TESTING)
  # BoostPack resolves relative cache paths from the build tree and relative
  # lockfile paths from the source tree. Pass absolute paths to the fresh build.
  get_filename_component(shared_cache "${BOOSTPACK_CACHE_DIR}" ABSOLUTE
    BASE_DIR "${CMAKE_BINARY_DIR}")
  get_filename_component(shared_lock "${BOOSTPACK_LOCKFILE}" ABSOLUTE
    BASE_DIR "${CMAKE_SOURCE_DIR}")
  add_test(NAME host_example_run COMMAND host_example)
  # The first configure writes the lockfile. Replay the same source in a
  # *different* build tree, with downloads disabled and the original cache.
  add_test(NAME host_fresh_offline_configure
    COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}"
      -B "${CMAKE_CURRENT_BINARY_DIR}/fresh-offline"
      "-DBUILD_TESTING:BOOL=OFF"
      "-DBOOSTPACK_OFFLINE:BOOL=ON"
      "-DBOOSTPACK_CACHE_DIR:PATH=${shared_cache}"
      "-DBOOSTPACK_LOCKFILE:FILEPATH=${shared_lock}")
  set_tests_properties(host_fresh_offline_configure PROPERTIES
    DEPENDS host_example_run)
endif()
