# Contributing

Preserve the consumer contract: one CMake file, CMake 3.22+, no consumer-side dependency tools, minimal module downloads, and original Boost CMake targets.

## Add or update supported Boost modules

The only manually maintained module selection is [tools/modules.txt](tools/modules.txt). The generator uses the Boost 1.92.0 superproject Git tree and the pinned upstream libraries' CMake files.

~~~sh
python tools/generate_metadata.py --refresh
python tools/generate_metadata.py --check
python tools/generate_metadata.py --verify-upstream
python tools/test_metadata.py
~~~

Commit the generated `tools/boost-1.92.0.json` and `cmake/BoostPack.cmake` together. Python is a **maintainer and CI tool only**, not a consumer dependency.

## Tests

~~~sh
cmake -S . -B build -DBUILD_TESTING=ON
ctest --test-dir build -C Debug --output-on-failure
cmake -S tests/integration -B build/integration
cmake --build build/integration --config Release
ctest --test-dir build/integration -C Release --output-on-failure
cmake -S examples/json -B build/json
cmake --build build/json --config Release
ctest --test-dir build/json -C Release --output-on-failure
~~~

For dependency resolution changes, add an offline CMake regression test. For compiled libraries or unusual build requirements, add a real Boost integration test.

CI publishes a new tagged release from `main` only after metadata verification, configuration, and compiled-library integration pass. The version recorded in both the core module and top-level CMake project must match.
