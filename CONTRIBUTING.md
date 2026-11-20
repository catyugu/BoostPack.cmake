# Contributing

BoostPack's consumer API and supported scope are documented in the [README](README.md). Keep the implementation in a single `cmake/BoostPack.cmake` file, usable with CMake 3.22+ and a C++ compiler. Do not introduce a version-specific module registry, consumer-side build tools or changes to the host project's `FetchContent` state.

Changes to dependency discovery should be covered by synthetic module fixtures in `tests/fixture`, including negative cases where appropriate. Preserve native `Boost::` targets, module-level downloads and the existing lockfile contract.

Run the offline unit suite before opening a PR:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build --output-on-failure
```

For changes involving real Boost modules or toolchains, also run the [integration tests](README.md#examples-and-testing). The [resolver benchmark](README.md#examples-and-testing) is optional: run it locally or use **Actions → Benchmark → Run workflow**. Performance results should be compared on the same environment.

PRs target `main`. [CI](.github/workflows/ci.yml) covers the supported CMake/platform matrix, archive mirrors, lockfiles and offline behavior. Version tags trigger release validation and publication of the standalone file; benchmark results never gate releases.
