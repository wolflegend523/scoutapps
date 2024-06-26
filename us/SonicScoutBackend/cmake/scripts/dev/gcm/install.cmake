# Recommendation: Place this file in source control.
# Auto-generated by `./dk dksdk.project.new` of DkHelloWorld.

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} "usage: ./dk user.dev.gcm.install

Installs git-credential-manager.

The installation closely follows
https://github.com/git-ecosystem/git-credential-manager/blob/release/docs/install.md

Arguments
=========

HELP
  Print this help message.
")
endfunction()

# https://github.com/git-ecosystem/git-credential-manager/blob/release/docs/install.md

function(run)
    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})
    set(noValues HELP)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    set(gcm_VER 2.0.935)

    if (CMAKE_HOST_APPLE)
        # https://github.com/git-ecosystem/git-credential-manager/blob/release/docs/install.md
        find_program(git-credential-manager-core NAMES git-credential-manager-core)
        if(NOT git-credential-manager-core)
            find_program(brew NAMES brew REQUIRED)
            execute_process(
                    COMMAND ${brew} tap microsoft/git
                    COMMAND_ERROR_IS_FATAL ANY)
            execute_process(
                    COMMAND ${brew} install --cask git-credential-manager-core
                    COMMAND_ERROR_IS_FATAL ANY)
        endif()
    elseif (CMAKE_HOST_LINUX)
        set(archive_extension .deb)
        set(archive_description "Debian Package")
        set(expected_sha256 bf788ae6d6d67b805cbc7f35f818696248b4d4f62175d19bb1a57d8d2148619b)

        # /usr/lib/x86_64-linux-gnu/libicuio.so
        find_library(libicuio NAMES libicuio.so PATHS /lib/x86_64-linux-gnu)
        if (NOT libicuio)
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "Installing libicu: sudo apt-get install -y libicu-dev")
            execute_process(
                    COMMAND sudo apt-get install -y libicu-dev
                    COMMAND_ERROR_IS_FATAL ANY)
        endif ()

        # /usr/lib/x86_64-linux-gnu/libsecret-1.so.0.0.0
        find_library(libsecret NAMES libsecret-1.so PATHS /lib/x86_64-linux-gnu)
        if (NOT libsecret)
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "Installing libsecret: sudo apt-get install -y libsecret-1-0")
            execute_process(
                    COMMAND sudo apt-get install -y libsecret-1-0
                    COMMAND_ERROR_IS_FATAL ANY)
        endif ()

        # dbus-x11
        if (NOT EXISTS /usr/bin/dbus-launch)
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "Installing dbus: sudo apt-get install -y dbus-x11")
            execute_process(
                    COMMAND sudo apt-get install -y dbus-x11
                    COMMAND_ERROR_IS_FATAL ANY)
        endif ()

        # gnome-keyring
        if (NOT EXISTS /usr/bin/gnome-keyring)
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "Installing gnome-keyring: sudo apt-get install -y gnome-keyring")
            execute_process(
                    COMMAND sudo apt-get install -y gnome-keyring
                    COMMAND_ERROR_IS_FATAL ANY)
        endif ()

        # curl
        if (NOT EXISTS /usr/bin/curl)
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "Installing curl: sudo apt-get install -y curl")
            execute_process(
                    COMMAND sudo apt-get install -y curl
                    COMMAND_ERROR_IS_FATAL ANY)
        endif ()

        if (NOT EXISTS /usr/local/bin/git-credential-manager)

            set(skip_download)
            if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/gcm${archive_extension})
                message(CHECK_START "Validating existing Git Credentials Manager ${archive_description}")
                file(SHA256 "${CMAKE_CURRENT_BINARY_DIR}/gcm${archive_extension}" actual_sha256)
                if (expected_sha256 STREQUAL "${actual_sha256}")
                    message(CHECK_PASS "validated")
                    set(skip_download ON)
                else ()
                    message(CHECK_FAIL "not validated. Will download again")
                endif ()
            endif ()
            if (NOT skip_download)
                message(CHECK_START "Downloading Git Credentials Manager ${gcm_VER} ${archive_description}")
                file(DOWNLOAD "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${gcm_VER}/gcm-linux_amd64.${gcm_VER}${archive_extension}"
                        "${CMAKE_CURRENT_BINARY_DIR}/gcm${archive_extension}"
                        SHOW_PROGRESS
                        EXPECTED_HASH SHA256=${expected_sha256})
                message(CHECK_PASS "verified")
            endif ()

            message(CHECK_START "Installing Git Credentials Manager ${archive_description}")
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "Installing: sudo apt-get install -y ${CMAKE_CURRENT_BINARY_DIR}/gcm${archive_extension}")
            execute_process(
                    COMMAND sudo apt-get install -y "${CMAKE_CURRENT_BINARY_DIR}/gcm${archive_extension}"
                    COMMAND_ERROR_IS_FATAL ANY)
            message(CHECK_PASS "installed")
        endif ()

        set(needs_config)
        if (EXISTS $ENV{HOME}/.gitconfig)
            file(STRINGS $ENV{HOME}/.gitconfig gitconfig REGEX "helper = /usr/local/bin/git-credential-manager")
            if (NOT gitconfig)
                set(needs_config ON)
            endif ()
        else ()
            set(needs_config ON)
        endif ()
        if (needs_config)
            execute_process(
                    COMMAND /usr/local/bin/git-credential-manager configure
                    COMMAND_ERROR_IS_FATAL ANY)
        endif ()
    endif ()
endfunction()