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

The source endpoint can be selected using the `REPOSITORY` and `URL_TEMPLATE` arguments of `boostpack_add()`. Both default to the official Boost GitHub repositories. A CMake configure may only use one Boost release and source endpoint; conflicting calls are rejected.

### Cache, offline builds and reproducibility

BoostPack exposes just three optional cache variables. Downloading and extracting Boost sources is entirely owned by BoostPack: it does **not** change or consult the host project's `FetchContent` settings or declarations.

| BoostPack setting | Default | Behavior |
| --- | --- | --- |
| `BOOSTPACK_CACHE_DIR` | Build-local | Optional reusable archive cache (separated by Boost version and source endpoint) |
| `BOOSTPACK_OFFLINE` | `OFF` | Never access the network; use cached archives only |
| `BOOSTPACK_LOCKFILE` | Empty | Optional JSON lockfile (relative to the top-level source directory) |

Lockfile behavior is automatic. When `BOOSTPACK_LOCKFILE` is set and the file does not exist, BoostPack resolves the complete dependency closure and **creates** the file. When it exists, BoostPack **verifies** every source URL and archive SHA256 as well as the Boost version and complete closure; any mismatch fails configuration. To intentionally regenerate a lockfile, delete it and configure again. No separate READ/WRITE mode is needed.

```sh
# First configure: download Boost sources and generate a lockfile.
cmake -S . -B build -DBOOSTPACK_LOCKFILE=boostpack.lock.json

# Subsequent configure: verify the existing lockfile.
cmake -S . -B build

# Strictly offline, using the existing lockfile and a populated shared cache.
cmake -S . -B offline -DBOOSTPACK_LOCKFILE=boostpack.lock.json \
  -DBOOSTPACK_CACHE_DIR=/path/to/cache -DBOOSTPACK_OFFLINE=ON
```

The first and third commands must use the same `BOOSTPACK_CACHE_DIR` if they use different build directories. Without a lockfile, offline mode still requires previously cached archives, but no source hashes are pinned across machines. When `BOOSTPACK_LOCKFILE` is set but missing, offline mode fails rather than generating an incomplete lockfile.

The lockfile is a JSON document (schema 1) that pins the Boost version, source endpoint, and every resolved archive's URL and SHA256, including version-matched upstream `boostorg/cmake` support when necessary. `BOOSTPACK_LOCKFILE` may be committed to version control for reproducible dependency sources. Lockfile verification covers downloaded archive bytes, not user modifications to files **after extraction**; use a clean build directory when checking source integrity.

Only HTTPS remote URLs and local `file://` archive mirrors are accepted. Downloads use TLS verification, per-archive file locks, and atomic cache updates. Extracted sources and binary directories are isolated in the consumer build tree; shared cache contents are limited to archives.

Multiple `boostpack_add()` calls incrementally add new dependencies and never duplicate targets. BoostPack temporarily sets `BUILD_TESTING=OFF` only while adding upstream Boost projects, leaving the parent's testing configuration untouched.

## How dependency discovery works

1. Each requested module is fetched from its own `boostorg/<module>` repository at the selected Boost release tag (no superproject download).
2. BoostPack configures each fetched module with its upstream CMake declarations (and loads version-matched `boostorg/cmake` support on demand where required).
3. It reads the configured targets' real CMake link properties, including targets created in subdirectories, and fetches missing `Boost::` dependencies until the closure is complete.
4. The requested `Boost::` targets are available immediately for `target_link_libraries()`.


The supported scope is Boost modules that expose their native CMake targets and link dependencies through CMake target properties. Dependencies that are purely implicit in headers, source files or custom build steps still require explicit support. Configured optional links using `TARGET_NAME_IF_EXISTS` do not trigger downloads. BoostPack does not guarantee support for arbitrary source repositories or every historical release/toolchain combination. No per-header or per-file trimming is performed: the complete source archive of each needed module is downloaded.

Without a lockfile, Boost sources are selected by upstream release tags, which may be mutable. With a lockfile, archive bytes, URLs and the complete module closure are verified. Delete the lockfile to regenerate it explicitly.

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

GitHub Actions tests CMake 3.22.6, GCC, Clang, AppleClang, MSVC, static/shared builds, more than one Boost release, extended modules, custom mirror URLs, and real Boost locked/offline builds. Ordinary pushes and PRs run CI; releases are published only from version tags matching the source version and reachable from `main`.

## License

BoostPack itself is [MIT licensed](LICENSE). Each fetched Boost module remains subject to its own upstream license (usually Boost Software License 1.0).