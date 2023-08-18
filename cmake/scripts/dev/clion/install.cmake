# Recommendation: Place this file in source control.
# Auto-generated by `./dk dksdk.project.new` of DkHelloWorld.

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} "usage: ./dk user.dev.clion.install

Installs CLion if it hasn't been installed.

Arguments
=========

HELP
  Print this help message.
")
endfunction()

function(get_clion_version outVar)
    set(${outVar} 2022.3.3 PARENT_SCOPE)
endfunction()
function(get_clion_runner outVar)
    get_clion_version(clion_VER)
    cmake_path(APPEND DKSDK_DATA_HOME clion OUTPUT_VARIABLE clion_SUBDIR)
    if (CMAKE_HOST_LINUX)
        set(${outVar} ${clion_SUBDIR}/clion-${clion_VER}/bin/clion.sh PARENT_SCOPE)
    elseif (CMAKE_HOST_WIN32)
        set(${outVar} ${clion_SUBDIR}/clion-${clion_VER}/bin/clion64.exe PARENT_SCOPE)
    endif ()
endfunction()

function(clion_install__install_linux_lib libname pkg)
    if (CMAKE_HOST_LINUX)
        find_library(lib_${pkg} NAMES ${libname} PATHS /lib/x86_64-linux-gnu)
        if (NOT lib_${pkg})
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "Installing ${pkg}: sudo apt-get install -y ${pkg}")
            execute_process(
                    COMMAND sudo apt-get install -y ${pkg})
        endif ()
    endif ()
endfunction()

function(clion_install__install)
    # https://www.jetbrains.com/clion/download/other.html
    if (CMAKE_HOST_LINUX)
        set(archive_description "Linux archive")
        set(archive_extension .tar.gz)
        set(expected_sha256 1b46ff0791bcb38ecb39c5f4a99941f99ed73d4f6d924a2042fdb55afc5fc03d)
    elseif (CMAKE_HOST_WIN32)
        set(archive_description "Windows ZIP archive")
        set(archive_extension .win.zip)
        set(expected_sha256 211d62bd94421edbb97a00694a51e1870bb09c156dce76d4ebcc737440ef776c)
    else ()
        message(FATAL_ERROR "Installing CLion is only supported on Linux")
    endif ()

    # libXtst.so.6
    #   Confer: ldd ~/.local/share/dksdk/clion/clion-2022.3.3/jbr/lib/libawt_xawt.so
    clion_install__install_linux_lib(libXtst.so.6 libxtst6)

    # https://intellij-support.jetbrains.com/hc/en-us/articles/360016421559
    clion_install__install_linux_lib(libnss3.so libnss3)
    clion_install__install_linux_lib(libgbm.so.1 libgbm1)
    clion_install__install_linux_lib(libasound.so.2 libasound2)

    # Quick-exit if we already have a runner
    get_clion_version(clion_VER)
    get_clion_runner(clion_RUNNER)
    if (EXISTS ${clion_RUNNER})
        return()
    endif ()

    set(skip_download)
    if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/clion${archive_extension})
        message(CHECK_START "Validating existing CLion ${archive_description}")
        file(SHA256 "${CMAKE_CURRENT_BINARY_DIR}/clion${archive_extension}" actual_sha256)
        if (expected_sha256 STREQUAL "${actual_sha256}")
            message(CHECK_PASS "validated as ${clion_VER}")
            set(skip_download ON)
        else ()
            message(CHECK_FAIL "not validated. Will download again")
        endif ()
    endif ()
    if (NOT skip_download)
        message(CHECK_START "Downloading CLion ${clion_VER} ${archive_description}")
        file(DOWNLOAD
                "https://download.jetbrains.com/cpp/CLion-${clion_VER}${archive_extension}"
                "${CMAKE_CURRENT_BINARY_DIR}/clion${archive_extension}"
                SHOW_PROGRESS
                EXPECTED_HASH SHA256=${expected_sha256})
        message(CHECK_PASS "verified")
    endif ()

    message(CHECK_START "Extracting CLion ${archive_description}")
    if (archive_extension STREQUAL ".win.zip")
        # Make zip files have the extra clion-2022.3.3 subdirectory for consistency
        # and isolation.
        cmake_path(APPEND DKSDK_DATA_HOME clion clion-${clion_VER} OUTPUT_VARIABLE clion_INSTALL_DIR)
    else ()
        cmake_path(APPEND DKSDK_DATA_HOME clion OUTPUT_VARIABLE clion_INSTALL_DIR)
    endif ()
    file(ARCHIVE_EXTRACT INPUT "${CMAKE_CURRENT_BINARY_DIR}/clion${archive_extension}"
            DESTINATION ${clion_INSTALL_DIR})
    message(CHECK_PASS "installed to: ${clion_INSTALL_DIR}")
endfunction()

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

    clion_install__install()
endfunction()
