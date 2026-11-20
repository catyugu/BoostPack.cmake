cmake_minimum_required(VERSION 3.22)
project(BoostPackArchiveMirror LANGUAGES NONE)

# A host FetchContent dependency intentionally uses the former BoostPack name.
# BoostPack must neither inspect nor mutate these unrelated native settings.
include(FetchContent)
set(FETCHCONTENT_BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}/foreign-fetch-cache")
set(FETCHCONTENT_FULLY_DISCONNECTED ON)
FetchContent_Declare(boostpack_foo URL "https://invalid.example/not-used.tar.gz")
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
# Both systems must retain ownership of their own cache and offline behavior.
if(NOT FETCHCONTENT_BASE_DIR STREQUAL "${CMAKE_CURRENT_BINARY_DIR}/foreign-fetch-cache"
    OR NOT FETCHCONTENT_FULLY_DISCONNECTED)
  message(FATAL_ERROR "BoostPack modified host FetchContent settings")
endif()
FetchContent_GetProperties(boostpack_foo)
if(boostpack_foo_POPULATED)
  message(FATAL_ERROR "BoostPack populated an unrelated FetchContent declaration")
endif()
