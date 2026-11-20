foreach(case IN ITEMS
    minimal closure incremental reinclude repository template
    conditional included dynamic nested optional support nested_support
    genex genex_inactive_unknown genex_bad genex_bad_condition genex_config_exclusive genex_target_exists
    collision version_conflict repository_conflict template_conflict cycle
    missing_offline bad_module bad_version bad_template missing_arguments missing_target)
  add_test(NAME configure_${case}
    COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}/fixture"
      -B "${CMAKE_CURRENT_BINARY_DIR}/cases/${case}"
      "-DTEST_CASE=${case}")
  if(case STREQUAL "genex_config_exclusive")
    add_test(NAME configure_genex_config_union
      COMMAND "${CMAKE_COMMAND}" -G "Ninja Multi-Config"
        -S "${CMAKE_CURRENT_SOURCE_DIR}/fixture"
        -B "${CMAKE_CURRENT_BINARY_DIR}/cases/genex_config_union"
        "-DTEST_CASE=genex_config_union")
  endif()
  if(case MATCHES "^(genex_target_exists|genex_bad|genex_bad_condition|collision|version_conflict|repository_conflict|template_conflict|missing_offline|bad_module|bad_version|bad_template|missing_arguments|missing_target)$")
    set_tests_properties(configure_${case} PROPERTIES WILL_FAIL TRUE)
  endif()
endforeach()

if(UNIX)
  add_test(NAME archive_mirror_fetch
    COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}/archive"
      -B "${CMAKE_CURRENT_BINARY_DIR}/archive"
      -DBOOSTPACK_OFFLINE=OFF)
  add_test(NAME archive_mirror_offline_reconfigure
    COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}/archive"
      -B "${CMAKE_CURRENT_BINARY_DIR}/archive"
      -DBOOSTPACK_OFFLINE=ON)
  set_tests_properties(archive_mirror_offline_reconfigure
    PROPERTIES DEPENDS archive_mirror_fetch)
endif()

add_test(NAME reproducible_lockfile
  COMMAND "${CMAKE_COMMAND}"
    -DREPOSITORY_SOURCE=${CMAKE_SOURCE_DIR}
    -DTEST_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/lock
    -P "${CMAKE_CURRENT_SOURCE_DIR}/lock/run.cmake")
