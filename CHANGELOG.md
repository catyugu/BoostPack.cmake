# Changelog

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