#!/bin/sh
set -euf

# Reset environment so no conflicts with a parent Opam or OCaml system
unset OPAMROOT
unset OPAM_SWITCH_PREFIX
unset OPAMSWITCH
unset CAML_LD_LIBRARY_PATH
unset OCAMLLIB
unset OCAML_TOPLEVEL_PATH

# For MSYS2 on Windows, stop path conversion from \ to / which messes up
# docker (which is a native Windows command).
export MSYS2_ARG_CONV_EXCL='*'

export PC_PROJECT_DIR="$PWD"
export FDOPEN_OPAMEXE_BOOTSTRAP=false
export CACHE_PREFIX=v1
export OCAML_COMPILER=
export DKML_COMPILER=
export SKIP_OPAM_MODIFICATIONS=false
export PRIMARY_SWITCH_SKIP_INSTALL=false
export SECONDARY_SWITCH=false
export CONF_DKML_CROSS_TOOLCHAIN=
export DISKUV_OPAM_REPOSITORY=
export DKML_HOME=
# autogen from global_env_vars.
export DEFAULT_DKML_COMPILER='4.14.0-v1.1.0-prerel15'
export PIN_ALCOTEST='1.6.0'
export PIN_ALCOTEST_ASYNC='1.6.0'
export PIN_ALCOTEST_JS='1.6.0'
export PIN_ALCOTEST_LWT='1.6.0'
export PIN_ALCOTEST_MIRAGE='1.6.0'
export PIN_BASE='v0.15.1'
export PIN_BASE_BIGSTRING='v0.15.0'
export PIN_BIGSTRINGAF='0.9.0+msvc'
export PIN_CORE='v0.15.1'
export PIN_CORE_KERNEL='v0.15.0'
export PIN_CTYPES_FOREIGN='0.19.2-windowssupport-r5'
export PIN_CTYPES='0.19.2-windowssupport-r5'
export PIN_CURLY='0.2.1-windows-env_r2'
export PIN_DKML_APPS='1.2.1~prerel1'
export PIN_DKML_EXE='1.2.1~prerel1'
export PIN_DUNE='3.6.2'
export PIN_FEATHER='0.3.0'
export PIN_OCAMLBUILD='0.14.0'
export PIN_OCAMLFIND='1.9.1'
export PIN_OCP_INDENT='1.8.2-windowssupport'
export PIN_PPX_EXPECT='v0.15.1'
export PIN_WITH_DKML='1.2.1~prerel1'

# Set matrix variables
# autogen from pc_vars. only linux_x86_64
export dkml_host_os="linux"
export opam_root_cacheable=".ci/o"
export abi_pattern="manylinux2014-linux_x86_64"
export comment="(CentOS 7, etc.)"
export bootstrap_opam_version="2.2.0-alpha-20221228"
export dkml_host_abi="linux_x86_64"
export opam_root=".ci/o"
export dockcross_image="dockcross/manylinux2014-x64"
export dockcross_run_extra_args="--platform linux/amd64"
export in_docker="true"


usage() {
  echo 'Setup Diskuv OCaml (DKML) compiler on a desktop PC.' >&2
  echo 'usage: setup-dkml-linux_x86_64.sh [options]' >&2
  echo 'Options:' >&2

  # Context variables
  echo "  --PC_PROJECT_DIR=<value>. Defaults to the current directory (${PC_PROJECT_DIR})" >&2

  # Input variables
  echo "  --FDOPEN_OPAMEXE_BOOTSTRAP=true|false. Defaults to: ${FDOPEN_OPAMEXE_BOOTSTRAP}" >&2
  echo "  --CACHE_PREFIX=<value>. Defaults to: ${CACHE_PREFIX}" >&2
  echo "  --OCAML_COMPILER=<value>. --DKML_COMPILER takes priority. If --DKML_COMPILER is not set and --OCAML_COMPILER is set, then the specified OCaml version tag of dkml-compiler (ex. 4.12.1) is used. Defaults to: ${OCAML_COMPILER}" >&2
  echo "  --DKML_COMPILER=<value>. Unspecified or blank is the latest from the default branch (main) of dkml-compiler. Defaults to: ${DKML_COMPILER}" >&2
  echo "  --SKIP_OPAM_MODIFICATIONS=true|false. If true then the opam root and switches will not be created or modified. Defaults to: ${SKIP_OPAM_MODIFICATIONS}" >&2
  echo "  --SECONDARY_SWITCH=true|false. If true then the secondary switch named 'two' is created. Defaults to: ${SECONDARY_SWITCH}" >&2
  echo "  --PRIMARY_SWITCH_SKIP_INSTALL=true|false. If true no dkml-base-compiler will be installed in the 'dkml' switch. Defaults to: ${PRIMARY_SWITCH_SKIP_INSTALL}" >&2
  echo "  --CONF_DKML_CROSS_TOOLCHAIN=<value>. Unspecified or blank is the latest from the default branch (main) of conf-dkml-cross-toolchain.  is the latest from Opam. Defaults to: ${CONF_DKML_CROSS_TOOLCHAIN}" >&2
  echo "  --DISKUV_OPAM_REPOSITORY=<value>. Defaults to the value of --DEFAULT_DISKUV_OPAM_REPOSITORY_TAG (see below)" >&2
  echo "  --DKML_HOME=<value>. then DiskuvOCamlHome, DiskuvOCamlBinaryPaths and DiskuvOCamlDeploymentId will be set, in addition to the always-present DiskuvOCamlVarsVersion and DiskuvOCamlVersion." >&2
  echo "  --in_docker=true|false. When true, opamrun and cmdrun will launch commands inside a Docker container. Defaults to '${in_docker:-}'" >&2
  echo "  --dockcross_image=<value>. When --in_docker=true, will be Docker container image. Defaults to '${dockcross_image:-}'" >&2
  echo "  --dockcross_run_extra_args=<value>. When --in_docker=true, will be extra arguments passed to 'docker run'. Defaults to '${dockcross_run_extra_args:-}'" >&2

  # autogen from global_env_vars.
  echo "  --DEFAULT_DKML_COMPILER=<value>. Defaults to: ${DEFAULT_DKML_COMPILER}" >&2
  echo "  --PIN_ALCOTEST=<value>. Defaults to: ${PIN_ALCOTEST}" >&2
  echo "  --PIN_ALCOTEST_ASYNC=<value>. Defaults to: ${PIN_ALCOTEST_ASYNC}" >&2
  echo "  --PIN_ALCOTEST_JS=<value>. Defaults to: ${PIN_ALCOTEST_JS}" >&2
  echo "  --PIN_ALCOTEST_LWT=<value>. Defaults to: ${PIN_ALCOTEST_LWT}" >&2
  echo "  --PIN_ALCOTEST_MIRAGE=<value>. Defaults to: ${PIN_ALCOTEST_MIRAGE}" >&2
  echo "  --PIN_BASE=<value>. Defaults to: ${PIN_BASE}" >&2
  echo "  --PIN_BASE_BIGSTRING=<value>. Defaults to: ${PIN_BASE_BIGSTRING}" >&2
  echo "  --PIN_BIGSTRINGAF=<value>. Defaults to: ${PIN_BIGSTRINGAF}" >&2
  echo "  --PIN_CORE=<value>. Defaults to: ${PIN_CORE}" >&2
  echo "  --PIN_CORE_KERNEL=<value>. Defaults to: ${PIN_CORE_KERNEL}" >&2
  echo "  --PIN_CTYPES_FOREIGN=<value>. Defaults to: ${PIN_CTYPES_FOREIGN}" >&2
  echo "  --PIN_CTYPES=<value>. Defaults to: ${PIN_CTYPES}" >&2
  echo "  --PIN_CURLY=<value>. Defaults to: ${PIN_CURLY}" >&2
  echo "  --PIN_DKML_APPS=<value>. Defaults to: ${PIN_DKML_APPS}" >&2
  echo "  --PIN_DKML_EXE=<value>. Defaults to: ${PIN_DKML_EXE}" >&2
  echo "  --PIN_DUNE=<value>. Defaults to: ${PIN_DUNE}" >&2
  echo "  --PIN_FEATHER=<value>. Defaults to: ${PIN_FEATHER}" >&2
  echo "  --PIN_OCAMLBUILD=<value>. Defaults to: ${PIN_OCAMLBUILD}" >&2
  echo "  --PIN_OCAMLFIND=<value>. Defaults to: ${PIN_OCAMLFIND}" >&2
  echo "  --PIN_OCP_INDENT=<value>. Defaults to: ${PIN_OCP_INDENT}" >&2
  echo "  --PIN_PPX_EXPECT=<value>. Defaults to: ${PIN_PPX_EXPECT}" >&2
  echo "  --PIN_WITH_DKML=<value>. Defaults to: ${PIN_WITH_DKML}" >&2
  exit 2
}
fail() {
  echo "Error: $*" >&2
  exit 3
}
unset file

OPTIND=1
while getopts :h-: option; do
  case $option in
  h) usage ;;
  -) case $OPTARG in
    PC_PROJECT_DIR) fail "Option \"$OPTARG\" missing argument" ;;
    PC_PROJECT_DIR=*) PC_PROJECT_DIR=${OPTARG#*=} ;;
    CACHE_PREFIX) fail "Option \"$OPTARG\" missing argument" ;;
    CACHE_PREFIX=*) CACHE_PREFIX=${OPTARG#*=} ;;
    FDOPEN_OPAMEXE_BOOTSTRAP) fail "Option \"$OPTARG\" missing argument" ;;
    FDOPEN_OPAMEXE_BOOTSTRAP=*) FDOPEN_OPAMEXE_BOOTSTRAP=${OPTARG#*=} ;;
    OCAML_COMPILER) fail "Option \"$OPTARG\" missing argument" ;;
    OCAML_COMPILER=*) OCAML_COMPILER=${OPTARG#*=} ;;
    DKML_COMPILER) fail "Option \"$OPTARG\" missing argument" ;;
    DKML_COMPILER=*) DKML_COMPILER=${OPTARG#*=} ;;
    SKIP_OPAM_MODIFICATIONS) fail "Option \"$OPTARG\" missing argument" ;;
    SKIP_OPAM_MODIFICATIONS=*) SKIP_OPAM_MODIFICATIONS=${OPTARG#*=} ;;
    SECONDARY_SWITCH) fail "Option \"$OPTARG\" missing argument" ;;
    SECONDARY_SWITCH=*) SECONDARY_SWITCH=${OPTARG#*=} ;;
    PRIMARY_SWITCH_SKIP_INSTALL) fail "Option \"$OPTARG\" missing argument" ;;
    PRIMARY_SWITCH_SKIP_INSTALL=*) PRIMARY_SWITCH_SKIP_INSTALL=${OPTARG#*=} ;;
    CONF_DKML_CROSS_TOOLCHAIN) fail "Option \"$OPTARG\" missing argument" ;;
    CONF_DKML_CROSS_TOOLCHAIN=*) CONF_DKML_CROSS_TOOLCHAIN=${OPTARG#*=} ;;
    DISKUV_OPAM_REPOSITORY) fail "Option \"$OPTARG\" missing argument" ;;
    DISKUV_OPAM_REPOSITORY=*) DISKUV_OPAM_REPOSITORY=${OPTARG#*=} ;;
    DKML_HOME) fail "Option \"$OPTARG\" missing argument" ;;
    DKML_HOME=*) DKML_HOME=${OPTARG#*=} ;;
    dockcross_image) fail "Option \"$OPTARG\" missing argument" ;;
    dockcross_image=*) dockcross_image=${OPTARG#*=} ;;
    dockcross_run_extra_args) fail "Option \"$OPTARG\" missing argument" ;;
    dockcross_run_extra_args=*) dockcross_run_extra_args=${OPTARG#*=} ;;
    in_docker) fail "Option \"$OPTARG\" missing argument" ;;
    in_docker=*) in_docker=${OPTARG#*=} ;;
    # autogen from global_env_vars.
    DEFAULT_DKML_COMPILER) fail "Option \"$OPTARG\" missing argument" ;;
    DEFAULT_DKML_COMPILER=*) DEFAULT_DKML_COMPILER=${OPTARG#*=} ;;
    PIN_ALCOTEST) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_ALCOTEST=*) PIN_ALCOTEST=${OPTARG#*=} ;;
    PIN_ALCOTEST_ASYNC) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_ALCOTEST_ASYNC=*) PIN_ALCOTEST_ASYNC=${OPTARG#*=} ;;
    PIN_ALCOTEST_JS) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_ALCOTEST_JS=*) PIN_ALCOTEST_JS=${OPTARG#*=} ;;
    PIN_ALCOTEST_LWT) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_ALCOTEST_LWT=*) PIN_ALCOTEST_LWT=${OPTARG#*=} ;;
    PIN_ALCOTEST_MIRAGE) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_ALCOTEST_MIRAGE=*) PIN_ALCOTEST_MIRAGE=${OPTARG#*=} ;;
    PIN_BASE) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_BASE=*) PIN_BASE=${OPTARG#*=} ;;
    PIN_BASE_BIGSTRING) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_BASE_BIGSTRING=*) PIN_BASE_BIGSTRING=${OPTARG#*=} ;;
    PIN_BIGSTRINGAF) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_BIGSTRINGAF=*) PIN_BIGSTRINGAF=${OPTARG#*=} ;;
    PIN_CORE) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_CORE=*) PIN_CORE=${OPTARG#*=} ;;
    PIN_CORE_KERNEL) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_CORE_KERNEL=*) PIN_CORE_KERNEL=${OPTARG#*=} ;;
    PIN_CTYPES_FOREIGN) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_CTYPES_FOREIGN=*) PIN_CTYPES_FOREIGN=${OPTARG#*=} ;;
    PIN_CTYPES) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_CTYPES=*) PIN_CTYPES=${OPTARG#*=} ;;
    PIN_CURLY) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_CURLY=*) PIN_CURLY=${OPTARG#*=} ;;
    PIN_DKML_APPS) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_DKML_APPS=*) PIN_DKML_APPS=${OPTARG#*=} ;;
    PIN_DKML_EXE) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_DKML_EXE=*) PIN_DKML_EXE=${OPTARG#*=} ;;
    PIN_DUNE) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_DUNE=*) PIN_DUNE=${OPTARG#*=} ;;
    PIN_FEATHER) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_FEATHER=*) PIN_FEATHER=${OPTARG#*=} ;;
    PIN_OCAMLBUILD) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_OCAMLBUILD=*) PIN_OCAMLBUILD=${OPTARG#*=} ;;
    PIN_OCAMLFIND) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_OCAMLFIND=*) PIN_OCAMLFIND=${OPTARG#*=} ;;
    PIN_OCP_INDENT) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_OCP_INDENT=*) PIN_OCP_INDENT=${OPTARG#*=} ;;
    PIN_PPX_EXPECT) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_PPX_EXPECT=*) PIN_PPX_EXPECT=${OPTARG#*=} ;;
    PIN_WITH_DKML) fail "Option \"$OPTARG\" missing argument" ;;
    PIN_WITH_DKML=*) PIN_WITH_DKML=${OPTARG#*=} ;;
    help) usage ;;
    help=*) fail "Option \"${OPTARG%%=*}\" has unexpected argument" ;;
    *) fail "Unknown long option \"${OPTARG%%=*}\"" ;;
    esac ;;
  '?') fail "Unknown short option \"$OPTARG\"" ;;
  :) fail "Short option \"$OPTARG\" missing argument" ;;
  *) fail "Bad state in getopts (OPTARG=\"$OPTARG\")" ;;
  esac
done
shift $((OPTIND - 1))

########################### before_script ###############################

echo "Writing scripts ..."
install -d .ci/sd4

cat > .ci/sd4/common-values.sh <<'end_of_script'
#!/bin/sh

# ------------------------ Log Formatting ------------------------

TXT_SECTION="\e[94m" # bright blue
TXT_CLEAR="\e[0m"

if [ "${GITLAB_CI:-}" = "true" ]; then
    # https://docs.gitlab.com/ee/ci/jobs/#expand-and-collapse-job-log-sections
    print_section_start() {
        print_section_start_NAME=$1
        shift
        printf "\e[0Ksection_start:%s:%s[collapsed=true]\r\e[0K" \
            "$(date +%s)" \
            "$print_section_start_NAME"
    }
    print_section_end() {
        print_section_end_NAME=$1
        shift
        printf "\e[0Ksection_end:%s:%s\r\e[0K\n" \
            "$(date +%s)" \
            "$print_section_end_NAME"
    }
elif [ -n "${GITHUB_ENV:-}" ]; then
    # https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#grouping-log-lines
    print_section_start() {
        print_section_start_NAME=$1
        shift
        printf "::group::"
    }
    print_section_end() {
        print_section_end_NAME=$1
        shift
        printf "::endgroup::\n"
    }
else
    print_section_start() {
        print_section_start_NAME=$1
        shift
    }
    print_section_end() {
        print_section_end_NAME=$1
        shift
    }
fi

section_begin() {
    # https://docs.gitlab.com/ee/ci/yaml/script.html#add-color-codes-to-script-output
    section_NAME=$1
    shift
    section_HEADER=$1
    shift
    print_section_start "$section_NAME"
    printf "${TXT_SECTION}%s${TXT_CLEAR}\n" "$section_HEADER"
}

section_end() {
    section_NAME=$1
    shift
    print_section_end "$section_NAME"
}

# ------------------- Other Functions -----------------

transfer_dir() {
    transfer_dir_SRC=$1
    shift
    transfer_dir_DST=$1
    shift
    # Remove the destination directory completely, but make sure the parent of the
    # destination directory exists so `mv` will work
    install -d "$transfer_dir_DST"
    rm -rf "$transfer_dir_DST"
    # Move
    mv "$transfer_dir_SRC" "$transfer_dir_DST"
}

# Set TEMP variable which is used, among other things, for OCaml's
# [Filename.temp_dir_name] on Win32, and by with-dkml.exe on Windows
export_temp_for_windows() {
    if [ -x /usr/bin/cygpath ]; then
        if [ -n "${RUNNER_TEMP:-}" ]; then
            # GitHub Actions
            TEMP=$(cygpath -am "$RUNNER_TEMP")
        else
            # GitLab CI/CD or desktop
            install -d .ci/tmp
            TEMP=$(cygpath -am ".ci/tmp")
        fi
        export TEMP
    fi
}

# Fixup opam_root on Windows to be mixed case.
# On input the following variables must be present:
# - opam_root
# - opam_root_cacheable
# On output the input variables will be modified _and_ the
# following variables will be available:
# - original_opam_root
# - original_opam_root_cacheable
# - unix_opam_root
# - unix_opam_root_cacheable
fixup_opam_root() {
    # shellcheck disable=SC2034
    original_opam_root=$opam_root
    # shellcheck disable=SC2034
    original_opam_root_cacheable=$opam_root_cacheable
    if [ -x /usr/bin/cygpath ]; then
        opam_root=$(/usr/bin/cygpath -m "$opam_root")
        opam_root_cacheable=$(/usr/bin/cygpath -m "$opam_root_cacheable")
        unix_opam_root=$(/usr/bin/cygpath -u "$opam_root")
        unix_opam_root_cacheable=$(/usr/bin/cygpath -u "$opam_root_cacheable")
    else
        # shellcheck disable=SC2034
        unix_opam_root=$opam_root
        # shellcheck disable=SC2034
        unix_opam_root_cacheable=$opam_root_cacheable
    fi
}
end_of_script

cat > .ci/sd4/run-checkout-code.sh <<'end_of_script'
#!/bin/sh

# ================
# checkout-code.sh
# ================
#
# Checkouts all of the git source code.
#
# This should be done outside of
# dockcross (used by Linux) since a Docker-in-Docker container can have
# difficulties doing a git checkout (the Git credentials for any private
# repositories are likely not present). We don't care about any private
# repositories for DKML but any code that extends this (ex. DKSDK) may
# need to use private repositories.

set -euf

setup_WORKSPACE_VARNAME=$1
shift
setup_WORKSPACE=$1
shift

if [ -x /usr/bin/cygpath ]; then
    setup_WORKSPACE=$(/usr/bin/cygpath -au "$setup_WORKSPACE")
fi

# ------------------------ Functions ------------------------

# shellcheck source=./common-values.sh
. .ci/sd4/common-values.sh

# Disable automatic garbage collection
git_disable_gc() {
    git_disable_gc_NAME=$1
    shift
    git -C ".ci/sd4/g/$git_disable_gc_NAME" config --local gc.auto 0
}

# Mimic the behavior of GitHub's actions/checkout@v3
# - the plus symbol in 'git fetch ... origin +REF:refs/tags/v0.0' overrides any existing REF
git_checkout() {
    git_checkout_NAME=$1
    shift
    git_checkout_URL=$1
    shift
    git_checkout_REF=$1
    shift

    if [ -e ".ci/sd4/g/$git_checkout_NAME" ]; then
        git_disable_gc "$git_checkout_NAME"
        git -C ".ci/sd4/g/$git_checkout_NAME" remote set-url origin "$git_checkout_URL"
        git -C ".ci/sd4/g/$git_checkout_NAME" fetch --no-tags --progress --no-recurse-submodules --depth=1 origin "+${git_checkout_REF}:refs/tags/v0.0"
    else
        install -d ".ci/sd4/g/$git_checkout_NAME"
        git -C ".ci/sd4/g/$git_checkout_NAME" -c init.defaultBranch=main init
        git_disable_gc "$git_checkout_NAME"
        git -C ".ci/sd4/g/$git_checkout_NAME" remote add origin "$git_checkout_URL"
        git -C ".ci/sd4/g/$git_checkout_NAME" fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin "+${git_checkout_REF}:refs/tags/v0.0"
    fi
    git -C ".ci/sd4/g/$git_checkout_NAME" -c advice.detachedHead=false checkout --progress --force refs/tags/v0.0
    git -C ".ci/sd4/g/$git_checkout_NAME" log -1 --format='%H'
}

# ---------------------------------------------------------------------

section_begin checkout-info "Summary: code checkout"

# shellcheck disable=SC2154
echo "
================
checkout-code.sh
================
.
---------
Arguments
---------
WORKSPACE_VARNAME=$setup_WORKSPACE_VARNAME
WORKSPACE=$setup_WORKSPACE
.
------
Inputs
------
VERBOSE=${VERBOSE:-}
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
.
"

section_end checkout-info

install -d .ci/sd4/g

# dkml-runtime-distribution

#   For 'Diagnose Visual Studio environment variables (Windows)' we need dkml-runtime-distribution
#   so that 'Import-Module Machine' and 'Get-VSSetupInstance' can be run.
#   The version doesn't matter too much, as long as it has a functioning Get-VSSetupInstance
#   that supports the Visual Studio versions of the latest GitLab CI and GitHub Actions machines.
#   commit 4d6f1bfc3510c55ba4273cb240e43727854b5718 = WinSDK 19041 and VS 14.29
case "$dkml_host_abi" in
windows_*)
    section_begin checkout-dkml-runtime-distribution 'Checkout dkml-runtime-distribution'
    git_checkout dkml-runtime-distribution https://github.com/diskuv/dkml-runtime-distribution.git "4d6f1bfc3510c55ba4273cb240e43727854b5718"
    section_end checkout-dkml-runtime-distribution
    ;;
esac

end_of_script

cat > .ci/sd4/run-setup-dkml.sh <<'end_of_script'
#!/bin/sh
set -euf

# Constants
SHA512_DEVNULL='cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e'
#   Edited by https://gitlab.com/diskuv/diskuv-ocaml/contributors/release.sh
DEFAULT_DISKUV_OPAM_REPOSITORY_TAG=315a344b354e883c0884eefdb7869a20d1ef5803
# Constants
DKML_VERSION=1.2.1-prerel1

setup_WORKSPACE_VARNAME=$1
shift
setup_WORKSPACE=$1
shift

if [ -x /usr/bin/cygpath ]; then
    setup_WORKSPACE=$(/usr/bin/cygpath -au "$setup_WORKSPACE")
fi

# ------------------ Variables and functions ------------------------

# shellcheck source=./common-values.sh
. .ci/sd4/common-values.sh

if [ "${VERBOSE:-}" = "true" ]; then
    do_tar_rf() {
        tar rvf "$@"
    }
else
    do_tar_rf() {
        tar rf "$@"
    }
fi

# Make the standard input work as an OCaml string.
# This currently only escapes backslashes and double quotes.
escape_arg_as_ocaml_string() {
    escape_arg_as_ocaml_string_ARG=$1
    shift
    printf "%s" "$escape_arg_as_ocaml_string_ARG" | sed 's#\\#\\\\#g; s#"#\\"#g;'
}

# Fixup opam_root on Windows to be mixed case. Set original_* and unix_* as well.
fixup_opam_root

# Set TEMP variable for Windows
export_temp_for_windows

# Load VS studio environment
if [ -e .ci/sd4/vsenv.sh ]; then
    # shellcheck disable=SC1091
    . .ci/sd4/vsenv.sh
fi

# -------------------------------------------------------------------

section_begin setup-info "Summary: setup-dkml"

SKIP_OPAM_MODIFICATIONS=${SKIP_OPAM_MODIFICATIONS:-false} # default is false

# shellcheck disable=SC2154
echo "
=============
setup-dkml.sh
=============
.
---------
Arguments
---------
WORKSPACE_VARNAME=$setup_WORKSPACE_VARNAME
WORKSPACE=$setup_WORKSPACE
.
------
Inputs
------
FDOPEN_OPAMEXE_BOOTSTRAP=${FDOPEN_OPAMEXE_BOOTSTRAP:-}
DISKUV_OPAM_REPOSITORY=${DISKUV_OPAM_REPOSITORY:-}
DKML_COMPILER=${DKML_COMPILER:-}
OCAML_COMPILER=${OCAML_COMPILER:-}
CONF_DKML_CROSS_TOOLCHAIN=${CONF_DKML_CROSS_TOOLCHAIN:-}
SKIP_OPAM_MODIFICATIONS=${SKIP_OPAM_MODIFICATIONS:-}
SECONDARY_SWITCH=${SECONDARY_SWITCH:-}
PRIMARY_SWITCH_SKIP_INSTALL=${PRIMARY_SWITCH_SKIP_INSTALL:-}
MANYLINUX=${MANYLINUX:-}
DKML_HOME=${DKML_HOME:-}
VERBOSE=${VERBOSE:-}
.
-------------------
Generated Constants
-------------------
DKML_VERSION=$DKML_VERSION
DEFAULT_DISKUV_OPAM_REPOSITORY_TAG=$DEFAULT_DISKUV_OPAM_REPOSITORY_TAG
DEFAULT_DKML_COMPILER=$DEFAULT_DKML_COMPILER
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
bootstrap_opam_version=$bootstrap_opam_version
abi_pattern=$abi_pattern
opam_root=${opam_root}
opam_root_cacheable=${opam_root_cacheable}
original_opam_root=${original_opam_root}
original_opam_root_cacheable=${original_opam_root_cacheable}
unix_opam_root=${unix_opam_root}
unix_opam_root_cacheable=${unix_opam_root_cacheable}
dockcross_image=${dockcross_image:-}
dockcross_image_custom_prefix=${dockcross_image_custom_prefix:-}
dockcross_run_extra_args=${dockcross_run_extra_args:-}
docker_runner=${docker_runner:-}
in_docker=${in_docker:-}
ocaml_options=${ocaml_options:-}
.
----
Pins
----
PIN_ALCOTEST=${PIN_ALCOTEST}
PIN_ALCOTEST_ASYNC=${PIN_ALCOTEST_ASYNC}
PIN_ALCOTEST_JS=${PIN_ALCOTEST_JS}
PIN_ALCOTEST_LWT=${PIN_ALCOTEST_LWT}
PIN_ALCOTEST_MIRAGE=${PIN_ALCOTEST_MIRAGE}
PIN_BASE=${PIN_BASE}
PIN_BASE_BIGSTRING=${PIN_BASE_BIGSTRING}
PIN_BIGSTRINGAF=${PIN_BIGSTRINGAF}
PIN_CORE=${PIN_CORE}
PIN_CORE_KERNEL=${PIN_CORE_KERNEL}
PIN_CTYPES_FOREIGN=${PIN_CTYPES_FOREIGN}
PIN_CTYPES=${PIN_CTYPES}
PIN_CURLY=${PIN_CURLY}
PIN_DKML_APPS=${PIN_DKML_APPS}
PIN_DKML_EXE=${PIN_DKML_EXE}
PIN_DUNE=${PIN_DUNE}
PIN_FEATHER=${PIN_FEATHER}
PIN_OCAMLBUILD=${PIN_OCAMLBUILD}
PIN_OCAMLFIND=${PIN_OCAMLFIND}
PIN_OCP_INDENT=${PIN_OCP_INDENT}
PIN_PPX_EXPECT=${PIN_PPX_EXPECT}
PIN_WITH_DKML=${PIN_WITH_DKML}
.
"
case "$dkml_host_abi" in
windows_*)
    # shellcheck disable=SC2153
    echo "
-------------
Visual Studio
-------------
VS_DIR=$VS_DIR
VS_VCVARSVER=$VS_VCVARSVER
VS_WINSDKVER=$VS_WINSDKVER
VS_MSVSPREFERENCE=$VS_MSVSPREFERENCE
VS_CMAKEGENERATOR=$VS_CMAKEGENERATOR
.
"
    ;;
esac
section_end setup-info

do_bootstrap() {
    # Bootstrap from historical release
    runit_BOOTSTRAPPED=0

    #   Bootstrap opam from fdopen (Windows)
    if [ "$runit_BOOTSTRAPPED" = 0 ] && [ "${FDOPEN_OPAMEXE_BOOTSTRAP:-}" = "true" ]; then
        if [ -e .ci/sd4/opam64/bin/opam.exe ] && [ -e .ci/sd4/opam64/bin/opam-installer.exe ]; then
            runit_BOOTSTRAPPED=1
        else
            case "$dkml_host_abi" in
            windows_*)
                echo 'Bootstrap opam from fdopen (Windows) ...'
                install -d .ci/sd4/bs/bin
                wget -O "$setup_WORKSPACE"/.ci/sd4/opam64.tar.xz https://github.com/fdopen/opam-repository-mingw/releases/download/0.0.0.2/opam64.tar.xz

                # this stalls: tar xvCfJ "$setup_WORKSPACE"/.ci/sd4 "$setup_WORKSPACE"/.ci/sd4/opam64.tar.xz
                xz -v -d "$setup_WORKSPACE"/.ci/sd4/opam64.tar.xz
                tar xvCf .ci/sd4 .ci/sd4/opam64.tar

                rm -rf "$setup_WORKSPACE"/.ci/sd4/bs/bin/Opam.Runtime.amd64
                mv -v "$setup_WORKSPACE"/.ci/sd4/opam64/bin/Opam.Runtime.amd64/ "$setup_WORKSPACE"/.ci/sd4/bs/bin/
                mv -v "$setup_WORKSPACE"/.ci/sd4/opam64/bin/opam.exe "$setup_WORKSPACE"/.ci/sd4/bs/bin/
                mv -v "$setup_WORKSPACE"/.ci/sd4/opam64/bin/opam-installer.exe "$setup_WORKSPACE"/.ci/sd4/bs/bin/

                # diagnostics
                ldd "$setup_WORKSPACE"/.ci/sd4/bs/bin/opam.exe
                ldd "$setup_WORKSPACE"/.ci/sd4/bs/bin/opam-installer.exe

                runit_BOOTSTRAPPED=1
                ;;
            esac
        fi
    fi

    #   Bootstrap from historical release
    if [ "$runit_BOOTSTRAPPED" = 0 ] && [ "$bootstrap_opam_version" != "os" ]; then
        install -d .ci/sd4/bs
        cd .ci/sd4/bs

        if [ ! -e version ] || [ "$(cat version)" != "$bootstrap_opam_version" ]; then
            echo 'Bootstrap opam from historical release (non-Windows; Windows non-fdopen) ...'
            if command -v curl > /dev/null 2> /dev/null; then
                curl -L -o opam.tar.gz "https://github.com/diskuv/dkml-component-opam/releases/download/v${bootstrap_opam_version}/dkml-component-staging-opam.tar.gz"
            else
                wget -O opam.tar.gz "https://github.com/diskuv/dkml-component-opam/releases/download/v${bootstrap_opam_version}/dkml-component-staging-opam.tar.gz"
            fi
            tar tvfz opam.tar.gz
            tar xfz opam.tar.gz "./staging-files/${dkml_host_abi}/"
            rm -rf bin/
            mv "staging-files/${dkml_host_abi}/bin" .
            rm -rf "${abi_pattern}"
            printf "%s" "${bootstrap_opam_version}" >version
        fi

        rm -f opam.tar.gz
        cd ../../..

        runit_BOOTSTRAPPED=1
    fi

    #   Bootstrap from package manager or GitHub ocaml/opam release
    case "$runit_BOOTSTRAPPED,$bootstrap_opam_version,$dkml_host_abi" in
    0,os,darwin_*)
        if ! command -v opam; then
            echo 'Bootstrap opam from package manager (macOS) ...'
            brew install gpatch
            brew install opam
        fi
        runit_BOOTSTRAPPED=1
        ;;
    0,os,linux_x86)
        if [ ! -x .ci/sd4/bs/bin/opam ]; then
            echo 'Bootstrap opam from GitHub ocaml/opam release (Linux x86) ...'
            install -d .ci/sd4/bs/bin
            if command -v curl > /dev/null 2> /dev/null; then
                curl -L -o .ci/sd4/bs/bin/opam.tmp https://github.com/ocaml/opam/releases/download/2.1.2/opam-2.1.2-i686-linux
            else
                wget -O .ci/sd4/bs/bin/opam.tmp https://github.com/ocaml/opam/releases/download/2.1.2/opam-2.1.2-i686-linux
            fi
            sha512_check=$(openssl sha512 2>&1 </dev/null | cut -f 2 -d ' ')
            if [ "$SHA512_DEVNULL" = "$sha512_check" ]; then
                sha512=$(openssl sha512 ".ci/sd4/bs/bin/opam.tmp" 2>/dev/null | cut -f 2 -d ' ')
                check="85a480d60e09a7d37fa0d0434ed97a3187434772ceb4e7e8faa5b06bc18423d004af3ad5849c7d35e72dca155103257fd6b1178872df8291583929eb8f884b6a"
                test "$sha512" = "$check"
                chmod +x .ci/sd4/bs/bin/opam.tmp
                mv .ci/sd4/bs/bin/opam.tmp .ci/sd4/bs/bin/opam
            else
                echo "openssl 512 option unsupported."
                exit 61
            fi
        fi
        runit_BOOTSTRAPPED=1
        ;;
    0,os,linux_x86_64)
        if [ ! -x .ci/sd4/bs/bin/opam ]; then
            echo 'Bootstrap opam from GitHub ocaml/opam release (Linux x86_64) ...'
            install -d .ci/sd4/bs/bin
            if command -v curl > /dev/null 2> /dev/null; then
                curl -L -o .ci/sd4/bs/bin/opam.tmp https://github.com/ocaml/opam/releases/download/2.1.2/opam-2.1.2-x86_64-linux
            else
                wget -O .ci/sd4/bs/bin/opam.tmp https://github.com/ocaml/opam/releases/download/2.1.2/opam-2.1.2-x86_64-linux
            fi
            sha512_check=$(openssl sha512 2>&1 </dev/null | cut -f 2 -d ' ')
            if [ "$SHA512_DEVNULL" = "$sha512_check" ]; then
                sha512=$(openssl sha512 ".ci/sd4/bs/bin/opam.tmp" 2>/dev/null | cut -f 2 -d ' ')
                check="c0657ecbd4dc212587a4da70c5ff0402df95d148867be0e1eb1be8863a2851015f191437c3c99b7c2b153fcaa56cac99169c76ec94c5787750d7a59cd1fbb68b"
                test "$sha512" = "$check"
                chmod +x .ci/sd4/bs/bin/opam.tmp
                mv .ci/sd4/bs/bin/opam.tmp .ci/sd4/bs/bin/opam
            else
                echo "openssl 512 option unsupported."
                exit 61
            fi
        fi
        runit_BOOTSTRAPPED=1
        ;;
    esac
}
section_begin bootstrap-opam 'Bootstrap opam'
do_bootstrap
section_end bootstrap-opam

# Start environment distribution tarball
#   We use .tar rather than .tar.gz/.tar.bz2 because we can repeatedly add to an uncompressed .tar. But we need to
#   start with an empty tarball since some tar programs will only add ('tar rf xyz.tar') to an existing .tar.
install -d .ci/sd4/dist
tar cf .ci/sd4/dist/run-with-env.tar -T /dev/null

do_get_dockcross() {
    if [ -n "${dockcross_image:-}" ]; then
        # The dockcross script is super-slow
        section_begin get-dockcross 'Get dockcross binary (ManyLinux)'
        install -d .ci/sd4
        #   shellcheck disable=SC2086
        docker run ${dockcross_run_extra_args:-} --rm "${dockcross_image_custom_prefix:-}${dockcross_image:-}" >.ci/sd4/dockcross.gen

        # PROBLEM 1
        # ---------
        # Super-annoying stderr output from dockcross at line:
        #    tty -s && [ -z "$MSYS" ] && TTY_ARGS=-ti
        # When there is no tty, get:
        #   tty: ignoring all arguments
        #   not a tty
        # So replace 'tty -s &&' with 'false &&'
        sed 's/tty -s &&/false \&\&/' .ci/sd4/dockcross.gen >.ci/sd4/dockcross-real
        rm -f .ci/sd4/dockcross.gen
        chmod +x .ci/sd4/dockcross-real

        # PROBLEM 2
        # ---------
        # By default dockcross for ManyLinux will chown -R all python packages; super-slow (~10 seconds)!
        # Confer: https://github.com/dockcross/dockcross/blob/master/manylinux-common/pre_exec.sh
        # That kills speed for any repetitive dockcross invocation.
        #
        # BUT it is unnecessary to chown -R when the current user is root, because inside the Docker container
        # the files are already root!
        #
        # The chown -R (within pre_exec.sh) is not run when the user ids are not passed in.
        # Confer: https://github.com/dockcross/dockcross/blob/96d87416f639af0204bdd42553e4b99315ca8476/imagefiles/entrypoint.sh#L21-L53
        #
        # So explicitly call the entrypoint if root!
        if echo "${dockcross_run_extra_args:-}" | grep -q linux/386; then
            # https://github.com/dockcross/dockcross/blob/master/linux-x86/linux32-entrypoint.sh
            # But only when `--platform linux/386` because the container image may be overridden.
            dockcross_entrypoint=/dockcross/linux32-entrypoint.sh
        else
            dockcross_entrypoint=/dockcross/entrypoint.sh
        fi
        cat > .ci/sd4/dockcross <<EOF
#!/bin/bash
set -euf
BUILDER_UID="\$( id -u )"
BUILDER_GID="\$( id -g )"
if [ "\$BUILDER_UID" = 0 ] && [ "\$BUILDER_GID" = 0 ]; then
    # ---------- Start of dockcross script snippet -------
    # Verbatim from
    # https://github.com/dockcross/dockcross/blob/96d87416f639af0204bdd42553e4b99315ca8476/imagefiles/dockcross#L175-L204
    # except 1) disabling of USER_IDS

    # Bash on Ubuntu on Windows
    UBUNTU_ON_WINDOWS=\$([ -e /proc/version ] && grep -l Microsoft /proc/version || echo "")
    # MSYS, Git Bash, etc.
    MSYS=\$([ -e /proc/version ] && grep -l MINGW /proc/version || echo "")
    # CYGWIN
    CYGWIN=\$([ -e /proc/version ] && grep -l CYGWIN /proc/version || echo "")

    #if [ -z "\$UBUNTU_ON_WINDOWS" -a -z "\$MSYS" -a "\$OCI_EXE" != "podman" ]; then
    #    USER_IDS=(-e BUILDER_UID="\$( id -u )" -e BUILDER_GID="\$( id -g )" -e BUILDER_USER="\$( id -un )" -e BUILDER_GROUP="\$( id -gn )")
    #fi

    # Change the PWD when working in Docker on Windows
    if [ -n "\$UBUNTU_ON_WINDOWS" ]; then
        WSL_ROOT="/mnt/"
        CFG_FILE=/etc/wsl.conf
            if [ -f "\$CFG_FILE" ]; then
                    CFG_CONTENT=\$(cat \$CFG_FILE | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
                    eval "\$CFG_CONTENT"
                    if [ -n "\$root" ]; then
                            WSL_ROOT=\$root
                    fi
            fi
        HOST_PWD=\`pwd -P\`
        HOST_PWD=\${HOST_PWD/\$WSL_ROOT//}
    elif [ -n "\$MSYS" ]; then
        HOST_PWD=\$PWD
        HOST_PWD=\${HOST_PWD/\//}
        HOST_PWD=\${HOST_PWD/\//:\/}
    elif [ -n "\$CYGWIN" ]; then
        for f in pwd readlink cygpath ; do
            test -n "\$(type "\${f}" )" || { echo >&2 "Missing functionality (\${f}) (in cygwin)." ; exit 1 ; } ;
        done ;
        HOST_PWD="\$( cygpath -w "\$( readlink -f "\$( pwd ;)" ; )" ; )" ;
    else
        HOST_PWD=\$PWD
        [ -L \$HOST_PWD ] && HOST_PWD=\$(readlink \$HOST_PWD)
    fi

    # ---------- End of dockcross script snippet -------

    # Handle: dockcross --args "-v X:Y --platform P"
    ARGS=
    if [ "\$#" -ge 1 ] && [ "\$1" = "--args" ]; then
        shift
        ARGS=\$1
        shift
    fi

    # Directly invoke entrypoint
    exec docker run --entrypoint /bin/bash \
        --rm \
        \${ARGS:-} \
         -v "\$HOST_PWD":/work \
        ${dockcross_image_custom_prefix:-}${dockcross_image:-} ${dockcross_entrypoint} "\$@"
else
    HERE=\$(dirname "\$0")
    HERE=\$(cd "\$HERE" && pwd)
    exec "\$HERE/dockcross-real" "\$@"
fi
EOF
        chmod +x .ci/sd4/dockcross

        # Bundle for consumers of setup-dkml.yml
        do_tar_rf .ci/sd4/dist/run-with-env.tar .ci/sd4/dockcross .ci/sd4/dockcross-real

        section_end get-dockcross
    fi
}
do_get_dockcross

if [ -n "${dockcross_image:-}" ]; then
    # rsync needs to be available, even after Docker container disappears
    if [ ! -e .ci/sd4/bs/bin/rsync ]; then
        section_begin get-opam-prereqs-in-dockcross 'Get Opam prerequisites (ManyLinux)'
        install -d .ci/sd4/bs/bin
        # Install rsync with 'yum' (ManyLinux) or 'apt' (dockcross/linux-x64, etc.)
        # if not present.
        #   shellcheck disable=SC2016
        .ci/sd4/dockcross --args "${dockcross_run_extra_args:-}" sh -c 'if ! command -v rsync; then if command -v yum; then sudo yum install -y rsync; else sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y rsync; fi; fi && install $(command -v rsync) .ci/sd4/bs/bin'
        section_end get-opam-prereqs-in-dockcross
    fi
fi

# Opam prerequisites for using opam (not for installing opam)

{
    if [ -n "${docker_runner:-}" ]; then
        # rsync needs to be available, even after Docker container disappears
        if [ ! -e .ci/sd4/bs/bin/rsync.deps ]; then
            section_begin get-opam-prereqs-in-docker 'Get Opam prerequisites (Linux Docker)'
            install -d .ci/sd4/bs/bin
            ${docker_runner} sh -c '
            apt-get update -qq -o=Dpkg::Use-Pty=0 &&
            apt-get install -qq -o=Dpkg::Use-Pty=0 -y rsync &&
            ldd /usr/bin/rsync &&
            ls -l /lib/i386-linux-gnu/libpopt.so.0 /lib/i386-linux-gnu/libacl.so.1 /lib/i386-linux-gnu/libattr.so.1 &&
            tar cCfhz / /work/.ci/sd4/bs/bin/deps.tar.gz /usr/bin/rsync /lib/i386-linux-gnu/libpopt.so.0
        '
            touch .ci/sd4/bs/bin/rsync.deps
            section_end get-opam-prereqs-in-docker
        fi
    fi

    # Bundle Opam prerequisites (ManyLinux or Linux Docker)
    if [ -n "${docker_runner:-}" ] || [ -n "${dockcross_image:-}" ]; then
        # Bundle for consumers of setup-dkml.yml
        do_tar_rf .ci/sd4/dist/run-with-env.tar .ci/sd4/bs/bin/rsync
    fi
}

# Get Opam Cache
do_get_opam_cache() {
    if [ "$unix_opam_root_cacheable" = "$unix_opam_root" ]; then return; fi
    if [ ! -e "$unix_opam_root_cacheable" ]; then return; fi
    section_begin get-opam-cache "Transferring Opam cache to $original_opam_root_cacheable"
    echo Starting transfer # need some output or GitLab CI will not display the section duration
    transfer_dir "$unix_opam_root_cacheable" "$unix_opam_root"
    echo Finished transfer
    section_end get-opam-cache
}
do_get_opam_cache

# Setup Opam

do_write_opam_scripts() {
    case "${FDOPEN_OPAMEXE_BOOTSTRAP:-},$dkml_host_abi" in
    true,windows_*)
        # With fdopen's opam.exe, 'os-distribution = "cygwinports"'. But native Windows opam.exe has 'os-distribution = "win32"'.
        # But on Windows we always want MSYS2 or native Windows libraries, not Cygwin. If cygwinports then
        # code like https://github.com/ocaml/opam-repository/blob/08cbb8258bd4bf30cd6f307c958911a29d537b54/packages/conf-pkg-config/conf-pkg-config.2/opam#L36
        # will fail. So always set 'os-distribution = "win32"' on Windows.
        PATCH_OS_DISTRIBUTION_WIN32=true
        # With fdopen's opam.exe, no 'exe = ".exe"' is set because Cygwin does not need file extensions.
        # Native Windows requires a .exe extension.
        PATCH_EXE_WIN32=true
        ;;
    *)
        PATCH_OS_DISTRIBUTION_WIN32=false
        PATCH_EXE_WIN32=false
        ;;
    esac

    # ---------------------
    # Empty opam repository
    # ---------------------

    install -d .ci/sd4/eor
    cat >.ci/sd4/eor/repo <<EOF
opam-version: "2.0"
browse: "https://opam.ocaml.org/pkg/"
upstream: "https://github.com/ocaml/opam-repository/tree/master/"
EOF

    # ---------------
    # Create Opam troubleshooting script
    #   Dump logs modified within the last 4 hours
    # ---------------

    cat >.ci/sd4/troubleshoot-opam.sh <<EOF
#!/bin/sh
set -euf
OPAMROOT=\$1
shift
if find . -maxdepth 0 -mmin -240 2>/dev/null >/dev/null; then
    FINDARGS="-mmin -240" # is -mmin supported? BSD (incl. macOS), MSYS2, GNU
else
    FINDARGS="-mtime -1" # use 1 day instead. Solaris
fi
printf "\n\n========= [START OF TROUBLESHOOTING] ===========\n\n" >&2
find "\$OPAMROOT"/log -mindepth 1 -maxdepth 1 \$FINDARGS -name "*.out" ! -name "log-*.out" ! -name "ocaml-variants-*.out" | while read -r dump_on_error_LOG; do
    dump_on_error_BLOG=\$(basename "\$dump_on_error_LOG")
    printf "\n\n========= [TROUBLESHOOTING] %s ===========\n\n" "\$dump_on_error_BLOG" >&2
    awk -v BLOG="\$dump_on_error_BLOG" '{print "[" BLOG "]", \$0}' "\$dump_on_error_LOG" >&2
done
printf "\nScroll up to see the [TROUBLESHOOTING] logs that begin at the [START OF TROUBLESHOOTING] line\n" >&2
EOF

    chmod +x .ci/sd4/troubleshoot-opam.sh
    do_tar_rf .ci/sd4/dist/run-with-env.tar .ci/sd4/troubleshoot-opam.sh

    # ---------------
    # Create Opam support scripts (not needed for all platforms)
    #   The PATH to find opam must work internally in setup-dkml.yml (sd4/bs/bin) and
    #   by consumers of setup-dkml.yml (sd4/opamexe)
    # ---------------

    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    USER_NAME=$(id -un)
    GROUP_NAME=$(id -gn)

    case "${opam_root}" in
    /* | ?:*) # /a/b/c or C:\Windows
        validate_supports_docker() {
            echo "Docker only supported with relative paths for the opam root, not: ${opam_root}" >&2
            exit 3
        }
        ;;
    *) # relative path
        validate_supports_docker() {
            true
        }
        cat >.ci/sd4/run-in-docker <<EOF
#!/bin/sh
set -euf
export PATH="/work/.ci/local/bin:/work/.ci/sd4/bs/bin:/work/.ci/sd4/opamexe:\$PATH"
export OPAMROOT=/work/${opam_root}
export OPAMROOTISOK=1
if [ "${PATCH_OS_DISTRIBUTION_WIN32}" = true ]; then export OPAMVAR_os_distribution=win32; fi
if [ "${PATCH_EXE_WIN32}" = true ]; then export OPAMVAR_exe=.exe; fi

# Reset environment so no conflicts with a parent Opam or OCaml system
unset OPAM_SWITCH_PREFIX
unset OPAMSWITCH
unset CAML_LD_LIBRARY_PATH
unset OCAMLLIB
unset OCAML_TOPLEVEL_PATH

prog=\$1
shift

# Optionally skip troubleshooting
troubleshooting=1
if [ "\$#" -ge 1 ] && [ "\$prog" = opam ] && [ "\$1" = "--no-troubleshooting" ]; then
    shift
    troubleshooting=0
fi

echo "Running inside Docker container: \$prog \$*" >&2
set +e
"\$prog" "\$@"
exitcode=\$?
if [ \$troubleshooting = 1 ] && [ \$prog = opam ]; then
    [ \$exitcode = 0 ] || "/work/.ci/sd4/troubleshoot-opam.sh" \$OPAMROOT
fi
exit \$exitcode
EOF
        chmod +x .ci/sd4/run-in-docker
        ;;
    esac

    cat >.ci/sd4/deescalate <<EOF
#!/bin/sh
set -euf

if [ -e /work/.ci/sd4/bs/bin/deps.tar.gz ]; then
    tar xCfz / /work/.ci/sd4/bs/bin/deps.tar.gz
fi

groupadd -g ${GROUP_ID} ${GROUP_NAME}
useradd -l -m -u ${USER_ID} -g ${GROUP_ID} ${USER_NAME}
exec runuser -u ${USER_NAME} -g ${GROUP_NAME} -- "\$@"
EOF

    chmod +x .ci/sd4/deescalate

    # -----------------------------------
    # Create run-with-env
    # -----------------------------------

    install -d .ci/sd4/dist

    if [ -x .ci/sd4/dockcross ]; then
        # Adding empty dockcross root volume avoids:
        #    cp: target ‘/home/root/’ is not a directory
        #    chown: cannot access ‘/home/root’: No such file or directory
        # from https://github.com/dockcross/dockcross/blob/96d87416f639af0204bdd42553e4b99315ca8476/imagefiles/entrypoint.sh#L31-L32
        install -d .ci/sd4/edr

        cat >.ci/sd4/run-with-env <<EOF
#!/bin/sh
set -euf

HERE=\$(dirname "\$0")
HERE=\$(cd "\$HERE" && pwd)
PROJECT_DIR=\$(cd "\$HERE"/../.. && pwd)

# Optionally enable terminal if and only if '-it' option given
termargs=
if [ "\$#" -ge 1 ] && [ "\$1" = "-it" ]; then
    shift
    termargs=-it
fi

exec bash "\${PROJECT_DIR}"/.ci/sd4/dockcross --args "\${termargs} -v \${PROJECT_DIR}/.ci/sd4/edr:/home/root ${dockcross_run_extra_args:-}" /work/.ci/sd4/run-in-docker "\$@"
EOF
        chmod +x .ci/sd4/run-with-env

        validate_supports_docker

        # Bundle for consumers of setup-dkml.yml
        echo '__ run-in-docker __' >&2
        cat .ci/sd4/run-in-docker >&2
        echo '___________________' >&2
        do_tar_rf .ci/sd4/dist/run-with-env.tar .ci/sd4/run-with-env .ci/sd4/run-in-docker .ci/sd4/edr

    elif [ -n "${docker_runner:-}" ]; then

        cat >.ci/sd4/run-with-env <<EOF
#!/bin/sh
set -euf
exec ${docker_runner:-} /work/.ci/sd4/deescalate /work/.ci/sd4/run-in-docker "\$@"
EOF
        chmod +x .ci/sd4/run-with-env

        validate_supports_docker

        # Bundle for consumers of setup-dkml.yml
        echo '__ run-in-docker __' >&2
        cat .ci/sd4/run-in-docker >&2
        echo '________________________' >&2
        echo '__ deescalate __' >&2
        cat .ci/sd4/deescalate >&2
        echo '________________' >&2
        do_tar_rf .ci/sd4/dist/run-with-env.tar .ci/sd4/run-with-env .ci/sd4/run-in-docker .ci/sd4/deescalate

    else

        cat >.ci/sd4/run-with-env <<EOF
#!/bin/sh
set -euf

HERE=\$(dirname "\$0")
HERE=\$(cd "\$HERE" && pwd)
PROJECT_DIR=\$(cd "\$HERE"/../.. && pwd)

export PATH="\${PROJECT_DIR}/.ci/local/bin:\${PROJECT_DIR}/.ci/sd4/bs/bin:\${PROJECT_DIR}/.ci/sd4/opamexe:\$PATH"
export OPAMROOT='${opam_root}'
export OPAMROOTISOK=1
if [ "${PATCH_OS_DISTRIBUTION_WIN32}" = true ]; then export OPAMVAR_os_distribution=win32; fi
if [ "${PATCH_EXE_WIN32}" = true ]; then export OPAMVAR_exe=.exe; fi

# Reset environment so no conflicts with a parent Opam or OCaml system
unset OPAM_SWITCH_PREFIX
unset OPAMSWITCH
unset CAML_LD_LIBRARY_PATH
unset OCAMLLIB
unset OCAML_TOPLEVEL_PATH

prog=\$1
shift

# Optionally skip troubleshooting
troubleshooting=1
if [ "\$#" -ge 1 ] && [ "\$prog" = opam ] && [ "\$1" = "--no-troubleshooting" ]; then
    shift
    troubleshooting=0
fi

echo "Running: \$prog \$*" >&2
set +e
"\$prog" "\$@"
exitcode=\$?
if [ \$troubleshooting = 1 ] && [ \$prog = opam ]; then
    [ \$exitcode = 0 ] || "\${PROJECT_DIR}/.ci/sd4/troubleshoot-opam.sh" \$OPAMROOT
fi
exit \$exitcode
EOF
        chmod +x .ci/sd4/run-with-env

        # Bundle for consumers of setup-dkml.yml
        do_tar_rf .ci/sd4/dist/run-with-env.tar .ci/sd4/run-with-env

    fi
    echo '__ run-with-env __' >&2
    cat .ci/sd4/run-with-env >&2
    echo '__________________' >&2

    # ------
    # cmdrun
    # ------

    install -d .ci/sd4/opamrun
    cat >.ci/sd4/opamrun/cmdrun <<EOF
#!/bin/sh
set -euf

HERE=\$(dirname "\$0")
HERE=\$(cd "\$HERE" && pwd)
PROJECT_DIR=\$(cd "\$HERE"/../../.. && pwd)

# Add MSVC compiler environment if available
if [ -e "\${PROJECT_DIR}/.ci/sd4/msvcenv" ]; then
    _oldpath="\$PATH"
    # shellcheck disable=SC1091
    . "\${PROJECT_DIR}/.ci/sd4/msvcenv"
    PATH="\$PATH:\$_oldpath"

    # MSVC (link.exe) needs a TMP as well.
    # Confer: https://docs.microsoft.com/en-us/cpp/build/reference/linking?view=msvc-170#link-environment-variables
    if [ -z "\${TMP:-}" ]; then
        # GitHub Actions as of 2022-10 does not set TMP. GitLab CI/CD does.
        TMP="\$RUNNER_TEMP"
    fi
    export TMP
    if [ -x /usr/bin/cygpath ]; then
        TMP=\$(/usr/bin/cygpath -aw "\$TMP")
    fi
fi

# Windows
if [ -n "\${COMSPEC:-}" ]; then
    # We must place MSYS2 in front of path so that MSYS2
    # tar.exe is used instead of Windows tar.exe.
    PATH="/usr/bin:\$PATH"
fi

exec "\${PROJECT_DIR}/.ci/sd4/run-with-env" "\$@"
EOF
    chmod +x .ci/sd4/opamrun/cmdrun

    # -------
    # opamrun
    # -------

    install -d .ci/sd4/opamrun
    cat >.ci/sd4/opamrun/opamrun <<EOF
#!/bin/sh
set -euf

HERE=\$(dirname "\$0")
HERE=\$(cd "\$HERE" && pwd)
PROJECT_DIR=\$(cd "\$HERE"/../../.. && pwd)

exec "\${PROJECT_DIR}/.ci/sd4/opamrun/cmdrun" opam "\$@"
EOF
    chmod +x .ci/sd4/opamrun/opamrun

    # Bundle for consumers of setup-dkml.yml
    do_tar_rf .ci/sd4/dist/run-with-env.tar .ci/sd4/opamrun
}
section_begin 'write-opam-scripts' 'Write opam scripts'
do_write_opam_scripts
section_end 'write-opam-scripts'

# Expose opamrun (also used for consumers of setup-dkml.yml) to GitHub
if [ -n "${GITHUB_PATH:-}" ]; then
    opamrunabs="$setup_WORKSPACE/.ci/sd4/opamrun"
    if [ -x /usr/bin/cygpath ]; then opamrunabs=$(/usr/bin/cygpath -aw "$opamrunabs"); fi
    echo "$opamrunabs" >>"$GITHUB_PATH"
    # Special case: GITHUB_PATH does not influence msys2.CMD of msys2/setup-msys2@v2, so place in real MSYS2 PATH
    if [ -n "${MSYSTEM:-}" ]; then
        install -d /usr/local/bin
        install .ci/sd4/opamrun/opamrun /usr/local/bin/opamrun
    fi
fi

# Place opamrun in the immediate PATH
PATH="$setup_WORKSPACE/.ci/sd4/opamrun:$PATH"

#   Complicated Opam sequence is because:
#   1. Opam's default curl does not work on Windows,
#      and `opam init` does not provide a way to change it (TODO: need
#      a PR!).
#   2. We have to separate the Opam download cache from the other Opam
#      caches
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ] && [ ! -s "$opam_root/.ci.root-init" ]; then # non-empty init file so can be cached irrespective of existence
    section_begin opam-init 'Initialize opam root'

    # Clear any partial previous attempt
    rm -rf "$opam_root"

    case "$dkml_host_abi,${in_docker:-}" in
    windows_*,*)
        eor=$(cygpath -am "$setup_WORKSPACE"/.ci/sd4/eor)
        opamrun init --disable-sandboxing --no-setup --kind local --bare "$eor"
        case "$(opamrun --version)" in
        2.0.*) echo 'download-command: wget' >>"$opam_root/config" ;;
        *) opamrun option --yes --global download-command=wget ;;
        esac
        ;;
    *,true)
        opamrun init --disable-sandboxing --no-setup --kind local --bare "/work/.ci/sd4/eor"
        ;;
    *)
        opamrun init --disable-sandboxing --no-setup --kind local --bare "$setup_WORKSPACE/.ci/sd4/eor"
        ;;
    esac
    echo yes > "$opam_root/.ci.root-init"

    section_end opam-init
fi

if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    section_begin opam-vars "Summary: opam global variables"
    opamrun --no-troubleshooting var --global || true
    section_end opam-vars
fi

# Build OCaml

do_switch_create() {
    do_switch_create_NAME=$1
    shift

    section_begin "switch-create-$do_switch_create_NAME" "Create opam switch '$do_switch_create_NAME'"
    # Create, or recreate, the Opam switch. The Opam switch should not be
    # cached except for the compiler (confer docs for setup-ocaml GitHub
    # Action) which is the 'dkml' switch (or the 'two' switch).
    # Check if the switch name is present in the Opam root (which may come from cache)
    NOMINALLY_PRESENT=false
    if opamrun switch list --short | grep "^${do_switch_create_NAME}\$"; then NOMINALLY_PRESENT=true; fi

    # Check if the switch is actually present in case of cache incoherence
    # or corrupt Opam state that could result in:
    #   Error:  No config file found for switch dkml. Switch broken?
    if [ $NOMINALLY_PRESENT = true ] && [ ! -e "$opam_root/$do_switch_create_NAME/.opam-switch/switch-config" ]; then
        # Remove the switch name from Opam root, and any partial switch state.
        # Ignore inevitable warnings/failure about missing switch.
        opamrun --no-troubleshooting switch remove "$do_switch_create_NAME" --yes || true
        rm -rf "${opam_root:?}/$do_switch_create_NAME"
        NOMINALLY_PRESENT=false
    fi

    if [ $NOMINALLY_PRESENT = false ]; then
        opamrun switch create "$do_switch_create_NAME" --empty --yes
    fi
    section_end "switch-create-$do_switch_create_NAME"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_switch_create dkml
    if [ "${SECONDARY_SWITCH:-}" = "true" ]; then
        do_switch_create two
    else
        section_begin "switch-create-two" "Create empty opam switch 'two'"
        # Always create a secondary switch ... just empty. Avoid problems with cache content missing
        # and idempotency.
        opamrun --no-troubleshooting switch remove two --yes || true
        rm -rf "$opam_root/two"
        opamrun switch create two --empty --yes
        section_end "switch-create-two"
    fi
fi

do_switch_active() {
    section_begin "switch-active" "Set dkml as active switch"
    opamrun switch set dkml --yes
    section_end "switch-active"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_switch_active
fi

do_opam_repositories_add() {
    section_begin "opam-repo-add" "Add 'diskuv' opam repository"
    if ! opamrun --no-troubleshooting repository list -s | grep '^diskuv'; then
        opamrun repository add diskuv "git+https://github.com/diskuv/diskuv-opam-repository.git#${DISKUV_OPAM_REPOSITORY:-$DEFAULT_DISKUV_OPAM_REPOSITORY_TAG}" --yes --dont-select
    fi
    section_end "opam-repo-add"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_opam_repositories_add
fi

do_opam_repositories_config() {
    do_opam_repositories_config_NAME=$1
    shift

    section_begin "opam-repo-$do_opam_repositories_config_NAME" "Attach repositories to $do_opam_repositories_config_NAME"

    if [ ! -s "$opam_root/.ci.$do_opam_repositories_config_NAME.repo-init" ]; then # non-empty init file so can be cached irrespective of existence
        opamrun --no-troubleshooting repository remove default --switch "$do_opam_repositories_config_NAME" --yes || true
        opamrun --no-troubleshooting repository remove diskuv --switch "$do_opam_repositories_config_NAME" --yes || true
        opamrun repository add default --switch "$do_opam_repositories_config_NAME" --yes
        opamrun repository add diskuv --switch "$do_opam_repositories_config_NAME" --yes
        echo yes > "$opam_root/.ci.$do_opam_repositories_config_NAME.repo-init"
    fi

    section_end "opam-repo-$do_opam_repositories_config_NAME"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_opam_repositories_config dkml
    if [ "${SECONDARY_SWITCH:-}" = "true" ]; then
        do_opam_repositories_config two
    fi
fi

do_opam_repositories_update() {
    section_begin "opam-repo-update" "Update opam repositories"
    # The default repository may be the initial 'eor' (empty) repository
    opamrun repository set-url default https://opam.ocaml.org --yes
    # Always set the `diskuv` repository url since it can change
    opamrun repository set-url diskuv "git+https://github.com/diskuv/diskuv-opam-repository.git#${DISKUV_OPAM_REPOSITORY:-$DEFAULT_DISKUV_OPAM_REPOSITORY_TAG}" --yes --dont-select
    # Update both `default` and `diskuv` Opam repositories
    opamrun update default diskuv
    section_end "opam-repo-update"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_opam_repositories_update
fi

do_pins() {
    do_pins_NAME=$1
    shift

    # dkml-base-compiler

    if [ "${DKML_COMPILER:-}" != '' ] && [ -z "${DKML_COMPILER:-}" ] && [ -z "${OCAML_COMPILER:-}" ]; then
        section_begin checkout-dkml-base-compiler "Pin dkml-base-compiler to default ${DEFAULT_DKML_COMPILER} (neither dkml-base-compiler nor OCAML_COMPILER specified) for $do_pins_NAME switch"
        opamrun pin add --switch "$do_pins_NAME" --yes --no-action dkml-base-compiler "https://github.com/diskuv/dkml-compiler.git#${DEFAULT_DKML_COMPILER}"
        section_end checkout-dkml-base-compiler
    elif [ "${DKML_COMPILER:-}" != '' ] && [ -n "${DKML_COMPILER:-}" ] && [ -z "${OCAML_COMPILER:-}" ]; then
        section_begin checkout-dkml-base-compiler "Pin dkml-base-compiler to $DKML_COMPILER (dkml-base-compiler specified; no OCAML_COMPILER specified) for $do_pins_NAME switch"
        opamrun pin add --switch "$do_pins_NAME" --yes --no-action dkml-base-compiler "https://github.com/diskuv/dkml-compiler.git#${DKML_COMPILER}"
        section_end checkout-dkml-base-compiler
    elif [ -n "${OCAML_COMPILER:-}" ]; then
        # Validate OCAML_COMPILER (OCAML_COMPILER specified)
        case "${OCAML_COMPILER:-}" in
        4.12.1) true ;;
        4.14.0) true ;;
        *)
            echo "OCAML_COMPILER version ${OCAML_COMPILER:-} is not supported" >&2
            exit 109
            ;;
        esac

        section_begin checkout-dkml-base-compiler "Pin dkml-base-compiler (OCAML_COMPILER specified) for $do_pins_NAME switch"
        opamrun pin add --switch "$do_pins_NAME" --yes --no-action dkml-base-compiler "https://github.com/diskuv/dkml-compiler.git#${OCAML_COMPILER}-v${DKML_VERSION}"
        section_end checkout-dkml-base-compiler
    fi

    # conf-dkml-cross-toolchain

    if [ "${CONF_DKML_CROSS_TOOLCHAIN:-}" != '' ]; then
        section_begin checkout-conf-dkml-cross-toolchain "Pin conf-dkml-cross-toolchain for $do_pins_NAME switch"
        opamrun pin add --switch "$do_pins_NAME" --yes --no-action conf-dkml-cross-toolchain "https://github.com/diskuv/conf-dkml-cross-toolchain.git#$CONF_DKML_CROSS_TOOLCHAIN"
        section_end checkout-conf-dkml-cross-toolchain
    fi

    # patches necessary for Windows in diskuv-opam-repository
    #
    # - ocamlfind and ocamlbuild
    #
    # - dune-configurator (and hence Dune)
    # Dune 2.9.1 and 3.0.2 will fail to build jst-config.v0.14.1 because for jst-config/discover/discover.ml Dune does:
    #   cl -nologo -O2 -Gy- -MD    -I Z:/.opam_root-cached-8/installer-ocaml/lib/ocaml -o C:\Users\beckf\AppData\Local\Temp\build_f18aec_dune\ocaml-configurator4d3858\c-test-31\test.obj -c C:\Users\beckf\AppData\Local\Temp\build_f18aec_dune\ocaml-configurator4d3858\c-test-31\test.c advapi32.lib ws2_32.lib version.lib
    # instead of
    #   cl -nologo -O2 -Gy- -MD    -I Z:/.opam_root-cached-8/installer-ocaml/lib/ocaml /FoC:\Users\beckf\AppData\Local\Temp\build_f18aec_dune\ocaml-configurator4d3858\c-test-31\test.obj -c C:\Users\beckf\AppData\Local\Temp\build_f18aec_dune\ocaml-configurator4d3858\c-test-31\test.c advapi32.lib ws2_32.lib version.lib
    # with the (irrelevant) test.c file:
    #    #include <stdio.h>
    #    #include <caml/config.h>
    #
    #    #ifdef ARCH_BIG_ENDIAN
    #    const char *s0 = "BEGIN-0-true-END";
    #    #else
    #    const char *s0 = "BEGIN-0-false-END";
    #    #endif
    #
    #    #ifdef ARCH_SIXTYFOUR
    #    const char *s1 = "BEGIN-1-true-END";
    #    #else
    #    const char *s1 = "BEGIN-1-false-END";
    #    #endif
    #
    # The actual problem is dune-configurator ... we only have patches in Diskuv
    # repository up until 2.9.3. Need to upstream fix the problem.
    #
    # - ppx_expect; only patch is for v0.14.1. Need to upstream fix the problem.
    # - base; patches for v0.14.1/2/3. Need to upstream fix the problem.
    section_begin "opam-pins-$do_pins_NAME" "Opam pins for $do_pins_NAME switch"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version alcotest "${PIN_ALCOTEST}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version alcotest-async "${PIN_ALCOTEST_ASYNC}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version alcotest-js "${PIN_ALCOTEST_JS}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version alcotest-lwt "${PIN_ALCOTEST_LWT}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version alcotest-mirage "${PIN_ALCOTEST_MIRAGE}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version base "${PIN_BASE}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version base_bigstring "${PIN_BASE_BIGSTRING}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version bigstringaf "${PIN_BIGSTRINGAF}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version core "${PIN_CORE}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version core_kernel "${PIN_CORE_KERNEL}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version ctypes "${PIN_CTYPES}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version ctypes-foreign "${PIN_CTYPES_FOREIGN}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version curly "${PIN_CURLY}"
    opamrun pin remove --switch "$do_pins_NAME"  --yes --no-action digestif # this used to be pinned, so any cached opamroot needs it unpinned
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version dkml-apps "${PIN_DKML_APPS}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version dkml-exe "${PIN_DKML_EXE}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version dune "${PIN_DUNE}"
    opamrun pin remove --switch "$do_pins_NAME"  --yes --no-action dune-configurator # this used to be pinned, so any cached opamroot needs it unpinned
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version feather "${PIN_FEATHER}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version ocamlbuild "${PIN_OCAMLBUILD}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version ocamlfind "${PIN_OCAMLFIND}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version ocp-indent "${PIN_OCP_INDENT}"
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version ppx_expect "${PIN_PPX_EXPECT}"
    opamrun pin remove --switch "$do_pins_NAME"  --yes --no-action ptime # this used to be pinned, so any cached opamroot needs it unpinned
    opamrun pin remove --switch "$do_pins_NAME"  --yes --no-action time_now # this used to be pinned, so any cached opamroot needs it unpinned
    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version with-dkml "${PIN_WITH_DKML}"
    section_end "opam-pins-$do_pins_NAME"
}

if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_pins dkml
    if [ "${SECONDARY_SWITCH:-}" = "true" ]; then
        do_pins two
    fi
fi

do_use_vsstudio() {
    do_use_vsstudio_NAME=$1
    shift
    case "$dkml_host_abi" in
    windows_*)
        section_begin "use-vsstudio-$do_use_vsstudio_NAME" "Use Visual Studio in dkml-* Opam packages (Windows) for $do_use_vsstudio_NAME switch"

        # shellcheck disable=SC2153
        E_VS_DIR=$(escape_arg_as_ocaml_string "$VS_DIR")
        # shellcheck disable=SC2153
        E_VS_VCVARSVER=$(escape_arg_as_ocaml_string "$VS_VCVARSVER")
        # shellcheck disable=SC2153
        E_VS_WINSDKVER=$(escape_arg_as_ocaml_string "$VS_WINSDKVER")
        # shellcheck disable=SC2153
        E_VS_MSVSPREFERENCE=$(escape_arg_as_ocaml_string "$VS_MSVSPREFERENCE")
        # shellcheck disable=SC2153
        E_VS_CMAKEGENERATOR=$(escape_arg_as_ocaml_string "$VS_CMAKEGENERATOR")

        case "$(opamrun --version)" in
        2.0.*)
            if [ "${in_docker}" = "true" ]; then
                echo Opam 2.0 support in dockcross to use a portable opam var prefix not yet implemented
                exit 67
            fi
            OP=$(opamrun var prefix --switch "$do_use_vsstudio_NAME")
            OPSC=$OP/.opam-switch/switch-config
            if grep setenv: "$OPSC"; then
                echo "INFO: Updating switch-config. Old was:"
                awk '{print ">> " $0}' "$OPSC"

                awk '$1=="setenv:"{x=1} x==0{print} x==1 && $0=="]"{x=0}' "$OPSC" >"$OPSC".trimmed
                mv "$OPSC".trimmed "$OPSC"
            fi
            echo 'setenv: [' >>"$OPSC"
            echo '  [DKML_COMPILE_SPEC = "1"]' >>"$OPSC"
            echo '  [DKML_COMPILE_TYPE = "VS"]' >>"$OPSC"
            echo "  [DKML_COMPILE_VS_DIR = \"$E_VS_DIR\"]" >>"$OPSC"
            echo "  [DKML_COMPILE_VS_VCVARSVER = \"$E_VS_VCVARSVER\"]" >>"$OPSC"
            echo "  [DKML_COMPILE_VS_WINSDKVER = \"$E_VS_WINSDKVER\"]" >>"$OPSC"
            echo "  [DKML_COMPILE_VS_MSVSPREFERENCE = \"$E_VS_MSVSPREFERENCE\"]" >>"$OPSC"
            echo "  [DKML_COMPILE_VS_CMAKEGENERATOR = \"$E_VS_CMAKEGENERATOR\"]" >>"$OPSC"
            echo "  [DKML_HOST_ABI = \"${dkml_host_abi}\"]" >>"$OPSC"
            echo ']' >>"$OPSC"
            cat "$OPSC" >&2 # print
            ;;
        *)
            opamrun option --switch "$do_use_vsstudio_NAME" setenv= # reset
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+='DKML_COMPILE_SPEC = "1"'
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+='DKML_COMPILE_TYPE = "VS"'
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+="DKML_COMPILE_VS_DIR = \"$E_VS_DIR\""
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+="DKML_COMPILE_VS_VCVARSVER = \"$E_VS_VCVARSVER\""
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+="DKML_COMPILE_VS_WINSDKVER = \"$E_VS_WINSDKVER\""
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+="DKML_COMPILE_VS_MSVSPREFERENCE = \"$E_VS_MSVSPREFERENCE\""
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+="DKML_COMPILE_VS_CMAKEGENERATOR = \"$E_VS_CMAKEGENERATOR\""
            opamrun option --switch "$do_use_vsstudio_NAME" setenv+="DKML_HOST_ABI = \"${dkml_host_abi}\""
            opamrun option --switch "$do_use_vsstudio_NAME" setenv # print
            ;;
        esac

        # shellcheck disable=SC2016
        opamrun exec --switch "$do_use_vsstudio_NAME" -- sh -c 'echo $VCToolsRedistDir'

        section_end "use-vsstudio-$do_use_vsstudio_NAME"
        ;;
    esac
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_use_vsstudio dkml
    if [ "${SECONDARY_SWITCH:-}" = "true" ]; then
        do_use_vsstudio two
    fi
fi

# Because dune.X.Y.Z+shim (and any user DKML packages) requires DKML installed (after all, it is just
# a with-dkml.exe shim), we need either dkmlvars-v2.sexp or DKML environment
# variables. Confer: Dkml_runtimelib.Dkml_context.get_dkmlversion
#
# grep matches either:
#   [... [DiskuvOCamlVersion = "1.0.1"] ...]
#   DiskuvOCamlVersion = "1.0.1"
do_setenv() {
    do_setenv_SWITCH=$1
    shift
    section_begin "setenv-$do_setenv_SWITCH" "Set opam option for $do_setenv_SWITCH switch"
    opamrun option --switch "$do_setenv_SWITCH" setenv > ".ci/sd4/setenv.$do_setenv_SWITCH.txt"
    if ! grep -q '\(^|\[\)DiskuvOCamlVarsVersion ' ".ci/sd4/setenv.$do_setenv_SWITCH.txt"; then
        opamrun option --switch "$do_setenv_SWITCH" setenv+='DiskuvOCamlVarsVersion = "2"'
    fi
    if ! grep -q '\(^|\[\)DiskuvOCamlVersion ' ".ci/sd4/setenv.$do_setenv_SWITCH.txt"; then
        opamrun option --switch "$do_setenv_SWITCH" setenv+="DiskuvOCamlVersion = \"$DKML_VERSION\""
    fi
    if [ "$do_setenv_SWITCH" = dkml ] && [ -n "${DKML_HOME:-}" ]; then
      do_setenv_DKMLHOME_ESCAPED="$DKML_HOME"
      do_setenv_USRBIN_ESCAPED="$DKML_HOME/usr/bin"
      do_setenv_BIN_ESCAPED="$DKML_HOME/bin"
      if [ -x /usr/bin/cygpath ]; then
        do_setenv_DKMLHOME_ESCAPED=$(/usr/bin/cygpath -aw "$do_setenv_DKMLHOME_ESCAPED" | sed 's/\\/\\\\/g')
        do_setenv_USRBIN_ESCAPED=$(/usr/bin/cygpath -aw "$do_setenv_USRBIN_ESCAPED" | sed 's/\\/\\\\/g')
        do_setenv_BIN_ESCAPED=$(/usr/bin/cygpath -aw "$do_setenv_BIN_ESCAPED" | sed 's/\\/\\\\/g')
      fi
      if ! grep -q '\(^|\[\)DiskuvOCamlHome ' ".ci/sd4/setenv.$do_setenv_SWITCH.txt"; then
          opamrun option --switch "$do_setenv_SWITCH" setenv+="DiskuvOCamlHome = \"$do_setenv_DKMLHOME_ESCAPED\""
      fi
      if ! grep -q '\(^|\[\)DiskuvOCamlBinaryPaths ' ".ci/sd4/setenv.$do_setenv_SWITCH.txt"; then
          opamrun option --switch "$do_setenv_SWITCH" setenv+="DiskuvOCamlBinaryPaths = \"$do_setenv_USRBIN_ESCAPED;$do_setenv_BIN_ESCAPED\""
      fi
      if ! grep -q '\(^|\[\)DiskuvOCamlDeploymentId ' ".ci/sd4/setenv.$do_setenv_SWITCH.txt"; then
          opamrun option --switch "$do_setenv_SWITCH" setenv+="DiskuvOCamlDeploymentId = \"setup-dkml-switch-$do_setenv_SWITCH\""
      fi
    fi
    case "${dkml_host_abi}" in
    windows_*)
        if ! grep -q '\(^|\[\)DiskuvOCamlMSYS2Dir ' ".ci/sd4/setenv.$do_setenv_SWITCH.txt"; then
            if [ -x /usr/bin/cygpath ]; then
                MSYS2_DIR_NATIVE=$(/usr/bin/cygpath -aw /)
            else
                # If we are already inside MSYS2 then MSYSTEM_PREFIX should be set. But cygpath should be there as well!!
                echo "FATAL: Could not locate MSYS2: there was no cygpath" >&2
                exit 3
            fi
            MSYS2_DIR_NATIVE_ESCAPED=$(printf "%s" "$MSYS2_DIR_NATIVE" | sed 's/\\/\\\\/g')
            opamrun option --switch "$do_setenv_SWITCH" setenv+="DiskuvOCamlMSYS2Dir = \"$MSYS2_DIR_NATIVE_ESCAPED\""
        fi
    esac
    section_end "setenv-$do_setenv_SWITCH"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_setenv dkml
    if [ "${SECONDARY_SWITCH:-}" = "true" ]; then
        do_setenv two
    fi
fi

do_install_compiler() {
    do_install_compiler_NAME=$1
    shift
    section_begin "install-compiler-$do_install_compiler_NAME" "Install OCaml compiler for $do_install_compiler_NAME switch"
    opamrun pin list --switch "$do_install_compiler_NAME"
    # shellcheck disable=SC2086
    opamrun upgrade --switch "$do_install_compiler_NAME" --yes dkml-base-compiler conf-dkml-cross-toolchain ${ocaml_options:-}
    section_end "install-compiler-$do_install_compiler_NAME"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    if ! [ "${PRIMARY_SWITCH_SKIP_INSTALL:-}" = "true" ]; then
        do_install_compiler dkml
    fi
    if [ "${SECONDARY_SWITCH:-}" = "true" ]; then
        do_install_compiler two
    fi
fi

do_summary() {
    do_summary_NAME=$1
    shift
    section_begin "summary-$do_summary_NAME" "Summary: $do_summary_NAME switch"
    opamrun var --switch "$do_summary_NAME"
    opamrun exec --switch "$do_summary_NAME" -- ocamlc -config
    section_end "summary-$do_summary_NAME"
}
if [ "${SKIP_OPAM_MODIFICATIONS:-}" = "false" ]; then
    do_summary dkml
    if [ "${SECONDARY_SWITCH:-}" = "true" ]; then
        do_summary two
    fi
fi

end_of_script

sh .ci/sd4/run-checkout-code.sh PC_PROJECT_DIR "${PC_PROJECT_DIR}"
sh .ci/sd4/run-setup-dkml.sh PC_PROJECT_DIR "${PC_PROJECT_DIR}"

# shellcheck disable=SC2154
echo "
Finished setup.

To continue your testing, run:
  export dkml_host_abi='${dkml_host_abi}'
  export abi_pattern='${abi_pattern}'
  export opam_root='${opam_root}'
  export exe_ext='${exe_ext:-}'

Now you can use 'opamrun' to do opam commands like:

  PATH=\"$PWD/.ci/sd4/opamrun:\$PATH\" opamrun install XYZ.opam
  PATH=\"$PWD/.ci/sd4/opamrun:\$PATH\" opamrun -it exec -- bash
  sh ci/build-test.sh
"