# Changelog

## 0.2.2 - 2026-11-20

- Add optional JSON lockfiles that pin each requested or transitive Boost module's archive URL and SHA256, including the upstream CMake support archive when needed.
- Implement explicit WRITE (regenerate at end of configuration) and READ (verify exact Boost version, endpoint, archive checksum, and complete dependency closure) modes.
- Require a lockfile in READ mode for strict offline builds. Reuse only cached archives and fail on missing, modified, or incorrectly sourced artifacts rather than performing a hidden network fetch.
- Restrict archive URLs to HTTPS or local file URLs; use TLS verification, atomic cached downloads and file locks; keep archive caches separated by version and source endpoint.
- Add end-to-end synthetic archive corruption/offline tests and a real Boost locked/offline CI job on CMake 3.22; preserve the single-file consumer interface.

## 0.2.1 - 2026-11-20

- Discover Boost dependencies from the actual configured CMake target graph rather than scanning text in only the root `CMakeLists.txt`. Support dependencies created through functions, variables, included files, subdirectories and active platform conditions; ignore optional `TARGET_NAME_IF_EXISTS` links.
- Load the upstream `boostorg/cmake` support files from the selected release on demand for modules requiring `boost_install` or related helpers; preserve the single-file consumer API.
- Add offline regression coverage for configured dependency discovery and upstream support, and extend real Boost integration to Asio, Filesystem, Regex, Stacktrace and Thread.
- Separate CI from release publication: only `v*` tag builds publish, after full test validation and tag/version/`main` ancestry checks.


## 0.2.0 - 2026-11-20 (corrected release)

- Replace the fixed Boost 1.92.0 / 53-module dependency registry with **runtime module discovery**: fetch the requested release/module sources and recursively resolve dependencies from upstream CMake target declarations.
- Accept arbitrary published Boost versions (subject to upstream CMake support) and configurable repository/mirror bases or archive URL templates.
- Eliminate maintainers' generated JSON, Python scripts, and version-specific tables. Consumer dependencies remain CMake 3.22+ and a C++ toolchain.
- Isolate source caches by Boost version and mirror; preserve offline mode, source overrides, incremental calls, and original Boost targets.
- Test synthetic dependency graphs, actual local archive mirrors, multiple real Boost releases, Clang/GCC/MSVC/AppleClang, static/shared, and a custom mirror URL.
- Add `examples/custom-version` to demonstrate selecting an older Boost release and alternate source location.

The initial v0.2.0 release was withdrawn and replaced because its fixed module registry did not meet the intended design requirements.

## 0.1.0 - 2026-11-20

- Introduce a single-file CMake 3.22+ Boost module manager.
- Add pinned Boost 1.92.0 metadata for 23 modules and their transitive dependencies.
- Reuse upstream Boost CMake targets and build definitions.
- Add incremental calls, source caching, offline mode, and explicit error handling.
- Add offline configuration tests, real Boost integration tests, cross-platform CI, and automated tagged releases.