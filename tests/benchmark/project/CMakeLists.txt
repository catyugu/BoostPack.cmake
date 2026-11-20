cmake_minimum_required(VERSION 3.22)
project(BoostPackResolutionBenchmark LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../../../cmake/BoostPack.cmake")
boostpack_add(VERSION 1.92.0 COMPONENTS module_00
  REPOSITORY "${BENCH_REPOSITORY}"
  URL_TEMPLATE "@REPOSITORY@/@MODULE@/@TAG@.tar.gz")
get_property(modules GLOBAL PROPERTY BOOSTPACK_MODULES)
list(LENGTH modules count)
if(NOT count EQUAL 24)
  message(FATAL_ERROR "Benchmark expected 24 resolved modules; got ${count}: ${modules}")
endif()
