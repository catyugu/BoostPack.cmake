# BoostPack.cmake v0.2.1
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

# Fetch sources without auto-configuring the upstream directory.
function(_boostpack_fetch module version repository template out_source out_binary)
  set(url "${template}")
  string(REPLACE "@REPOSITORY@" "${repository}" url "${url}")
  string(REPLACE "@MODULE@" "${module}" url "${url}")
  string(REPLACE "@VERSION@" "${version}" url "${url}")
  string(REPLACE "@TAG@" "boost-${version}" url "${url}")
  set(content_name "boostpack_${module}")
  set(download_options "")
  if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.24)
    list(APPEND download_options DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
  endif()
  set(FETCHCONTENT_TRY_FIND_PACKAGE_MODE NEVER)
  FetchContent_Declare(${content_name}
    URL "${url}"
    SOURCE_SUBDIR "_boostpack_no_auto_configure"
    ${download_options})
  message(STATUS "BoostPack: resolving ${module} from Boost ${version}")
  FetchContent_MakeAvailable(${content_name})
  FetchContent_GetProperties(${content_name} SOURCE_DIR source_dir BINARY_DIR binary_dir)
  set(${out_source} "${source_dir}" PARENT_SCOPE)
  set(${out_binary} "${binary_dir}" PARENT_SCOPE)
endfunction()

# Fetch version-matched upstream CMake helpers only for modules that require
# them (boost_install/boost_message), without growing a metadata registry.
function(_boostpack_needs_support source_dir out_needed)
  file(READ "${source_dir}/CMakeLists.txt" contents)
  if(contents MATCHES "boost_install[ \t\r\n]*\\("
      OR contents MATCHES "boost_message[ \t\r\n]*\\("
      OR contents MATCHES "include[ \t\r\n]*\\([ \t]*Boost(Install|Message|Root|Test)")
    set(${out_needed} TRUE PARENT_SCOPE)
  else()
    set(${out_needed} FALSE PARENT_SCOPE)
  endif()
endfunction()

# Enumerate configured targets from the upstream module's entire CMake tree.
function(_boostpack_targets directory out_targets)
  get_property(targets DIRECTORY "${directory}" PROPERTY BUILDSYSTEM_TARGETS)
  get_property(children DIRECTORY "${directory}" PROPERTY SUBDIRECTORIES)
  foreach(child IN LISTS children)
    _boostpack_targets("${child}" nested)
    list(APPEND targets ${nested})
  endforeach()
  set(${out_targets} "${targets}" PARENT_SCOPE)
endfunction()

# Link properties are evaluated after CMake conditionals, variables, includes
# and functions. Namespaced dependencies may be defined later, at generation.
function(_boostpack_dependencies module source_dir out_deps)
  _boostpack_targets("${source_dir}" targets)
  set(deps "")
  foreach(target IN LISTS targets)
    foreach(prop IN ITEMS LINK_LIBRARIES INTERFACE_LINK_LIBRARIES)
      get_target_property(links "${target}" "${prop}")
      if(NOT links)
        continue()
      endif()
      string(REGEX REPLACE "\\$<TARGET_NAME_IF_EXISTS:Boost::[A-Za-z][A-Za-z0-9_]*>"
        "" links "${links}")
      string(REGEX MATCHALL "Boost::[A-Za-z][A-Za-z0-9_]*" references "${links}")
      foreach(reference IN LISTS references)
        string(SUBSTRING "${reference}" 7 -1 dep)
        # A module's extra exported targets belong to the same repository.
        if(dep STREQUAL module OR dep MATCHES "^${module}_")
          continue()
        endif()
        list(APPEND deps "${dep}")
      endforeach()
    endforeach()
  endforeach()
  list(REMOVE_DUPLICATES deps)
  list(SORT deps)
  set(${out_deps} "${deps}" PARENT_SCOPE)
endfunction()

function(_boostpack_check_cycles modules)
  set(pending ${modules})
  set(ordered "")
  while(pending)
    set(progress FALSE)
    foreach(module IN LISTS pending)
      get_property(deps GLOBAL PROPERTY "BOOSTPACK_DEPS_${module}")
      set(ready TRUE)
      foreach(dep IN LISTS deps)
        if(NOT dep IN_LIST ordered AND dep IN_LIST pending)
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

  # Disable upstream tests and installation only in this function scope.
  set(BUILD_TESTING OFF)
  set(BOOST_SKIP_INSTALL_RULES ON)
  set(BOOST_SUPERPROJECT_VERSION "${BP_VERSION}")

  get_property(loaded GLOBAL PROPERTY BOOSTPACK_MODULES)
  get_property(support_dir GLOBAL PROPERTY BOOSTPACK_SUPPORT_SOURCE)
  if(support_dir)
    list(PREPEND CMAKE_MODULE_PATH "${support_dir}/include")
  endif()

  set(queue ${BP_COMPONENTS})
  while(queue)
    list(POP_FRONT queue module)
    if(module IN_LIST loaded)
      continue()
    endif()
    if(TARGET Boost::${module})
      message(FATAL_ERROR "BoostPack: Boost::${module} already exists outside BoostPack")
    endif()

    _boostpack_fetch("${module}" "${BP_VERSION}" "${repository}" "${template}"
      source_dir binary_dir)
    if(NOT EXISTS "${source_dir}/CMakeLists.txt")
      message(FATAL_ERROR
        "BoostPack: '${module}' has no CMakeLists.txt at '${source_dir}'. "
        "Verify that Boost ${BP_VERSION} contains the module and that the "
        "mirror/cache is populated (offline=${BOOSTPACK_OFFLINE}).")
    endif()

    _boostpack_needs_support("${source_dir}" needs_support)
    if(needs_support)
      if(NOT support_dir)
        _boostpack_fetch("cmake" "${BP_VERSION}" "${repository}" "${template}"
          support_dir support_binary)
        if(NOT EXISTS "${support_dir}/include/BoostInstall.cmake")
          message(FATAL_ERROR
            "BoostPack: missing upstream CMake support for Boost ${BP_VERSION} "
            "at '${support_dir}/include/BoostInstall.cmake'")
        endif()
        set_property(GLOBAL PROPERTY BOOSTPACK_SUPPORT_SOURCE "${support_dir}")
        list(PREPEND CMAKE_MODULE_PATH "${support_dir}/include")
      endif()
      include(BoostInstall)
    endif()

    add_subdirectory("${source_dir}" "${binary_dir}" EXCLUDE_FROM_ALL)
    if(NOT TARGET Boost::${module})
      message(FATAL_ERROR
        "BoostPack: '${module}' did not define Boost::${module} "
        "for Boost ${BP_VERSION}; check upstream CMake support")
    endif()

    _boostpack_dependencies("${module}" "${source_dir}" deps)
    set_property(GLOBAL PROPERTY "BOOSTPACK_DEPS_${module}" "${deps}")
    list(APPEND loaded "${module}")
    set_property(GLOBAL PROPERTY BOOSTPACK_MODULES "${loaded}")
    message(STATUS "BoostPack: added Boost::${module}")
    list(APPEND queue ${deps})
  endwhile()

  _boostpack_check_cycles("${loaded}")
  set_property(GLOBAL PROPERTY BOOSTPACK_VERSION "${BP_VERSION}")
  set_property(GLOBAL PROPERTY BOOSTPACK_REPOSITORY "${repository}")
  set_property(GLOBAL PROPERTY BOOSTPACK_URL_TEMPLATE "${template}")
endfunction()
