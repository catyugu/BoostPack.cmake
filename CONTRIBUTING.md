# Contributing

Keep the consumer contract: a single `BoostPack.cmake` file, CMake 3.22+, no extra consumer tools, module-level downloads, optional mirrors, and upstream Boost targets.

The resolver must work from module source files, without a baked-in version or module list. A lockfile must cover the exact configured archive closure and pin each archive's URL and SHA256. Keep the BoostPack API small: `BOOSTPACK_CACHE_DIR`, `BOOSTPACK_OFFLINE` and `BOOSTPACK_LOCKFILE` are the only global configuration options. Do not modify, consult, or otherwise interfere with the host project's FetchContent configuration or declarations; BoostPack manages downloads and extraction independently. Changes to dependency discovery should come with synthetic CMake regression tests covering version independence, configured target graphs (including dynamic references, conditions and nested directories), dependency closure, and error paths.

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

To measure source resolution, run `cmake -DBENCH_ROOT=build/resolver-benchmark -P tests/benchmark/run.cmake`; compare cold/warm/reconfigure times on the same machine. The benchmark uses only synthetic local Boost module archives and outputs CSV results.

The CI matrix covers multiple Boost releases, CMake 3.22, Windows, Linux, macOS, CMake archive mirrors, locked and strictly offline real Boost builds, and static/shared compiled libraries. Releases are published on matching `v*` tags only after all CI jobs succeed; the tag commit must be reachable from `main`.