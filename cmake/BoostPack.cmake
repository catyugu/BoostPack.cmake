# BoostPack.cmake v0.2.0
# Copyright (c) 2026 Catyugu
# SPDX-License-Identifier: MIT
#
# On-demand Boost module source resolution and native CMake target integration.
# Consumer requirements: CMake 3.22+ and a C++ compiler. No metadata registry.

if(CMAKE_VERSION VERSION_LESS 3.22)
  message(FATAL_ERROR "BoostPack requires CMake 3.22 or newer")
endif()

include_guard(GLOBAL)
include(FetchContent)

set(BOOSTPACK_REPOSITORY "https://github.com/boostorg" CACHE STRING
  "Base URL of Boost module repositories (GitHub by default)")
set(BOOSTPACK_URL_TEMPLATE "" CACHE STRING
  "Archive URL template with @REPOSITORY@, @MODULE@ and @TAG@ tokens")
set(BOOSTPACK_CACHE_DIR "" CACHE PATH
  "Optional shared directory for downloaded Boost module source archives")
option(BOOSTPACK_OFFLINE "Use already populated Boost sources without network" OFF)

# Module dependencies are discovered from the CMake project shipped in each
# selected Boost repository at the requested release tag. Inspecting the
# upstream target references avoids maintaining a version-specific registry.
function(_boostpack_dependencies module source_dir out_deps)
  file(READ "${source_dir}/CMakeLists.txt" contents)
  # Exclude commented references (for example, documentation examples).
  string(REGEX REPLACE "#[^\r\n]*" "" contents "${contents}")
  string(REGEX MATCHALL "Boost::[A-Za-z][A-Za-z0-9_]*" references "${contents}")
  set(deps "")
  foreach(reference IN LISTS references)
    string(SUBSTRING "${reference}" 7 -1 dep)
    # Boost::<module> is the module's own alias; Boost::<module>_detail etc.
    # can be extra targets provided by the same upstream repository.
    if(dep STREQUAL module OR dep MATCHES "^${module}_")
      continue()
    endif()
    list(APPEND deps "${dep}")
  endforeach()
  list(REMOVE_DUPLICATES deps)
  list(SORT deps)
  set(${out_deps} "${deps}" PARENT_SCOPE)
endfunction()

function(boostpack_add)
  cmake_parse_arguments(BP "" "VERSION;REPOSITORY;URL_TEMPLATE" "COMPONENTS" ${ARGN})
  if(BP_UNPARSED_ARGUMENTS OR BP_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "BoostPack: invalid arguments to boostpack_add()")
  endif()
  if(NOT BP_VERSION OR NOT BP_COMPONENTS)
    message(FATAL_ERROR "BoostPack: boostpack_add(VERSION <version> COMPONENTS <modules...>) is required")
  endif()
  if(NOT BP_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR "BoostPack: expected a Boost release version such as 1.92.0, got '${BP_VERSION}'")
  endif()
  foreach(module IN LISTS BP_COMPONENTS)
    if(NOT module MATCHES "^[a-z][a-z0-9_]*$")
      message(FATAL_ERROR "BoostPack: invalid Boost module name '${module}'")
    endif()
  endforeach()

  if(BP_REPOSITORY)
    set(repository "${BP_REPOSITORY}")
  else()
    set(repository "${BOOSTPACK_REPOSITORY}")
  endif()
  string(REGEX REPLACE "/+$" "" repository "${repository}")
  if(NOT repository)
    message(FATAL_ERROR "BoostPack: REPOSITORY must not be empty")
  endif()
  if(BP_URL_TEMPLATE)
    set(template "${BP_URL_TEMPLATE}")
  elseif(BOOSTPACK_URL_TEMPLATE)
    set(template "${BOOSTPACK_URL_TEMPLATE}")
  else()
    set(template "@REPOSITORY@/@MODULE@/archive/refs/tags/@TAG@.tar.gz")
  endif()
  if(NOT template MATCHES "@MODULE@" OR NOT template MATCHES "@TAG@|@VERSION@")
    message(FATAL_ERROR "BoostPack: URL_TEMPLATE must include @MODULE@ and @TAG@ or @VERSION@")
  endif()

  get_property(loaded_version GLOBAL PROPERTY BOOSTPACK_VERSION)
  get_property(loaded_repository GLOBAL PROPERTY BOOSTPACK_REPOSITORY)
  get_property(loaded_template GLOBAL PROPERTY BOOSTPACK_URL_TEMPLATE)
  if(loaded_version AND NOT loaded_version STREQUAL BP_VERSION)
    message(FATAL_ERROR "BoostPack: Boost ${loaded_version} is already loaded; cannot also load ${BP_VERSION}")
  endif()
  if(loaded_repository AND NOT loaded_repository STREQUAL repository)
    message(FATAL_ERROR "BoostPack: repository cannot change in the same CMake configure")
  endif()
  if(loaded_template AND NOT loaded_template STREQUAL template)
    message(FATAL_ERROR "BoostPack: URL_TEMPLATE cannot change in the same CMake configure")
  endif()

  # Keep sources for different releases and mirrors separate even when the
  # same build tree or shared cache directory is reused by multiple projects.
  string(SHA256 repository_hash "${repository}\n${template}")
  string(SUBSTRING "${repository_hash}" 0 12 cache_key)
  if(BOOSTPACK_CACHE_DIR)
    get_filename_component(cache_root "${BOOSTPACK_CACHE_DIR}" ABSOLUTE
      BASE_DIR "${CMAKE_BINARY_DIR}")
  else()
    set(cache_root "${CMAKE_BINARY_DIR}/_boostpack")
  endif()
  set(FETCHCONTENT_BASE_DIR "${cache_root}/boost-${BP_VERSION}/${cache_key}")
  if(BOOSTPACK_OFFLINE)
    set(FETCHCONTENT_FULLY_DISCONNECTED ON)
  endif()

  # Other CMake projects may use BUILD_TESTING. Only disable it in the local
  # scope from which upstream Boost add_subdirectory() is called.
  set(BUILD_TESTING OFF)
  set(BOOST_SUPERPROJECT_VERSION "${BP_VERSION}")

  set(download_options "")
  if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.24)
    list(APPEND download_options DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
  endif()

  # Discovery fetches sources (not built libraries) before registering targets.
  # This is a fixed-point calculation: newly discovered modules join the queue.
  get_property(loaded GLOBAL PROPERTY BOOSTPACK_MODULES)
  set(queue ${BP_COMPONENTS})
  set(required "")
  while(queue)
    list(POP_FRONT queue module)
    if(module IN_LIST required)
      continue()
    endif()

    set(content_name "boostpack_${module}")
    set(url "${template}")
    string(REPLACE "@REPOSITORY@" "${repository}" url "${url}")
    string(REPLACE "@MODULE@" "${module}" url "${url}")
    string(REPLACE "@VERSION@" "${BP_VERSION}" url "${url}")
    string(REPLACE "@TAG@" "boost-${BP_VERSION}" url "${url}")
    FetchContent_Declare(${content_name}
      URL "${url}"
      SOURCE_SUBDIR "_boostpack_no_auto_configure"
      ${download_options}
    )
    message(STATUS "BoostPack: resolving ${module} from Boost ${BP_VERSION}")
    FetchContent_MakeAvailable(${content_name})
    FetchContent_GetProperties(${content_name} SOURCE_DIR source_dir)
    if(NOT EXISTS "${source_dir}/CMakeLists.txt")
      message(FATAL_ERROR
        "BoostPack: '${module}' has no CMakeLists.txt at '${source_dir}'. "
        "Verify that Boost ${BP_VERSION} contains the module and that the "
        "mirror/cache is populated (offline=${BOOSTPACK_OFFLINE}).")
    endif()
    _boostpack_dependencies("${module}" "${source_dir}" deps)
    set_property(GLOBAL PROPERTY "BOOSTPACK_DEPS_${module}" "${deps}")
    list(APPEND required "${module}")
    list(APPEND queue ${deps})
  endwhile()

  # Dependencies must be available when upstream target_link_libraries() runs.
  set(pending ${required})
  set(ordered "")
  while(pending)
    set(progress FALSE)
    foreach(module IN LISTS pending)
      get_property(deps GLOBAL PROPERTY "BOOSTPACK_DEPS_${module}")
      set(ready TRUE)
      foreach(dep IN LISTS deps)
        if(NOT dep IN_LIST ordered AND NOT dep IN_LIST loaded)
          set(ready FALSE)
          break()
        endif()
      endforeach()
      if(ready)
        list(APPEND ordered "${module}")
        list(REMOVE_ITEM pending "${module}")
        set(progress TRUE)
      endif()
    endforeach()
    if(NOT progress)
      message(FATAL_ERROR "BoostPack: cyclic Boost module dependencies: ${pending}")
    endif()
  endwhile()

  foreach(module IN LISTS ordered)
    if(TARGET Boost::${module} AND NOT module IN_LIST loaded)
      message(FATAL_ERROR "BoostPack: Boost::${module} already exists outside BoostPack")
    endif()
  endforeach()

  foreach(module IN LISTS ordered)
    if(module IN_LIST loaded)
      continue()
    endif()
    set(content_name "boostpack_${module}")
    FetchContent_GetProperties(${content_name}
      SOURCE_DIR source_dir BINARY_DIR binary_dir)
    add_subdirectory("${source_dir}" "${binary_dir}" EXCLUDE_FROM_ALL)
    if(NOT TARGET Boost::${module})
      message(FATAL_ERROR
        "BoostPack: ${module} did not define Boost::${module} "
        "for Boost ${BP_VERSION}; check upstream CMake support")
    endif()
    list(APPEND loaded "${module}")
    set_property(GLOBAL PROPERTY BOOSTPACK_MODULES "${loaded}")
    message(STATUS "BoostPack: added Boost::${module}")
  endforeach()
  set_property(GLOBAL PROPERTY BOOSTPACK_VERSION "${BP_VERSION}")
  set_property(GLOBAL PROPERTY BOOSTPACK_REPOSITORY "${repository}")
  set_property(GLOBAL PROPERTY BOOSTPACK_URL_TEMPLATE "${template}")
endfunction()