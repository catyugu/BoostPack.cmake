cmake_minimum_required(VERSION 3.22)

if(NOT BENCH_ROOT)
  set(BENCH_ROOT "${CMAKE_CURRENT_BINARY_DIR}/boostpack-benchmark")
endif()
get_filename_component(root "${BENCH_ROOT}" ABSOLUTE)
file(REMOVE_RECURSE "${root}")
set(staging "${root}/staging")
set(mirror "${root}/mirror")
file(MAKE_DIRECTORY "${staging}" "${mirror}")

# Local synthetic modules: 24 repositories forming a transitive chain.
# Archive preparation is excluded from configure timings.
foreach(index RANGE 0 23)
  if(index LESS 10)
    set(suffix "0${index}")
  else()
    set(suffix "${index}")
  endif()
  set(module "module_${suffix}")
  set(src "${staging}/${module}")
  file(MAKE_DIRECTORY "${src}" "${mirror}/${module}")
  set(definition "add_library(boost_${module} INTERFACE)\nadd_library(Boost::${module} ALIAS boost_${module})\n")
  if(index LESS 23)
    math(EXPR next_index "${index}+1")
    if(next_index LESS 10)
      set(next "0${next_index}")
    else()
      set(next "${next_index}")
    endif()
    string(APPEND definition "target_link_libraries(boost_${module} INTERFACE Boost::module_${next})\n")
  endif()
  file(WRITE "${src}/CMakeLists.txt" "${definition}")
  execute_process(COMMAND "${CMAKE_COMMAND}" -E tar czf
      "${mirror}/${module}/boost-1.92.0.tar.gz" "${module}"
    WORKING_DIRECTORY "${staging}" RESULT_VARIABLE status)
  if(NOT status EQUAL 0)
    message(FATAL_ERROR "Cannot create synthetic archive for ${module}")
  endif()
endforeach()

if(WIN32)
  set(repository "file:///${mirror}")
else()
  set(repository "file://${mirror}")
endif()
file(WRITE "${root}/results.csv" "scenario,seconds\n")

# CTest's JUnit testcase duration is fractional wall-clock time on CMake 3.22;
# cmake -E time on that version reports wall time in whole seconds only.
file(MAKE_DIRECTORY "${root}/timer")
file(WRITE "${root}/timer/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.22)
project(BoostPackBenchmarkTimer LANGUAGES NONE)
enable_testing()
add_test(NAME configure COMMAND "${CMAKE_COMMAND}"
  -S "${BENCH_SOURCE}" -B "${BENCH_BUILD}"
  "-DBENCH_REPOSITORY=${BENCH_REPOSITORY}"
  "-DBOOSTPACK_CACHE_DIR=${BENCH_CACHE}"
  "-DBOOSTPACK_OFFLINE=${BENCH_OFFLINE}")
]=])

function(run_case label directory offline)
  execute_process(COMMAND "${CMAKE_COMMAND}"
      -S "${root}/timer" -B "${root}/timer-build"
      "-DBENCH_SOURCE=${CMAKE_CURRENT_LIST_DIR}/project"
      "-DBENCH_BUILD=${root}/${directory}"
      "-DBENCH_REPOSITORY=${repository}"
      "-DBENCH_CACHE=${root}/cache"
      "-DBENCH_OFFLINE=${offline}"
    RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE error)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "${label} timer configuration failed:\n${output}\n${error}")
  endif()
  execute_process(COMMAND "${CMAKE_CTEST_COMMAND}"
      --test-dir "${root}/timer-build"
      --output-junit "${root}/${label}.xml"
      --output-on-failure
    RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE error)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "${label} configure failed:\n${output}\n${error}")
  endif()
  file(READ "${root}/${label}.xml" report)
  string(REGEX MATCH "<testcase[^>]*time=\"([0-9]+([.][0-9]+)?)\"" testcase "${report}")
  if(NOT testcase)
    message(FATAL_ERROR "Could not parse CTest JUnit duration:\n${report}")
  endif()
  set(seconds "${CMAKE_MATCH_1}")
  file(APPEND "${root}/results.csv" "${label},${seconds}\n")
  message(STATUS "${label}: ${seconds} s")
endfunction()

message(STATUS "BoostPack resolution benchmark: 24 synthetic modules, CMake ${CMAKE_VERSION}")
run_case(cold cold OFF)
run_case(warm warm ON)
run_case(reconfigure warm ON)
message(STATUS "Results: ${root}/results.csv")
