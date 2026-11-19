# Contributing

Changes should preserve the consumer contract: a single CMake file, CMake 3.22+, no required dependency-management tools, minimal module downloads, and upstream `Boost::` targets.

Before opening a pull request, run:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build --output-on-failure
```

For changes to dependency metadata or module initialization, also run the real Boost integration test described in the README. New module metadata must be derived from the target Boost release's upstream `CMakeLists.txt`, and Git revisions must be pinned to that release tag's resolved commit. Add a configuration regression test for changes to parsing, caching, collision detection, or repeat-call behavior.

Releases use semantic version tags. The `main` CI workflow publishes a new GitHub release only after its configuration and integration jobs pass; it uses the version recorded in both `CMakeLists.txt` and `cmake/BoostPack.cmake`.
