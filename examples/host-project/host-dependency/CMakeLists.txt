# A local dependency owned by the host project's native FetchContent.
add_library(host_dependency INTERFACE)
target_compile_definitions(host_dependency
  INTERFACE BOOSTPACK_HOST_DEPENDENCY=1)
