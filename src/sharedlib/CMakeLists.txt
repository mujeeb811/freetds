# CMakeLists.txt for FreeTDS shared library
# This creates libfreetds.so/.dll combining tds, tdssrv, replacements, and tdsutils

# Create a shared library that combines all the static libraries
add_library(freetds SHARED
    freetds_sharedlib.c
    # Include all source files from the static libraries directly
    $<TARGET_OBJECTS:tds_obj>
    $<TARGET_OBJECTS:tdssrv_obj>
    $<TARGET_OBJECTS:replacements_obj>
    $<TARGET_OBJECTS:tdsutils_obj>
)

# Link runtime dependencies
target_link_libraries(freetds
    PRIVATE
        ${lib_NETWORK}
        ${lib_BASE}
)

# Include directories
target_include_directories(freetds
    PUBLIC
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_BINARY_DIR}/include
)

# Set the output name and properties
set_target_properties(freetds PROPERTIES
    OUTPUT_NAME "freetds"
    VERSION "${VERSION}"
    SOVERSION "${MAJOR}"
)

# Platform-specific symbol export settings
if(WIN32)
    # On Windows, export all symbols automatically
    set_target_properties(freetds PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
else()
    # On Linux/Unix with GCC, hide symbols by default and use TDS_EXPORT for public API
    # This requires -fvisibility=hidden to work properly
    set_target_properties(freetds PROPERTIES
        C_VISIBILITY_PRESET hidden
        CXX_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN ON
    )
    
    # For older CMake versions or explicit control, add the flag directly
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
        target_compile_options(freetds PRIVATE -fvisibility=hidden)
    endif()
endif()

# Install the shared library
install(TARGETS freetds
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
