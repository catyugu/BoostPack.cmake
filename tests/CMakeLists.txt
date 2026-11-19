foreach(case IN ITEMS minimal full expanded incremental reinclude collision unsupported version_conflict missing_offline invalid_arguments)
  add_test(NAME configure_${case}
    COMMAND ${CMAKE_COMMAND}
      -S "${CMAKE_CURRENT_SOURCE_DIR}/fixture"
      -B "${CMAKE_CURRENT_BINARY_DIR}/cases/${case}"
      "-DTEST_CASE=${case}"
  )
  if(case MATCHES "^(collision|unsupported|version_conflict|missing_offline|invalid_arguments)$")
    set_tests_properties(configure_${case} PROPERTIES WILL_FAIL TRUE)
  endif()
endforeach()
