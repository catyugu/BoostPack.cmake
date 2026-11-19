foreach(case IN ITEMS
    minimal closure incremental reinclude repository template
    collision version_conflict repository_conflict template_conflict cycle
    missing_offline bad_module bad_version bad_template missing_arguments)
  add_test(NAME configure_${case}
    COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}/fixture"
      -B "${CMAKE_CURRENT_BINARY_DIR}/cases/${case}"
      "-DTEST_CASE=${case}")
  if(case MATCHES "^(collision|version_conflict|repository_conflict|template_conflict|cycle|missing_offline|bad_module|bad_version|bad_template|missing_arguments)$")
    set_tests_properties(configure_${case} PROPERTIES WILL_FAIL TRUE)
  endif()
endforeach()

if(UNIX)
  add_test(NAME archive_mirror_fetch
    COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}/archive"
      -B "${CMAKE_CURRENT_BINARY_DIR}/archive")
  add_test(NAME archive_mirror_offline_reconfigure
    COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}/archive"
      -B "${CMAKE_CURRENT_BINARY_DIR}/archive"
      -DBOOSTPACK_OFFLINE=ON)
  set_tests_properties(archive_mirror_offline_reconfigure
    PROPERTIES DEPENDS archive_mirror_fetch)
endif()