#!/bin/bash
# FreeTDS Linux Build Script (x64 Release and Debug)
# Prerequisites:
#   - GCC or Clang
#   - autoconf, automake, libtool
#   - OpenSSL development headers (libssl-dev on Debian/Ubuntu, openssl-devel on RHEL/CentOS)
#   - Git
#
# Usage: ./build-linux.sh [--clean] [--release-only] [--debug-only]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$SOURCE_DIR/output"

# Parse arguments
CLEAN_BUILD=false
BUILD_RELEASE=true
BUILD_DEBUG=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --release-only)
            BUILD_DEBUG=false
            shift
            ;;
        --debug-only)
            BUILD_RELEASE=false
            shift
            ;;
        --source-dir)
            SOURCE_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --clean         Clean build directories before building"
            echo "  --release-only  Build only Release configuration"
            echo "  --debug-only    Build only Debug configuration"
            echo "  --source-dir    Specify source directory (default: parent of script dir)"
            echo "  --help          Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

BUILD_DIR_RELEASE="$SOURCE_DIR/build-linux-release"
BUILD_DIR_DEBUG="$SOURCE_DIR/build-linux-debug"

echo "========================================"
echo "FreeTDS Linux Build (x64)"
echo "========================================"
echo "Source Directory: $SOURCE_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is required but not installed."
        echo "Install it with: $2"
        exit 1
    fi
}

check_tool "autoconf" "apt install autoconf (Debian/Ubuntu) or yum install autoconf (RHEL/CentOS)"
check_tool "automake" "apt install automake (Debian/Ubuntu) or yum install automake (RHEL/CentOS)"
check_tool "libtool" "apt install libtool (Debian/Ubuntu) or yum install libtool (RHEL/CentOS)"
check_tool "make" "apt install make (Debian/Ubuntu) or yum install make (RHEL/CentOS)"
check_tool "pkg-config" "apt install pkg-config (Debian/Ubuntu) or yum install pkgconfig (RHEL/CentOS)"

# Check for OpenSSL development headers
if ! pkg-config --exists openssl 2>/dev/null; then
    echo "Warning: OpenSSL development headers not found via pkg-config."
    echo "Install with: apt install libssl-dev (Debian/Ubuntu) or yum install openssl-devel (RHEL/CentOS)"
    echo "Continuing anyway - build will fail if OpenSSL is not available."
fi

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo "Cleaning build directories..."
    rm -rf "$BUILD_DIR_RELEASE" "$BUILD_DIR_DEBUG" "$OUTPUT_DIR"
fi

# Create output directories
mkdir -p "$OUTPUT_DIR/include/freetds"
mkdir -p "$OUTPUT_DIR/lib/x64/Release"
mkdir -p "$OUTPUT_DIR/lib/x64/Debug"

# Change to source directory
cd "$SOURCE_DIR"

# Run autoreconf if needed
if [ ! -f "configure" ] || [ "configure.ac" -nt "configure" ]; then
    echo "Running autoreconf..."
    autoreconf -i -f
fi

# Function to build a configuration
build_config() {
    local config_name="$1"
    local build_dir="$2"
    local debug_flag="$3"
    local output_subdir="$4"
    
    echo ""
    echo "========================================"
    echo "Building $config_name..."
    echo "========================================"
    
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # Configure
    local configure_opts=(
        "--with-openssl"
        "--enable-sharedlib"
    )
    
    if [ "$debug_flag" = "yes" ]; then
        configure_opts+=("--enable-debug")
        export CFLAGS="-g -O0 -DDEBUG"
        export CXXFLAGS="-g -O0 -DDEBUG"
    else
        configure_opts+=("--disable-debug")
        export CFLAGS="-O2 -DNDEBUG"
        export CXXFLAGS="-O2 -DNDEBUG"
    fi
    
    echo "Running configure with options: ${configure_opts[*]}"
    "$SOURCE_DIR/configure" "${configure_opts[@]}"
    
    # Build
    echo "Running make..."
    make -j$(nproc)
    
    # Copy libraries to output
    echo "Copying libraries to output..."
    
    # Copy shared library
    if [ -f "src/sharedlib/.libs/libfreetds.so" ]; then
        cp -P src/sharedlib/.libs/libfreetds.so* "$OUTPUT_DIR/lib/x64/$output_subdir/"
    fi
    
    # Copy static library if exists
    if [ -f "src/sharedlib/.libs/libfreetds.a" ]; then
        cp src/sharedlib/.libs/libfreetds.a "$OUTPUT_DIR/lib/x64/$output_subdir/"
    fi
    
    cd "$SOURCE_DIR"
    
    unset CFLAGS CXXFLAGS
}

# Build Release
if [ "$BUILD_RELEASE" = true ]; then
    build_config "Release" "$BUILD_DIR_RELEASE" "no" "Release"
fi

# Build Debug
if [ "$BUILD_DEBUG" = true ]; then
    build_config "Debug" "$BUILD_DIR_DEBUG" "yes" "Debug"
fi

# Copy headers (use Release build directory for generated headers)
echo ""
echo "========================================"
echo "Copying header files..."
echo "========================================"

GENERATED_HEADERS_DIR="$BUILD_DIR_RELEASE"
if [ ! -d "$GENERATED_HEADERS_DIR" ]; then
    GENERATED_HEADERS_DIR="$BUILD_DIR_DEBUG"
fi

# Copy source headers
HEADERS=(
    "bkpublic.h"
    "cspublic.h"
    "cstypes.h"
    "ctpublic.h"
    "sqldb.h"
    "sqlfront.h"
    "sybdb.h"
    "sybfront.h"
    "syberror.h"
)

for header in "${HEADERS[@]}"; do
    if [ -f "$SOURCE_DIR/include/$header" ]; then
        cp "$SOURCE_DIR/include/$header" "$OUTPUT_DIR/include/"
    fi
done

# Copy freetds subdirectory headers
FREETDS_HEADERS=(
    "export.h"
    "server.h"
    "tds.h"
    "proto.h"
    "bytes.h"
    "configs.h"
    "convert.h"
    "data.h"
    "encodings.h"
    "iconv.h"
    "macros.h"
    "stream.h"
    "tls.h"
    "bool.h"
    "alloca.h"
    "pushvis.h"
    "popvis.h"
    "thread.h"
    "time.h"
    "checks.h"
    "unused.h"
)

for header in "${FREETDS_HEADERS[@]}"; do
    if [ -f "$SOURCE_DIR/include/freetds/$header" ]; then
        cp "$SOURCE_DIR/include/freetds/$header" "$OUTPUT_DIR/include/freetds/"
    fi
done

# Copy generated headers
if [ -f "$GENERATED_HEADERS_DIR/include/config.h" ]; then
    cp "$GENERATED_HEADERS_DIR/include/config.h" "$OUTPUT_DIR/include/"
fi

if [ -f "$GENERATED_HEADERS_DIR/include/tds_sysdep_public.h" ]; then
    cp "$GENERATED_HEADERS_DIR/include/tds_sysdep_public.h" "$OUTPUT_DIR/include/"
fi

if [ -f "$GENERATED_HEADERS_DIR/include/freetds/version.h" ]; then
    cp "$GENERATED_HEADERS_DIR/include/freetds/version.h" "$OUTPUT_DIR/include/freetds/"
fi

if [ -f "$GENERATED_HEADERS_DIR/include/freetds/sysdep_types.h" ]; then
    cp "$GENERATED_HEADERS_DIR/include/freetds/sysdep_types.h" "$OUTPUT_DIR/include/freetds/"
fi

# Copy utils headers
if [ -d "$SOURCE_DIR/include/freetds/utils" ]; then
    mkdir -p "$OUTPUT_DIR/include/freetds/utils"
    cp "$SOURCE_DIR/include/freetds/utils/"*.h "$OUTPUT_DIR/include/freetds/utils/" 2>/dev/null || true
fi

# Copy replacements headers
if [ -d "$SOURCE_DIR/include/freetds/replacements" ]; then
    mkdir -p "$OUTPUT_DIR/include/freetds/replacements"
    cp "$SOURCE_DIR/include/freetds/replacements/"*.h "$OUTPUT_DIR/include/freetds/replacements/" 2>/dev/null || true
fi

echo ""
echo "========================================"
echo "Build completed successfully!"
echo "========================================"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Structure:"
echo "  output/"
echo "    include/           - Header files"
echo "    include/freetds/   - FreeTDS-specific headers"
echo "    lib/x64/Release/   - Release shared library (.so)"
echo "    lib/x64/Debug/     - Debug shared library (.so)"
echo ""
echo "To use the library:"
echo "  export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$OUTPUT_DIR/lib/x64/Release"
