# Changelog

## 0.3.3 - 2026-11-21

- Register the streaming dependency test through the common CMake fixture and check download ordering without relying on transient status files persisting after completion.
- Share CMake build parallelism setup between CI and the manually dispatched Examples workflow; retain the ceiling of 1.5 times available logical cores.
- Remove the unused Manual workflow. Keep extended integration and resolver benchmarking available as local CMake commands.
- Reduce README to the consumer API, cache and lockfile behavior, dependency scope, and links to development instructions. No public API changes.

## 0.3.2 - 2026-11-20

- Stream independent Boost archive downloads: configure each completed module and enqueue newly discovered target dependencies without a layer-wide download barrier.
- Remove per-module downloader scripts and redundant extraction markers and locks, while preserving real inter-process archive-cache and lockfile locks.
- Run routine CI with unit and real Boost integration tests on Linux, Windows and macOS; move all example builds into a manually dispatched Examples workflow.
- Set CI build parallelism from the available logical core count rather than a fixed two workers.

## 0.3.1 - 2026-11-20

- Improve cold configure with concurrent archive retrieval and fewer GitHub redirects.
- Consolidate build-local archives, extracted sources and upstream build trees under `_boostpack/`.
- Speed up test fixtures on Windows through Ninja, parallel CTest execution and avoiding unnecessary compiler detection.

## 0.3.0 - 2026-11-20

- Add diverse executable examples across Boost 1.89.0 and 1.92.0, header-only and compiled modules, and shared-library linking on Linux, Windows and macOS.
- Simplify the generator-expression resolver and remove redundant dependency/lockfile state without changing the public `boostpack_add()` API.
- Add a real host-project example that combines native `FetchContent` with repeated BoostPack calls, writes a lockfile, and verifies a fresh offline configure against the same archive cache.
- Keep CMake 3.22+, the standalone `BoostPack.cmake` distribution, the three existing user controls and the existing three-platform CI workflow. Optional benchmarks and extended compatibility checks remain manual.

## 0.2.6 - 2026-11-20

- Evaluate target link generator expressions separately for each configured build configuration, avoiding spurious dependencies from mutually exclusive conditions while preserving the multi-config union.
- Reject ambiguous `TARGET_EXISTS:Boost::...` conditions rather than making a configure-time guess about modules fetched later.
- Verify extraction completion markers against archive hashes; guard lockfile creation against concurrent writers and refuse an overwrite when another configure has created the lockfile.
- Add offline regression fixtures for conditional dependency discovery; retain the existing public API and CI/Manual/Release workflow split.

## 0.2.5 - 2026-11-20

- Prune inactive or install-only generator-expression branches before rejecting unsupported nested link expressions, while preserving diagnostics for active expressions.
- Detect upstream CMake helpers in included scripts and nested build definitions.
- Leave legal interface dependency cycles to CMake's target graph validation.
- Add synthetic resolver regressions and an optional compiled/assembler compatibility suite.
- Separate CI, manually dispatched compatibility/benchmark suites, and release publication into dedicated workflows. CI now runs `tests/`, default real-Boost integration and every `examples/` project on Linux, Windows and macOS; release tags and assets are created after the `main` CI passes.


## 0.2.4 - 2026-11-20

- Consolidate usage, source selection, lockfile semantics, limitations, examples and test instructions in the README. Correct the shared-cache requirement in the fresh offline build example.
- Remove duplicated contributor documentation and clarify that the resolver benchmark runs only through a separately dispatched GitHub Action.
- Drop an unused internal archive parameter, duplicate comments and redundant test-fixture list construction. Public API and dependency resolution behavior are unchanged.


## 0.2.3 - 2026-11-20

- Resolve conditional Boost target links by evaluating nested generator expressions before dependency discovery. Skip inactive and install-only branches instead of speculatively downloading modules.
- Preserve the union of required targets for multi-config generators and diagnose unsupported link expressions rather than silently guessing.
- Add cross-platform regression cases for conditional dependencies and an offline, reproducible cold/warm/reconfigure benchmark with 24 synthetic Boost modules.

## 0.2.2 - 2026-11-20

- Add one optional `BOOSTPACK_LOCKFILE` setting; automatically create the JSON lockfile if absent and strictly verify Boost version, source endpoint, archive SHA256 and dependency closure if present.
- Keep `BOOSTPACK_CACHE_DIR` and `BOOSTPACK_OFFLINE` as isolated BoostPack options. Remove the duplicate repository and URL-template cache settings and avoid introducing a lockfile mode switch.
- Download and extract Boost source archives independently using CMake file primitives; never modify or consult the host project's FetchContent cache, disconnected flags, declarations or global state.
- Pin transitive archives including version-matched boostorg/cmake support; use HTTPS/TLS verification, file locks, atomic archive downloads, and build-local extraction.
- Exercise online lock generation, locked and unlocked offline builds, tampering, missing and mismatched lock entries, and real Boost integration with CMake 3.22.

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