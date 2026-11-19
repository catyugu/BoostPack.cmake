# Changelog

## 0.2.0 - 2026-11-20

- Expand Boost 1.92.0 module coverage from 23 to 53, including JSON, URL, MultiIndex, Bloom, and Outcome.
- Introduce upstream-derived, automatically generated metadata: release-pinned submodule revisions and CMake dependency declarations, embedded in the single-file consumer module.
- Add offline generator regression tests and CI comparison with the upstream release.
- Strengthen real Boost integration tests: CMake 3.22.6, GCC, Clang, AppleClang, MSVC, and static/shared libraries.
- Add a compiled JSON/URL consumer example, built and tested in CI.

## 0.1.0 - 2026-11-20

- Introduce a single-file CMake 3.22+ Boost module manager.
- Add pinned Boost 1.92.0 metadata for 23 modules and their transitive dependencies.
- Reuse upstream Boost CMake targets and build definitions.
- Add incremental calls, source caching, offline mode, and explicit error handling.
- Add offline configuration tests, real Boost integration tests, cross-platform CI, and automated tagged releases.
