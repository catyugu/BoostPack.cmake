# BoostPack.cmake

[![CI](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml/badge.svg)](https://github.com/catyugu/BoostPack.cmake/actions/workflows/ci.yml)

BoostPack is a standalone CMake file that downloads selected Boost module repositories and their transitive dependencies, then exposes the upstream `Boost::<module>` targets. Dependencies are discovered from the modules' CMake targets at configure time; there is no version-specific module database or Boost superproject checkout.

Consumers need CMake **3.22+**, a C++ compiler, and network access on the first download (or a populated archive cache). No Python, Boost.Build, package manager, or other dependency tool is required. Individual Boost modules may impose additional toolchain requirements.

## Usage

Copy [`cmake/BoostPack.cmake`](cmake/BoostPack.cmake) into your project, or use the file attached to a [release](https://github.com/catyugu/BoostPack.cmake/releases).

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

Configure and build as usual with `cmake -S . -B build` and `cmake --build build`. The version above is an example, not a built-in whitelist. A requested release/module must have an upstream archive and CMake support for its native `Boost::` target.

The public entry point is:

```cmake
boostpack_add(
  VERSION <Boost release>
  COMPONENTS <module> [<module> ...]
  [REPOSITORY <base URL>]
  [URL_TEMPLATE <archive URL template>]
)
```

You may call `boostpack_add()` repeatedly to add modules incrementally. Within one configure, all calls must use the same Boost version and source endpoint. BoostPack rejects collisions with `Boost::` targets created outside BoostPack instead of mixing different Boost installations.

### Repository and mirrors

By default, module `json` at Boost `1.92.0` is downloaded from:

```text
https://github.com/boostorg/json/archive/refs/tags/boost-1.92.0.tar.gz
```

Set `REPOSITORY` for a mirror using the same layout. For a different archive layout, pass `URL_TEMPLATE`:

```cmake
boostpack_add(
  VERSION 1.92.0
  COMPONENTS json url
  URL_TEMPLATE "https://codeload.github.com/boostorg/@MODULE@/tar.gz/refs/tags/@TAG@"
)
```

Available placeholders are `@REPOSITORY@` (the base URL), `@MODULE@`, `@VERSION@` (`1.92.0`), and `@TAG@` (`boost-1.92.0`). Remote archives must use HTTPS; local mirrors can use `file://` URLs.

### Cache, offline mode and lockfiles

Only three BoostPack-wide cache variables are exposed:

| Variable | Default | Purpose |
| --- | --- | --- |
| `BOOSTPACK_CACHE_DIR` | Build-local cache | Reuse downloaded archives across build directories |
| `BOOSTPACK_OFFLINE` | `OFF` | Prohibit network downloads; require cached archives |
| `BOOSTPACK_LOCKFILE` | Unset | Path to an optional JSON dependency lockfile |

When a lockfile path is provided, BoostPack **creates** the file if it is absent, or **verifies** it if present. The file records the Boost version, repository, URL template and complete resolved module set (including upstream `boostorg/cmake` support when needed). Each archive is pinned by its URL and SHA256. To update a lockfile intentionally, delete it and configure again.

For reproducible source downloads across separate build directories, use the **same shared cache** in both configurations:

```sh
# First configure: populate the cache and create boostpack.lock.json.
cmake -S . -B build -DBOOSTPACK_CACHE_DIR=/path/to/boostpack-cache \
  -DBOOSTPACK_LOCKFILE=boostpack.lock.json

# Fresh offline build: read and verify the same lockfile and cached archives.
cmake -S . -B build-offline -DBOOSTPACK_CACHE_DIR=/path/to/boostpack-cache \
  -DBOOSTPACK_LOCKFILE=boostpack.lock.json -DBOOSTPACK_OFFLINE=ON
```

Offline mode also works without a lockfile if the archives are already cached; a missing *requested* lockfile cannot be created offline. Cache entries are separated by Boost version and source endpoint. Archive verification does not detect changes made after extraction in a build tree, and it does not guarantee byte-identical compiled binaries.

BoostPack manages downloads and extraction independently. It neither reads nor modifies the host project's `FetchContent` declarations, cache location or offline settings.

On a cold configure, BoostPack maintains a streaming queue with up to eight concurrent downloads. Whenever an archive becomes available, its upstream CMake targets are configured immediately in the calling project, and newly discovered dependencies are queued without waiting for other downloads to finish. In-flight and already-loaded modules are deduplicated, and a single uncached module is downloaded synchronously to avoid worker startup overhead. No dependency list is hard-coded. The default GitHub download skips its archive redirect.

Generated files stay under `<build>/_boostpack/`: `archives/` (default archive cache), `sources/` (extracted sources), and `binary/` (upstream CMake build trees). While downloads are running, temporary status files live under `download-jobs/`; they are removed after success. The streaming worker executes this same standalone CMake file, rather than generating a file or script for each module. Archive and lockfile `.lock` files are genuine inter-process synchronization locks and must not be removed while another process could be using them. Partial downloads/extractions are written under temporary paths and atomically renamed; an additional extraction-ready marker is unnecessary. Worker startup uses the operating system's built-in shell (`/bin/sh` on Unix, Windows PowerShell on Windows), with no extra consumer tools. Setting `BOOSTPACK_CACHE_DIR` explicitly still places the archive cache at the requested path; it does not move generated sources or binary files.

## Dependency discovery and scope

BoostPack configures each requested module's upstream `CMakeLists.txt` and inspects its target link properties, including targets created by included files and subdirectories. Missing `Boost::` dependencies are fetched recursively; version-matched `boostorg/cmake` support is loaded on demand.

Common generator expressions are resolved before dependency discovery, so inactive conditional branches, install-only links and optional missing targets do not trigger downloads. Multi-config generators include dependencies required by any configured build configuration. Unsupported link expressions produce a diagnostic rather than a speculative dependency list.

The resolver covers dependencies expressed through CMake target link properties. Implicit header/source/custom-step dependencies are outside that contract. Boost modules without suitable upstream CMake support are not guaranteed to work. Downloads are **module archives**, not trimmed header or file subsets.

## Examples and testing

- [`examples/minimal`](examples/minimal): single header-only PFR module.
- [`examples/json`](examples/json): JSON and URL libraries with transitive dependencies.
- [`examples/custom-version`](examples/custom-version): Boost 1.89 with PFR, MP11 and Describe, plus optional mirror and archive-template selection.
- [`examples/cli-report`](examples/cli-report): compiled Program_options, Filesystem and Serialization plus Regex; exercises shared libraries and a deterministic file-report round trip.
- [`examples/host-project`](examples/host-project): a consuming project with native `FetchContent`, incremental `boostpack_add()` calls, a build-local lockfile, and a fresh offline configure that reuses its archive cache.

The examples are intentionally varied: Boost 1.89.0 and 1.92.0, C++17 and C++20, header-only and compiled targets, shared linking, optional source mirrors, and coexistence with a host project's native `FetchContent`. CI reuses the existing three OS jobs to build and run every example; no new matrix entries or synthetic fixtures are required.

The host-project example exercises cache and lockfile reuse across independent build trees. Its first configure downloads the necessary module archives and writes a lockfile; its CTest then performs a fresh configure with `BOOSTPACK_OFFLINE=ON` and the same cache and lockfile:

```sh
cmake -S examples/host-project -B build/host-project
cmake --build build/host-project --config Release
ctest --test-dir build/host-project -C Release --output-on-failure
```

The local `FetchContent` dependency requires no network access and retains the host's own offline and cache settings. A passing example verifies the specific modules and platforms exercised; it does not guarantee compatibility with every upstream Boost module or release.

Run the synthetic, offline-capable unit tests:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build --output-on-failure
```

For real Boost integration tests, including compiled modules:

```sh
cmake -S tests/integration -B build/integration \
  -DBOOST_VERSION=1.92.0 -DBOOSTPACK_INTEGRATION_EXTENDED=ON
cmake --build build/integration --config Release
ctest --test-dir build/integration -C Release --output-on-failure
```

With `BOOSTPACK_INTEGRATION_EXTENDED=ON`, the test project additionally builds `asio`, `filesystem`, `regex`, `thread`, `program_options`, `serialization`, `iostreams`, `context`, `coroutine` and `fiber`. The assembler-dependent modules require a compatible platform toolchain.

GitHub Actions is split by responsibility:

- [CI](.github/workflows/ci.yml) runs on PRs and `main` pushes, with **one job on each of Linux, Windows and macOS**. Each job runs the root `tests/` suite, the default real-Boost `tests/integration/` suite, and **every project under `examples/`** (configure, build and execute its tests). Linux exercises CMake 3.22. Superseded PR runs are canceled.
- [Manual](.github/workflows/manual.yml) runs only when explicitly dispatched from [Actions → Manual](https://github.com/catyugu/BoostPack.cmake/actions/workflows/manual.yml). Choose `compatibility` for the extended compiled/assembler-dependent Boost suite (with an optional Boost version), or `benchmark` for the offline resolver benchmark. Neither is a regular CI job.
- [Release](.github/workflows/release.yml) runs after a successful `main` push CI. If the CMake and standalone-file versions agree and that version is not yet released, it creates an annotated `v<version>` tag on the tested `main` commit and publishes the standalone `BoostPack.cmake` asset. Existing releases are left unchanged.

The benchmark can also be run locally:

```sh
cmake -DBENCH_ROOT=build/resolver-benchmark -P tests/benchmark/run.cmake
```

It measures cold-cache, warm-cache and repeat configuration for 24 local synthetic modules and writes `results.csv`. GitHub Actions uploads the CSV as an artifact. See [CONTRIBUTING.md](CONTRIBUTING.md) for development and release guidance.

## License

BoostPack is [MIT licensed](LICENSE). Boost modules retain their respective upstream licenses (usually Boost Software License 1.0).
