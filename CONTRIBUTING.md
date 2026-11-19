# Contributing

Keep the consumer contract: a single `BoostPack.cmake` file, CMake 3.22+, no extra consumer tools, module-level downloads, optional mirrors, and upstream Boost targets.

The resolver must work from module source files, without a baked-in version or module list. Changes to dependency discovery should come with synthetic CMake regression tests covering version independence, dependency closure, dynamic references, and error paths.

Run offline tests locally:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build -C Debug --output-on-failure
```

For substantive integration changes, also test real Boost sources:

```sh
cmake -S tests/integration -B build/integration -DBOOST_VERSION=1.92.0
cmake --build build/integration --config Release
ctest --test-dir build/integration -C Release --output-on-failure
```

The CI matrix covers multiple Boost releases, CMake 3.22, Windows, Linux, macOS, CMake archive mirrors, and static/shared compiled libraries. Releases are published only after the main branch CI succeeds.