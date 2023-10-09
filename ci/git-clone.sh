#!/bin/sh
# Recommendation: Place this file in source control.
# Auto-generated by `./dk dksdk.project.new` of DkHelloWorld.
#
# Clone private dependencies (for Linux this can't be done inside the
# dockcross container, because the container has no access to credentials)
# and bleeding edge dependencies.
# These are defined in the CMakePresets.json [ci-agnostic-configure] preset.
#
# We have a chicken-and-egg problem though. We don't know which versions
# of the dependencies to get until we have dksdk-cmake. But we need to get
# dksdk-cmake. So this script can operate in two passes. The first pass
# can be run with -l; that pulls in the latest versions of all the
# dependencies. The next pass, done inside the container and with access to
# the cmake executable, can be run with --pin; that resets each git
# repository to the correct version defined in dksdk-cmake.
#
# Forward looking statement: This should have been, and will likely convert into,
# a `./dk dksdk.project.gitclone` command.

set -euf

DEFAULT_DKSDK_VERSION=1.0

usage() {
  echo "usage: git-clone.sh [options]" >&2
  echo "Options:" >&2
  echo "  -V VERSION:" >&2
  echo "      Set the version of DkSDK to use. Currently supports the Major.Minor version" >&2
  echo "      format. Defaults to $DEFAULT_DKSDK_VERSION" >&2
  echo "  -l:" >&2
  echo "      Get the latest versions of the dependencies" >&2
  echo "  -g GIT_EXE:" >&2
  echo "      Use the specified git executable. Defaults to 'git' in the PATH" >&2
  echo "  -p CMAKE_EXE:" >&2
  echo "      Pin the dependencies to the versions supported by DkSDK." >&2
  echo "      CMAKE_EXE is the path to a CMake executable." >&2
  echo "      Requires that dksdk-cmake is already cloned, so use -l at" >&2
  echo "      least once prior." >&2
  echo "Optional Environment Variables:" >&2
  echo "  GIT_TAG_DKSDK_CMAKE - Git <tag> or <remote>/<branch> for dksdk-cmake" >&2
  echo "  GIT_TAG_DKSDK_OPAM_REPOSITORY - Git <tag> or <remote>/<branch> for dksdk-opam-repository" >&2
  echo "  GIT_TAG_DKSDK_OPAM_REPOSITORY_JS - Git <tag> or <remote>/<branch> for dksdk-opam-repository-js" >&2
  echo "  GIT_TAG_DKML_RUNTIME_COMMON - Git <tag> or <remote>/<branch> for github.com/diskuv/dkml-runtime-common" >&2
  echo "  GIT_TAG_DKML_RUNTIME_DISTRIBUTION - Git <tag> or <remote>/<branch> for github.com/diskuv/dkml-runtime-distribution" >&2
  echo "  GIT_TAG_DKML_COMPILER - Git <tag> or <remote>/<branch> for github.com/diskuv/dkml-compiler" >&2
  echo "  GIT_TAG_OPAM_OVERLAYS - Git <tag> or <remote>/<branch> for github.com/dune-universe/opam-overlays.git" >&2
  echo "  GIT_TAG_OPAM_REPOSITORY - Git <tag> or <remote>/<branch> for github.com/ocaml/opam-repository.git" >&2
  echo "  GIT_URL_DKSDK_CMAKE - Git url for dksdk-cmake" >&2
  echo "  GIT_URL_* - Git url for all the GIT_TAG_* above" >&2
  echo "Examples:" >&2
  echo "  GIT_URL_DKSDK_OPAM_REPOSITORY=git@gitlab.com:diskuv/distributions/1.0/dksdk-opam-repository.git GIT_URL_DKSDK_OPAM_REPOSITORY_JS=git@gitlab.com:diskuv/distributions/1.0/dksdk-opam-repository-js.git sh git-clone.sh -l" >&2
  exit 2
}
pin=
latest=0
dksdk_majmin=$DEFAULT_DKSDK_VERSION
git_exe=git
while getopts V:lp:g: name
do
    case $name in
    V) dksdk_majmin="$OPTARG";;
    l) latest=1;;
    p) pin="$OPTARG";;
    g) git_exe="$OPTARG";;
    ?) usage;;
    esac
done

if [ -z "$pin" ] && [ $latest -eq 0 ]; then
  echo "Either -l or -p must be specified."
  usage
fi

install -d "fetch"
if ! [ -e "fetch/dune" ]; then
  printf '; Created by ci/git-clone.sh. Do not edit.\n(dirs) ; disable scanning of any subdirectories\n' > "fetch/dune"
fi

# On Windows we do not want MSYS2 or Cygwin credentials! The native Windows credentials
# are likely the credentials that can access private repositories (if any).
if [ -x /usr/bin/cygpath ] && [ -n "${USERPROFILE:-}" ] && [ -z "${GIT_CLONE_DISABLE_NATIVE_WIN32:-}" ]; then
  HOME=$(/usr/bin/cygpath -a "$USERPROFILE")
fi

clone() {
  clone_URL=$1; shift
  clone_DIR=$1; shift

  # Header
  clone_LINE=$(echo "$clone_DIR" | sed 's/./_/g')
  printf "%40.40s\n" "$clone_LINE"
  printf "%40.40s\n" "$clone_DIR"

  # Check if there is a pin. C identifier logic must match dksdk-cmake's fetch-git-projects.cmake.
  clone_DIR_C=$(printf "%s" "$clone_DIR" | sed 's/[^A-Za-z0-9_]/_/g; s/^[0-9]/_\0/' | tr '[:lower:]' '[:upper:]')
  eval "clone_OVERRIDE_GITREF=\${GIT_TAG_$clone_DIR_C:-}"
  eval "clone_OVERRIDE_GITURL=\${GIT_URL_$clone_DIR_C:-}"
  # IMPORTANT: Don't display the URL. It may be private.
  if [ -e "fetch/$clone_DIR/.git" ]; then
    printf "%-40.40s\n" "Updating $clone_DIR ..."
    if [ $latest -eq 1 ] || [ -z "$clone_OVERRIDE_GITREF" ]; then
      "$git_exe" -C "fetch/$clone_DIR" pull --ff-only || ( echo "[RECOVERY] Will use a fresh download" ; rm -rf "fetch/$clone_DIR" )
    elif [ -n "$clone_OVERRIDE_GITREF" ]; then
      "$git_exe" -C "fetch/$clone_DIR" fetch
      printf "%-40.40s " "Pinning $clone_DIR ..."
      if ! "$git_exe" -C "fetch/$clone_DIR" reset --hard "$clone_OVERRIDE_GITREF"; then
        echo "[RECOVERY] Will use a fresh download"
        rm -rf "fetch/$clone_DIR"
      fi
    fi
  fi
  if ! [ -e "fetch/$clone_DIR/.git" ]; then
    printf "%-40.40s\n" "Cloning $clone_DIR ..."
    rm -rf "fetch/$clone_DIR"
    if [ -n "$clone_OVERRIDE_GITURL" ]; then
      "$git_exe" -C "fetch" -c advice.detachedHead=false clone "$clone_OVERRIDE_GITURL"
    else
      "$git_exe" -C "fetch" -c advice.detachedHead=false clone "$clone_URL"
    fi
    if [ -n "$clone_OVERRIDE_GITREF" ]; then
      printf "%-40.40s " "Pinning $clone_DIR ..."
      "$git_exe" -C "fetch/$clone_DIR" reset --hard "$clone_OVERRIDE_GITREF"
    fi
  fi
  # Always display recent git commits, especially important for troubleshooting and CI log auditing
  "$git_exe" -C "fetch/$clone_DIR" log --oneline -n4

  # Footer
  printf "%40.40s\n" "$clone_LINE"
  echo
}

# First stage of bootstrapping: Get endpoints we have access to
clone https://gitlab.com/diskuv/dksdk-access.git              dksdk-access
#   Support same mechanism as https://gitlab.com/diskuv/dksdk-access/-/blob/main/cmake/DkSDKAccess.cmake
#     shellcheck disable=SC1091
. fetch/dksdk-access/shells/access.source.sh
dksdk_access "$dksdk_majmin" # Exports _dksdk_BASE_REPOSITORY_URL and _dksdk_cmake_REPOSITORY

# Last stage of bootstrapping: boot-git-clone.sh
#     shellcheck disable=SC2154
clone "${_dksdk_cmake_REPOSITORY}"                            dksdk-cmake
#     Do the [boot-git-clone.sh] command
if [ "$pin" ]; then
  # shellcheck disable=SC2046
  eval $(sh "fetch/dksdk-cmake/shell/boot-git-clone.sh" --schema=1 "--cmake=$pin" | PATH=/usr/bin:/bin tr -d '\r')
fi

# Other DkSDK projects
#     shellcheck disable=SC2154
clone "${_dksdk_BASE_REPOSITORY_URL}/dksdk-ffi-c.git"         dksdk-ffi-c
clone "${_dksdk_BASE_REPOSITORY_URL}/dksdk-ffi-java.git"      dksdk-ffi-java
