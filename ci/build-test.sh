#!/bin/sh
# Recommendation: Place this file in source control.
# Auto-generated by `./dk dksdk.project.new` of SquirrelScout.
set -euf

CMAKE_BUILD_PRESET=${CMAKE_BUILD_PRESET:-ci-main-and-tests}

# shellcheck disable=SC2154
echo "
=============
build-test.sh
=============
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
abi_pattern=$abi_pattern
opam_root=$opam_root
exe_ext=${exe_ext:-}
.
---------------------
CMake Cache Variables
---------------------
$*
.
---------------------
Environment Variables
---------------------
CMAKE_BUILD_PRESET=$CMAKE_BUILD_PRESET
DISABLE_CTEST=${DISABLE_CTEST:-}
.
"

# PATH. Add opamrun
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    export PATH="$CI_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    export PATH="$PC_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    export PATH="$GITHUB_WORKSPACE/.ci/sd4/opamrun:$PATH"
else
    export PATH="$PWD/.ci/sd4/opamrun:$PATH"
fi

# Install CMake, Ninja and Android Command Line Tools if not pre-installed
# and necessary
cmdrun sh ci/download-build-tools.sh "$dkml_host_abi" "$abi_pattern" .ci/local

# Clone private dependencies
cmdrun sh ci/git-clone.sh -p .ci/local/bin/cmake

# Accessors

cmake_run() {
  #   Linux uses a dockcross container accessible with cmdrun
  cmdrun sh ci/exec.sh "$dkml_host_abi" cmake "$@"
}
ctest_run() {
  #   Linux uses a dockcross container accessible with cmdrun
  cmdrun env "CDASH_SquirrelScout_TOKEN=${CDASH_SquirrelScout_TOKEN:-}" sh ci/exec.sh "$dkml_host_abi" ctest "$@"
}
ninja_run() {
  cmdrun ninja "$@"
}

# CMake Diagnostics
cmake_run --version
cmake_run --help # Shows available generators

# Ninja Diagnostics
ninja_run --version

# Configure build using CI presets
root_arg="-DDKSDK_OPAM_ROOT=$opam_root"
case $dkml_host_abi,$abi_pattern in
  #   There is no Redis 32-bit for Windows?
  windows_x86,*)    cmake_run --preset=ci-windows_x86 "$root_arg" "$@" ;;
  windows_x86_64,*) cmake_run --preset=ci-windows_x86_64 "$root_arg" "$@" ;;
  darwin_x86_64,macos-darwin_x86_64)                cmake_run --preset=ci-darwin_x86_64 "$root_arg" "$@" ;;
  darwin_x86_64,macos-darwin_x86_64_X_darwin_arm64) cmake_run --preset=ci-darwin_x86_64_X_darwin_arm64 "$root_arg" "$@" ;;
  darwin_arm64,*)   cmake_run --preset=ci-darwin_arm64 "$root_arg" "$@" ;;
  linux_x86,*linux*-android_x86)                    cmake_run --preset=ci-linux_x86_X_android_x86 "$root_arg" "$@" ;;
  linux_x86,*linux*-android_arm32v7a)               cmake_run --preset=ci-linux_x86_X_android_arm32v7a "$root_arg" "$@" ;;
  linux_x86_64,*linux*-android_x86_64)              cmake_run --preset=ci-linux_x86_64_X_android_x86_64 "$root_arg" "$@" ;;
  linux_x86_64,*linux*-android_arm64v8a)            cmake_run --preset=ci-linux_x86_64_X_android_arm64v8a "$root_arg" "$@" ;;
  linux_x86,*)      cmake_run --preset=ci-linux_x86 "$root_arg" "$@" ;;
  linux_x86_64,*)   cmake_run --preset=ci-linux_x86_64 "$root_arg" "$@" ;;
  *) echo "FATAL: CMake preset unsupported on host ABI $dkml_host_abi and ABI pattern $abi_pattern"; exit 3
esac

# Is this a CI job that should be traced and reported to CDash?
#   This is advanced. See the HelloWorld project's CTestConfig.cmake
#   for setting it up. If it is setup and the CI job sets the
#   SCHEDULED_CTEST_JOB environment variable, delegate everything else to
#   the CTest script.
case "${SCHEDULED_CTEST_JOB:-}" in
  Nightly)
    echo "Running $SCHEDULED_CTEST_JOB CTest with reports forwarded to CDash"
    ctest_run -S "ci/ctest/$SCHEDULED_CTEST_JOB-CTest.cmake" --verbose
    exit
esac

# Build the code
cmake_run --build "--preset=$CMAKE_BUILD_PRESET"

# Test the code and write to JUnit report file
# --verbose will show all the test output (including the fixtures used
# by failed tests).
if [ "${DISABLE_CTEST:-0}" = 0 ] && ! ctest_run --output-junit cmakespec.xml --verbose --preset=ci-test; then
  # Rerun the failed tests so can be seen directly on the CI log output.
  ctest_run --rerun-failed --verbose --preset=ci-test
  # Rerun succeeded. Regardless, we failed earlier so we fail now.
  echo "Even though the rerun of the failed tests succeeded, exiting with failure 4 because original test run failed"
  exit 4
fi
