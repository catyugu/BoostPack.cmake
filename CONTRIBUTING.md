# Contributing

BoostPack's consumer API and supported scope are documented in the [README](README.md). Keep the implementation in a single `cmake/BoostPack.cmake` file, usable with CMake 3.22+ and a C++ compiler. Do not introduce a version-specific module registry, consumer-side build tools or changes to the host project's `FetchContent` state.

Changes to dependency discovery should be covered by synthetic module fixtures in `tests/fixture`, including negative cases where appropriate. Preserve native `Boost::` targets, module-level downloads and the existing lockfile contract.

Run the offline unit suite before opening a PR:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build --output-on-failure
```

For changes involving real Boost modules or toolchains, also run the [integration tests](README.md#examples-and-testing). Use **Actions → CI → Run workflow** and choose `compatibility` for additional compiled/assembler-dependent modules or `benchmark` for the resolver benchmark. Both are manual; compare performance results on the same environment.

PRs target `main`. The [single workflow](.github/workflows/ci.yml) performs only two automatic smoke checks (Linux/CMake 3.22 and Windows), covering offline fixtures and a real Boost build. Detailed compatibility and performance suites stay optional. Version tags publish the standalone file only after both smoke checks pass.
