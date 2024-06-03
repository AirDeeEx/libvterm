include(CMakeDependentOption)

cmake_minimum_required(VERSION 3.10)
project(libvterm)

option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)
option(LIBVTERM_BUILD_BIN "Build standalone programs" OFF)
option(LIBVTERM_STATIC_BIN "Link standalone programs statically" OFF)
# cmake_dependent_option(LIBVTERM_LINK_BIN_STATIC "Link standalone programs statically opt" OFF "BUILD_SHARED_LIBS" OFF)

set(CMAKE_C_STANDARD 99)

find_package(Perl REQUIRED)

# Vterm lib

set(LIBVTERM_TARGET "vterm")

set(LIBVTERM_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/src/encoding.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/keyboard.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/mouse.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/parser.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/pen.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/screen.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/state.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/unicode.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/vterm.c"
)

set(LIBVTERM_TBL2INC "${CMAKE_CURRENT_SOURCE_DIR}/tbl2inc_c.pl")

set(LIBVTERM_ENC_DEC_SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/encoding/DECdrawing.tbl")
set(LIBVTERM_ENC_DEC_OUT "${CMAKE_CURRENT_SOURCE_DIR}/src/encoding/DECdrawing.inc")

set(LIBVTERM_ENC_UK_SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/encoding/uk.tbl")
set(LIBVTERM_ENC_UK_OUT "${CMAKE_CURRENT_SOURCE_DIR}/src/encoding/uk.inc")

add_library(${LIBVTERM_TARGET} ${LIBVTERM_SRC})
target_compile_options(${LIBVTERM_TARGET} PRIVATE -Wall -Wpedantic -Werror)
target_include_directories(${LIBVTERM_TARGET} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src/")
target_include_directories(${LIBVTERM_TARGET} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include/")

add_custom_command(OUTPUT "${LIBVTERM_ENC_DEC_OUT}"
    COMMAND ${PERL_EXECUTABLE} -CSD ${LIBVTERM_TBL2INC} "${LIBVTERM_ENC_DEC_SRC}" > "${LIBVTERM_ENC_DEC_OUT}"
    )

add_custom_command(OUTPUT "${LIBVTERM_ENC_UK_OUT}"
    COMMAND ${PERL_EXECUTABLE} -CSD ${LIBVTERM_TBL2INC} "${LIBVTERM_ENC_UK_SRC}" > "${LIBVTERM_ENC_UK_OUT}"
    )

add_custom_target(libvterm_gen_encoding DEPENDS "${LIBVTERM_ENC_DEC_OUT}" "${LIBVTERM_ENC_UK_OUT}")


add_dependencies(${LIBVTERM_TARGET} libvterm_gen_encoding)
target_link_libraries(${LIBVTERM_TARGET})


# Standalone programs

set(LIBVTERM_BIN_UNTERM_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/bin/unterm.c"
    )

set(LIBVTERM_BIN_VTERM_CTRL_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/bin/vterm-ctrl.c"
    )

set(LIBVTERM_BIN_VTERM_DUMP_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/bin/vterm-ctrl.c"
    )


add_executable(unterm ${LIBVTERM_BIN_UNTERM_SRC})
add_executable(vterm-ctrl ${LIBVTERM_BIN_VTERM_CTRL_SRC})
add_executable(vterm-dump ${LIBVTERM_BIN_VTERM_DUMP_SRC})

if(NOT LIBVTERM_BUILD_BIN)
    set_target_properties(unterm vterm-ctrl vterm-dump PROPERTIES EXCLUDE_FROM_ALL 1 EXCLUDE_FROM_DEFAULT_BUILD 1)
endif()


if(LIBVTERM_STATIC_BIN)
    if(NOT BUILD_SHARED_LIBS)
        set_target_properties(unterm vterm-ctrl vterm-dump PROPERTIES
            LINK_SEARCH_START_STATIC ON
            LINK_SEARCH_END_STATIC ON
            )

        target_link_options(unterm PRIVATE -static)
        target_link_options(vterm-ctrl PRIVATE -static)
        target_link_options(vterm-dump PRIVATE -static)
    else()
        message(WARNING "Ignoring LIBVTERM_STATIC_BIN due BUILD_SHARED_LIBS=ON")
    endif()
endif()

target_link_libraries(unterm ${LIBVTERM_TARGET})
target_link_libraries(vterm-ctrl ${LIBVTERM_TARGET})
target_link_libraries(vterm-dump ${LIBVTERM_TARGET})