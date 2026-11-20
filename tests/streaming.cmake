cmake_minimum_required(VERSION 3.22)

if(NOT DEFINED TEST_BINARY_DIR)
  message(FATAL_ERROR "TEST_BINARY_DIR is required")
endif()

# Check observable resolver behavior rather than any temporary job filename:
# stream_root is cached, stream_peer is not; stream_root's transitive leaf
# should be dispatched while stream_peer is still downloading.
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -S "${CMAKE_CURRENT_LIST_DIR}/fixture"
    -B "${TEST_BINARY_DIR}"
    -DTEST_CASE=streaming
  RESULT_VARIABLE result
  OUTPUT_VARIABLE output
  ERROR_VARIABLE error
  TIMEOUT 60)
if(NOT result STREQUAL "0")
  message(FATAL_ERROR "Streaming configuration failed:\n${output}\n${error}")
endif()

string(FIND "${output}" "BoostPack: started download of stream_leaf" started_leaf)
string(FIND "${output}" "BoostPack: resolving stream_peer" resolved_peer)
if(started_leaf EQUAL -1 OR resolved_peer EQUAL -1
    OR started_leaf GREATER resolved_peer)
  message(FATAL_ERROR
    "A transitive download was not started before an unrelated package completed:\n${output}")
endif()
message(STATUS "Streaming resolution overlapped unrelated dependency work")
