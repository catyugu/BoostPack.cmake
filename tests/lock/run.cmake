cmake_minimum_required(VERSION 3.22)

if(NOT REPOSITORY_SOURCE OR NOT TEST_BINARY_DIR)
  message(FATAL_ERROR "Missing runner arguments")
endif()
set(root "${TEST_BINARY_DIR}")
file(REMOVE_RECURSE "${root}")
file(MAKE_DIRECTORY "${root}/staging" "${root}/archives")

foreach(module IN ITEMS foo bar support cmake)
  set(mod_dir "${root}/staging/${module}")
  file(MAKE_DIRECTORY "${mod_dir}")
  if(module STREQUAL "cmake")
    file(MAKE_DIRECTORY "${mod_dir}/include")
    file(WRITE "${mod_dir}/include/BoostInstall.cmake"
      "function(boost_install)\n  if(NOT BOOST_SKIP_INSTALL_RULES)\n    message(FATAL_ERROR \"Installation must be disabled\")\n  endif()\nendfunction()\n")
  else()
    set(content "add_library(boost_${module} INTERFACE)\nadd_library(Boost::${module} ALIAS boost_${module})\n")
    if(module STREQUAL "foo")
      string(APPEND content "target_link_libraries(boost_foo INTERFACE Boost::bar)\n")
    elseif(module STREQUAL "support")
      string(APPEND content "boost_install(TARGETS boost_support VERSION \${BOOST_SUPERPROJECT_VERSION})\n")
    endif()
    file(WRITE "${mod_dir}/CMakeLists.txt" "${content}")
  endif()
  file(MAKE_DIRECTORY "${root}/archives/${module}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar czf
      "${root}/archives/${module}/boost-1.91.0.tar.gz" "${module}"
    WORKING_DIRECTORY "${root}/staging" RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Failed to create module archive for ${module}")
  endif()
endforeach()

if(WIN32)
  set(repository "file:///${root}/archives")
else()
  set(repository "file://${root}/archives")
endif()
set(lock "${root}/boostpack.lock.json")
set(cache "${root}/cache")

function(check_case name expected_success expected_message)
  set(build "${root}/${name}")
  set(args ${ARGN})
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${REPOSITORY_SOURCE}/tests/lock/project"
      -B "${build}"
      "-DLOCK_REPOSITORY=${repository}"
      "-DTEST_BINARY_DIR=${root}"
      "-DBOOSTPACK_CACHE_DIR=${cache}"
      "-DBOOSTPACK_LOCKFILE=${lock}"
      ${args}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE stdout ERROR_VARIABLE stderr)
  if(expected_success)
    if(NOT result EQUAL 0)
      message(FATAL_ERROR "${name} must succeed, but failed:\n${stdout}\n${stderr}")
    endif()
  elseif(result EQUAL 0)
    message(FATAL_ERROR "${name} must fail, but passed")
  elseif(NOT "${stdout}\n${stderr}" MATCHES "${expected_message}")
    message(FATAL_ERROR "${name} failed for wrong reason. Expected: ${expected_message}\n${stdout}\n${stderr}")
  endif()
endfunction()

check_case(create TRUE "")
if(NOT EXISTS "${lock}")
  message(FATAL_ERROR "Lockfile was not written")
endif()
file(READ "${lock}" data)
string(JSON count LENGTH "${data}" modules)
if(NOT count EQUAL 4)
  message(FATAL_ERROR "Expected 4 locked archives including the CMake support files, found ${count}")
endif()
foreach(module IN ITEMS foo bar support cmake)
  string(JSON hash GET "${data}" modules "${module}" sha256)
  file(SHA256 "${root}/archives/${module}/boost-1.91.0.tar.gz" reference_hash)
  if(NOT hash STREQUAL reference_hash)
    message(FATAL_ERROR "Wrong sha256 recorded for ${module}")
  endif()
endforeach()

check_case(read_fresh TRUE "")
# A present but corrupted ready marker must trigger re-extraction on reconfigure.
string(JSON foo_hash GET "${data}" modules foo sha256)
string(SUBSTRING "${foo_hash}" 0 24 foo_short_hash)
set(foo_ready "${root}/read_fresh/_boostpack_sources/foo/${foo_short_hash}/.boostpack-ready")
if(NOT EXISTS "${foo_ready}")
  message(FATAL_ERROR "Expected extraction completion marker not found")
endif()
file(WRITE "${foo_ready}" "invalid-marker\n")
check_case(read_fresh TRUE "")
file(READ "${foo_ready}" repaired_marker)
string(STRIP "${repaired_marker}" repaired_marker)
if(NOT repaired_marker STREQUAL foo_hash)
  message(FATAL_ERROR "Corrupt extraction marker was not repaired")
endif()
check_case(read_offline TRUE "" -DBOOSTPACK_OFFLINE=ON)
# Calculate the cache identity from the manifest's repository and URL template.
set(template "@REPOSITORY@/@MODULE@/@TAG@.tar.gz")
string(SHA256 repo_hash "${repository}\n${template}")
string(SUBSTRING "${repo_hash}" 0 12 key)
set(foo_archive "${cache}/boost-1.91.0/${key}/archives/foo.tar.gz")
if(NOT EXISTS "${foo_archive}")
  message(FATAL_ERROR "Expected cached archive not found: ${foo_archive}")
endif()
file(RENAME "${foo_archive}" "${foo_archive}.saved")
check_case(missing_archive FALSE "offline cache is missing" -DBOOSTPACK_OFFLINE=ON)
check_case(redownload TRUE "")
file(APPEND "${foo_archive}" "tampering")
check_case(corrupt_archive FALSE "SHA256 mismatch for cached" -DBOOSTPACK_OFFLINE=ON)
file(REMOVE "${foo_archive}")
file(RENAME "${foo_archive}.saved" "${foo_archive}")

check_case(version_mismatch FALSE "boost_version mismatch"
   -DTEST_BOOST_VERSION=1.90.0)
check_case(repository_mismatch FALSE "repository mismatch"
   -DLOCK_REPOSITORY=file:///invalid-source)

string(JSON reduced REMOVE "${data}" modules bar)
file(WRITE "${root}/missing.lock.json" "${reduced}\n")
set(lock "${root}/missing.lock.json")
check_case(missing_module FALSE "module 'bar' is missing from the lockfile")

file(WRITE "${root}/malformed.lock.json" "this is not JSON\n")
set(lock "${root}/malformed.lock.json")
check_case(malformed FALSE "invalid lockfile schema")

# New lockfiles must be created online; archived sources may be reused offline.
set(lock "${root}/nonexistent.lock.json")
check_case(offline_new_lock FALSE "cannot create lockfile while offline"
  -DBOOSTPACK_OFFLINE=ON)
set(lock "${root}/boostpack.lock.json")
check_case(insecure_source FALSE "archive URL must use HTTPS or file://"
  -DBOOSTPACK_LOCKFILE= -DLOCK_REPOSITORY=http://invalid.example/source)

# Missing/extra manifest entries must fail instead of silently resolving a new
# dependency graph that no longer matches the committed lockfile.
string(JSON extra SET "${data}" modules extra "{\"sha256\":\"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\",\"url\":\"file:///invalid\"}")
file(WRITE "${root}/extra.lock.json" "${extra}\n")
set(lock "${root}/extra.lock.json")
check_case(extra_entry FALSE "dependency closure mismatch")

message(STATUS "Lockfile, multi-call closure, offline and archive corruption tests passed")
