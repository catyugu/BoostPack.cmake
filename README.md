# BoostPack.cmake

[![CI](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml/badge.svg)](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml)

**Choose Boost modules through one CMake file.** BoostPack fetches only requested Boost repositories and their transitive dependencies, then uses the original upstream CMake targets. Consumers need **CMake 3.22+ and a C++ compiler**, but no installed Boost, Boost.Build, Boostdep, BCP, Python, or package manager.

## Quick start

Copy [BoostPack.cmake](cmake/BoostPack.cmake) into your project, or download the single-file [v0.2.0 release](https://github.com/catyugu/BoostPack.cmake/releases/tag/v0.2.0).

~~~cmake
cmake_minimum_required(VERSION 3.22)
project(example LANGUAGES CXX)

include(cmake/BoostPack.cmake)
boostpack_add(VERSION 1.92.0 COMPONENTS unordered container pfr mp11)

add_executable(example main.cpp)
target_link_libraries(example PRIVATE
  Boost::unordered Boost::container Boost::pfr Boost::mp11)
~~~

Configure and build normally: `cmake -S . -B build`, then `cmake --build build`. See the complete [minimal](examples/minimal) and [JSON + URL](examples/json) consumer examples.

## Supported modules (v0.2.0)

The **52 supported Boost 1.92.0 modules**, including commonly used transitive dependencies, are:

`align`, `any`, `array`, `assert`, `bind`, `bloom`, `callable_traits`, `charconv`, `circular_buffer`, `compat`, `concept_check`, `config`, `container`, `container_hash`, `core`, `crc`, `describe`, `dynamic_bitset`, `endian`, `exception`, `function`, `integer`, `intrusive`, `io`, `json`, `lambda2`, `lexical_cast`, `logic`, `move`, `mp11`, `multi_index`, `optional`, `outcome`, `pfr`, `pool`, `predef`, `preprocessor`, `rational`, `scope`, `smart_ptr`, `static_string`, `system`, `throw_exception`, `tuple`, `type_index`, `type_traits`, `unordered`, `url`, `utility`, `uuid`, `variant2`, `winapi`.

Only selected modules and their full dependency closure are downloaded. Libraries with compiled sources (for example, `json`, `url`, `charconv`, or `container` in its default mode) use their original CMake build definitions. Module revisions are pinned to the exact commits in the Boost 1.92.0 release superproject, **not floating branches**. Other Boost versions or unlisted modules fail before downloading.

## Options and local sources

| CMake variable | Default | Meaning |
| --- | --- | --- |
| `BOOSTPACK_CACHE_DIR` | empty | Reusable FetchContent source cache; otherwise build-local |
| `BOOSTPACK_OFFLINE` | `OFF` | Use already populated sources only; no network |

~~~sh
cmake -S . -B build -DBOOSTPACK_CACHE_DIR=/path/to/cache
cmake -S . -B build -DBOOSTPACK_OFFLINE=ON -DBOOSTPACK_CACHE_DIR=/path/to/cache
~~~

For vendored individual modules, use `FETCHCONTENT_SOURCE_DIR_BOOSTPACK_<UPPERCASE_MODULE>` (for example, `FETCHCONTENT_SOURCE_DIR_BOOSTPACK_JSON`). The directory must contain the upstream `CMakeLists.txt`.

Repeated `boostpack_add()` calls add only newly required dependencies. Boost version mixing or BoostPack-managed targets colliding with existing targets are rejected. Upstream Boost tests are disabled during module configuration, preserving the parent project's test settings.

This is **module-level** selection; it does not prune individual source files or headers. BoostPack's own CMake code is MIT licensed; downloaded Boost modules retain their original licenses (typically BSL-1.0).

## Maintainer workflow: regenerate pinned metadata

**Consumers never need Python.** For repository maintenance, a standard-library-only Python tool derives dependencies from the selected release's upstream module `CMakeLists.txt` and revisions from the tagged Boost superproject submodule tree.

The manually maintained supported-module selection is [tools/modules.txt](tools/modules.txt); its pinned manifest is [tools/boost-1.92.0.json](tools/boost-1.92.0.json).

~~~sh
python tools/generate_metadata.py --refresh          # update JSON and embedded CMake
python tools/generate_metadata.py --check            # offline consistency verification
python tools/generate_metadata.py --verify-upstream  # validate against tagged Boost sources
python tools/test_metadata.py                       # generator unit tests
~~~

`--refresh` and `--verify-upstream` require network access; `--check` and generator unit tests are offline. To add modules, edit `tools/modules.txt`, run `--refresh`, and commit the manifest and CMake changes. CI independently checks generated data against the upstream Boost release.

## Testing

Synthetic-module tests cover the complete supported dependency graph, incremental loading, offline failures, duplicate includes, target collisions, unsupported modules, and invalid versions/arguments:

~~~sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build -C Debug --output-on-failure
~~~

Real Boost integration includes both header-only and compiled libraries (including JSON, URL, and MultiIndex):

~~~sh
cmake -S tests/integration -B build/integration
cmake --build build/integration --config Release
ctest --test-dir build/integration -C Release --output-on-failure
~~~

CI tests Linux (GCC, Clang, static/shared modes, and CMake 3.22.6), macOS (AppleClang), Windows (MSVC), and builds and runs the [JSON/URL example](examples/json) with CMake 3.22.6. On successful `main` CI, a versioned GitHub Release attaches the standalone `BoostPack.cmake`.

## Scope

Further Boost versions/modules, source vendoring, per-file trimming, install/export rules, and independent archive SHA256 verification are future work.

## License

BoostPack uses the [MIT License](LICENSE). Boost modules retain their own upstream licenses, normally [Boost Software License 1.0](https://www.boost.org/LICENSE_1_0.txt).
