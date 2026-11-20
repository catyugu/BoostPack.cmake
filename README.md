# BoostPack.cmake

[![CI](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml/badge.svg)](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml)

BoostPack downloads selected Boost module archives and their transitive CMake target dependencies, exposing the upstream `Boost::<module>` targets. It is a single CMake file with no prebuilt module database or Boost superproject checkout.

Requires CMake **3.22+**, a C++ compiler, and network access for uncached modules. No Git, Python, Boost.Build, or package manager is required. Individual Boost modules may have additional toolchain requirements.

## Usage

Copy [`cmake/BoostPack.cmake`](cmake/BoostPack.cmake) into your project, or get the standalone file from the [latest release](https://github.com/catyugu/BoostPack.cmake/releases/latest).

```cmake
cmake_minimum_required(VERSION 3.22)
project(example LANGUAGES CXX)

include(cmake/BoostPack.cmake)
boostpack_add(VERSION 1.92.0 COMPONENTS unordered container pfr mp11)

add_executable(example main.cpp)
target_compile_features(example PRIVATE cxx_std_20)
target_link_libraries(example PRIVATE
  Boost::unordered Boost::container Boost::pfr Boost::mp11)
```

Configure normally with `cmake -S . -B build` and `cmake --build build`. The Boost version is chosen by the caller; supported modules require upstream archives with suitable CMake targets.

`boostpack_add()` accepts:

```cmake
boostpack_add(
  VERSION <Boost release>
  COMPONENTS <module> [<module> ...]
  [REPOSITORY <base URL>]
  [URL_TEMPLATE <archive URL template>]
)
```

The default source is the GitHub `boostorg` repositories. `REPOSITORY` selects a compatible mirror, while `URL_TEMPLATE` customizes its archive layout. Template placeholders: `@REPOSITORY@`, `@MODULE@`, `@VERSION@`, `@TAG@` (for example, `boost-1.92.0`). Use HTTPS for remote sources or `file://` for local mirrors.

You can call `boostpack_add()` multiple times in the same configure, using the same version and source endpoint. Existing external `Boost::` targets are not overridden.

## Cache and reproducibility

| CMake variable | Default | Meaning |
| --- | --- | --- |
| `BOOSTPACK_CACHE_DIR` | `<build>/_boostpack/` | Optional shared archive cache |
| `BOOSTPACK_OFFLINE` | `OFF` | Require cached archives; never download |
| `BOOSTPACK_LOCKFILE` | Unset | Optional JSON lockfile path |

A specified lockfile is created if absent or verified if present. It pins the Boost version, source endpoint, resolved modules, archive URLs and SHA256 hashes. Regenerate it by deleting the lockfile and configuring online again.

To configure a fresh build without network access, use the same lockfile and shared archive cache:

```sh
cmake -S . -B build -DBOOSTPACK_CACHE_DIR=/path/to/cache \
  -DBOOSTPACK_LOCKFILE=boostpack.lock.json

cmake -S . -B build-offline -DBOOSTPACK_CACHE_DIR=/path/to/cache \
  -DBOOSTPACK_LOCKFILE=boostpack.lock.json -DBOOSTPACK_OFFLINE=ON
```

By default, archives, extracted sources and module build files stay under `<build>/_boostpack/`. An explicit `BOOSTPACK_CACHE_DIR` moves only the archive cache.

## Dependency resolution

BoostPack configures each module's upstream CMake project and discovers dependencies from actual target-link properties, including common generator expressions. Uncached modules download concurrently (up to eight at a time); as each becomes available, newly discovered dependencies enter the download queue immediately.

Resolution covers CMake target links, not implicit header, source or custom-command dependencies. Modules without compatible upstream CMake support may not work. BoostPack does not change the host project's `FetchContent` settings.

## Examples and development

See [`examples/`](examples/) for header-only, compiled, mixed-version and offline-cache usage. [CI](.github/workflows/ci.yml) runs unit and integration tests on Linux, Windows and macOS; the [Examples workflow](.github/workflows/examples.yml) builds and tests all examples on manual dispatch.

Testing commands, benchmarks and release details are in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE). Downloaded Boost modules retain their upstream licenses (usually BSL-1.0).
