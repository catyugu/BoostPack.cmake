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

function(run_case label directory offline)
  execute_process(COMMAND "${CMAKE_COMMAND}" -E time "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_LIST_DIR}/project" -B "${root}/${directory}"
      "-DBENCH_REPOSITORY=${repository}"
      "-DBOOSTPACK_CACHE_DIR=${root}/cache"
      "-DBOOSTPACK_OFFLINE=${offline}"
    RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE error)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "${label} configure failed:\n${output}\n${error}")
  endif()
  string(REGEX MATCH "Elapsed time \\(seconds\\): ([0-9.]+)" elapsed "${output}\n${error}")
  if(NOT elapsed)
    message(FATAL_ERROR "Could not parse CMake -E time output: ${error}")
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
