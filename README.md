# BoostPack.cmake

[![CI](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml/badge.svg)](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml)

**Choose any Boost release and modules from one CMake file.** BoostPack retrieves just the chosen upstream Boost repositories and their transitive dependencies **on demand**, reads each downloaded module's upstream CMake target declarations, and registers the original `Boost::<module>` targets. No precomputed module registry, supported-version whitelist, Boost installation, Boost.Build, Boostdep, BCP, Python, or package manager is required by consumers.

Requirements: CMake **3.22+**, a C++ compiler, and network access on first use (or a populated source cache). Upstream modules may have additional toolchain requirements.

## Quick start

Copy [`cmake/BoostPack.cmake`](cmake/BoostPack.cmake) into your project, or get the standalone file from the release.

```cmake
cmake_minimum_required(VERSION 3.22)
project(example LANGUAGES CXX)

include(cmake/BoostPack.cmake)
boostpack_add(
    VERSION 1.92.0
    COMPONENTS unordered container pfr mp11
)

add_executable(example main.cpp)
target_link_libraries(example PRIVATE
    Boost::unordered Boost::container Boost::pfr Boost::mp11)
```

Run `cmake -S . -B build` and `cmake --build build`. Version `1.92.0` above is only an example; you can select **any published Boost release version** for which the requested module repositories include the release tag and an upstream `CMakeLists.txt`. Unsupported versions/modules produce fetch or CMake errors rather than using stale metadata.

### Specify a mirror or private repository

By default, BoostPack downloads archives from `https://github.com/boostorg/<module>/archive/refs/tags/boost-<version>.tar.gz`.

If the alternative host follows the same archive path convention, override the repository base URL:

```cmake
boostpack_add(
    VERSION 1.89.0
    COMPONENTS json url
    REPOSITORY https://your-mirror.example/boostorg
)
```

For hosts with different archive layouts, supply an URL template. The placeholders are `@REPOSITORY@`, `@MODULE@`, `@VERSION@`, and `@TAG@` (`boost-<version>`):

```cmake
boostpack_add(
    VERSION 1.92.0
    COMPONENTS pfr mp11
    URL_TEMPLATE "https://codeload.github.com/boostorg/@MODULE@/tar.gz/refs/tags/@TAG@"
)
```

`REPOSITORY` and `URL_TEMPLATE` are also configurable as project-wide cache options, `BOOSTPACK_REPOSITORY` and `BOOSTPACK_URL_TEMPLATE`. A given CMake configure may only use a single Boost release and source endpoint to prevent mixed-source target graphs.

### Cache, offline builds, local sources

| CMake setting | Default | Behavior |
| --- | --- | --- |
| `BOOSTPACK_REPOSITORY` | `https://github.com/boostorg` | Default repository/mirror base |
| `BOOSTPACK_URL_TEMPLATE` | empty | Override archive URL layout; uses placeholders listed above |
| `BOOSTPACK_CACHE_DIR` | empty | Reusable downloaded source cache (otherwise build-local) |
| `BOOSTPACK_OFFLINE` | `OFF` | Do not fetch anything; require existing cached sources |

```sh
cmake -S . -B build -DBOOSTPACK_CACHE_DIR=/path/to/cache
cmake -S . -B build -DBOOSTPACK_CACHE_DIR=/path/to/cache -DBOOSTPACK_OFFLINE=ON
```

The cache is isolated by Boost version and repository/template identity. The `FetchContent` source override `FETCHCONTENT_SOURCE_DIR_BOOSTPACK_<UPPERCASE_MODULE>` (for example `FETCHCONTENT_SOURCE_DIR_BOOSTPACK_PFR`) also works for local or vendored upstream modules.

Multiple `boostpack_add()` calls incrementally add new dependencies and never duplicate targets. BoostPack temporarily sets `BUILD_TESTING=OFF` only while adding upstream Boost projects, leaving the parent's testing configuration untouched.

## How dependency discovery works

1. Each requested module is fetched from its own `boostorg/<module>` repository at the selected Boost release tag (no superproject download).
2. BoostPack configures each fetched module with its upstream CMake declarations (and loads version-matched `boostorg/cmake` support on demand where required).
3. It reads the configured targets' real CMake link properties, including targets created in subdirectories, and fetches missing `Boost::` dependencies until the closure is complete.
4. The requested `Boost::` targets are available immediately for `target_link_libraries()`.


The supported scope is Boost modules that expose their native CMake targets and link dependencies through CMake target properties. Dependencies that are purely implicit in headers, source files or custom build steps still require explicit support. Configured optional links using `TARGET_NAME_IF_EXISTS` do not trigger downloads. BoostPack does not guarantee support for arbitrary source repositories or every historical release/toolchain combination. No per-header or per-file trimming is performed: the complete source archive of each needed module is downloaded.

Downloaded archives are selected by **release tag**, not commit SHA or independently verified hash. Treat mirror trust and release reproducibility accordingly; strict lockfiles are future work.

## Examples

- [`examples/minimal`](examples/minimal) — a basic PFR single-module project.
- [`examples/json`](examples/json) — compiled JSON + URL libraries and their transitive dependencies.
- [`examples/custom-version`](examples/custom-version) — configurable Boost release and mirror using lightweight PFR + Mp11; pass `-DBOOST_VERSION=1.89.0 -DBOOST_MIRROR=...`.

## Tests and CI

The offline unit tests generate fake Boost repositories with varying dependency graphs and validate closure discovery across CMake functions, variables, conditions and subdirectories, CMake support loading, multiple releases, URL templates and custom mirrors, repeated calls, version/source conflicts, cycles, offline errors, and invalid input. A separate local archive fixture tests real CMake archive downloading without GitHub.

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build -C Debug --output-on-failure
```

The real integration project verifies compiled and header-only Boost libraries across multiple versions. Enable the extended suite for Asio, Filesystem, Regex, Stacktrace and Thread:

```sh
cmake -S tests/integration -B build/integration -DBOOST_VERSION=1.89.0 -DBOOSTPACK_INTEGRATION_EXTENDED=ON
cmake --build build/integration --config Release
ctest --test-dir build/integration -C Release --output-on-failure
```

GitHub Actions tests CMake 3.22.6, GCC, Clang, AppleClang, MSVC, static/shared builds, more than one Boost release, extended modules, and a custom GitHub codeload template. Ordinary pushes and PRs run CI; releases are published only from version tags matching the source version and reachable from `main`.

## License

BoostPack itself is [MIT licensed](LICENSE). Each fetched Boost module remains subject to its own upstream license (usually Boost Software License 1.0).