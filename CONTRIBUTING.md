# Contributing

BoostPack's consumer API and supported scope are documented in the [README](README.md). Keep the implementation in a single `cmake/BoostPack.cmake` file, usable with CMake 3.22+ and a C++ compiler. Do not introduce a version-specific module registry, consumer-side build tools or changes to the host project's `FetchContent` state.

Changes to dependency discovery should be covered by synthetic module fixtures in `tests/fixture`, including negative cases where appropriate. Preserve native `Boost::` targets, module-level downloads and the existing lockfile contract.

Run the offline unit suite before opening a PR:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build --output-on-failure
```

For changes involving real Boost modules or toolchains, also run the [integration tests](README.md#examples-and-testing). [Manual](.github/workflows/manual.yml) provides separately dispatched `compatibility` and `benchmark` suites; benchmark results should be compared on the same environment.

PRs target `main`. [CI](.github/workflows/ci.yml) has three platform jobs (Linux/CMake 3.22, Windows, macOS), each running `tests/`, the default integration tests and **all** `examples/` projects. [Release](.github/workflows/release.yml) creates the version tag and publishes `BoostPack.cmake` only after successful `main` CI, once per matching version.
