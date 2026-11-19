# BoostPack.cmake

[![CI](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml/badge.svg)](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml)

**Boost modules through one CMake file.** BoostPack downloads only the requested Boost repositories and their transitive module dependencies, then adds the upstream CMake targets to your build. No Boost installation, Boost.Build, Boostdep, BCP, Python, or package manager is required by consumers.

## Quick start

Copy [`cmake/BoostPack.cmake`](cmake/BoostPack.cmake) into your project:

```cmake
cmake_minimum_required(VERSION 3.22)
project(example LANGUAGES CXX)

include(cmake/BoostPack.cmake)
boostpack_add(VERSION 1.92.0 COMPONENTS unordered container pfr mp11)

add_executable(example main.cpp)
target_link_libraries(example PRIVATE
  Boost::unordered Boost::container Boost::pfr Boost::mp11)
```

See also [`examples/minimal`](examples/minimal) for a complete consumer project.

CMake fetches the selected modules (including dependencies) at configure time, and uses their **original** `Boost::<module>` targets and CMake build definitions. Compiled modules are built only as needed by downstream targets. Every source archive is addressed by its upstream release tag's resolved Git commit SHA; no mutable branch references are used.

## Supported modules (v0.1.0)

Boost **1.92.0** is supported. The following 23 modules can be requested directly or loaded as transitive dependencies:

`assert`, `charconv`, `config`, `container`, `container_hash`, `core`, `describe`, `dynamic_bitset`, `endian`, `intrusive`, `io`, `move`, `mp11`, `pfr`, `predef`, `preprocessor`, `scope`, `static_string`, `throw_exception`, `type_traits`, `unordered`, `utility`, `uuid`.

All combinations of these modules are resolved from pinned, version-specific dependency metadata. Unknown modules and other Boost versions fail during configuration, before download.

## Configuration

| Option | Default | Purpose |
| --- | --- | --- |
| `BOOSTPACK_CACHE_DIR` | empty | Optional reusable FetchContent source cache; otherwise CMake's build-local cache is used |
| `BOOSTPACK_OFFLINE` | `OFF` | Do not contact the network; use previously populated sources only |

```sh
cmake -S . -B build -DBOOSTPACK_CACHE_DIR=/path/to/cache
cmake -S . -B build -DBOOSTPACK_OFFLINE=ON -DBOOSTPACK_CACHE_DIR=/path/to/cache
```

For local source overrides or vendored copies, use CMake's standard `FETCHCONTENT_SOURCE_DIR_BOOSTPACK_<UPPERCASE_MODULE>` variables (for example, `FETCHCONTENT_SOURCE_DIR_BOOSTPACK_PFR`). The module's directory must contain its upstream `CMakeLists.txt`.

Multiple `boostpack_add()` calls are permitted and add only newly needed modules. A single CMake build tree cannot mix Boost versions or combine BoostPack-managed targets with already-existing targets of the same names. BoostPack sets `BUILD_TESTING=OFF` *only while configuring downloaded Boost projects*, leaving the parent project's test settings unchanged.

This is **module-level** selection: each chosen module's complete source archive is downloaded. It is not per-header or per-file pruning. The downloaded libraries retain their upstream licenses; BoostPack's own CMake source is MIT-licensed.

## Development

Requires CMake 3.22+ and a C++ compiler. Local configuration tests use synthetic Boost modules and run without network access:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build --output-on-failure
```

Run an integration test against actual Boost 1.92.0 sources:

```sh
cmake -S tests/integration -B build/integration
cmake --build build/integration --config Release
ctest --test-dir build/integration -C Release --output-on-failure
```

GitHub Actions exercises the configuration tests on Linux, macOS and Windows, including CMake 3.22.6, and compiles a real Boost integration test on all three platforms. On a successful `main` CI run, a new version is published as a GitHub release with `BoostPack.cmake` attached; already published versions are not overwritten.

## Scope

The current release prioritizes a small CMake-only implementation, a fixed verified dependency graph, and upstream targets. Support for additional Boost versions/modules, per-file trimming, install/export rules, and source vendoring are future enhancements.

## License

BoostPack.cmake is distributed under the [MIT license](LICENSE). Fetched Boost modules are distributed under their own upstream licenses (normally Boost Software License 1.0).
