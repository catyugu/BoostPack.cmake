# Contributing

BoostPack's consumer API and supported scope are in the [README](README.md). Keep the implementation in a single `cmake/BoostPack.cmake` file, compatible with CMake 3.22+. Do not introduce a hard-coded Boost module database, consumer-side build tools, or modifications to the host project's `FetchContent` state.

Cover dependency-resolution changes with the shared synthetic fixture in `tests/fixture/`. Add negative tests where appropriate. Preserve the upstream `Boost::` targets, module-level downloads, SHA256 verification, offline operation and lockfile contract.

Run the offline unit suite:

```sh
cmake -S . -B build/tests -DBUILD_TESTING=ON
ctest --test-dir build/tests --output-on-failure
```

Run the real Boost integration suite when changing resolution, toolchain support or compiled modules:

```sh
cmake -S tests/integration -B build/integration -DBOOST_VERSION=1.92.0
cmake --build build/integration --config Release
ctest --test-dir build/integration -C Release --output-on-failure
```

Set `BOOSTPACK_INTEGRATION_EXTENDED=ON` for additional compiled and assembler-dependent modules. The standalone resolver benchmark runs locally:

```sh
cmake -DBENCH_ROOT=build/benchmark -P tests/benchmark/run.cmake
```

PRs target `main`. [CI](.github/workflows/ci.yml) runs unit and default integration tests on Linux (CMake 3.22), Windows and macOS. The [Examples workflow](.github/workflows/examples.yml) is manually triggered and builds/tests every example on all three platforms. Both use the shared [build-parallelism action](.github/actions/build-parallelism/action.yml), setting compile concurrency to `ceil(1.5 × available logical cores)`.

After successful `main` CI, [Release](.github/workflows/release.yml) tags and publishes the standalone file if the CMake and file-header versions match and that version is not already released.
