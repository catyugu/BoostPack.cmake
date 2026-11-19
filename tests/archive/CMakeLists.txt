cmake_minimum_required(VERSION 3.22)
project(BoostPackArchiveMirror LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/BoostPack.cmake")
set(archive_dir "${CMAKE_CURRENT_BINARY_DIR}/archive")
set(staging "${CMAKE_CURRENT_BINARY_DIR}/staging")
foreach(module IN ITEMS foo bar)
  file(MAKE_DIRECTORY "${archive_dir}/${module}" "${staging}/${module}")
  set(definition "add_library(boost_${module} INTERFACE)\nadd_library(Boost::${module} ALIAS boost_${module})\n")
  if(module STREQUAL "foo")
    string(APPEND definition "target_link_libraries(boost_foo INTERFACE Boost::bar)\n")
  endif()
  file(WRITE "${staging}/${module}/CMakeLists.txt" "${definition}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar czf
      "${archive_dir}/${module}/boost-1.91.0.tar.gz" "${module}"
    WORKING_DIRECTORY "${staging}" RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Cannot construct fake mirror archive: ${module}")
  endif()
endforeach()

boostpack_add(VERSION 1.91.0
  REPOSITORY "file://${archive_dir}"
  URL_TEMPLATE "@REPOSITORY@/@MODULE@/@TAG@.tar.gz"
  COMPONENTS foo)
if(NOT TARGET Boost::bar OR NOT TARGET Boost::foo)
  message(FATAL_ERROR "Mirrored source was not downloaded or resolved")
endif()