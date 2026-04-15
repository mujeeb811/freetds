#!/bin/bash
# Build FreeTDS with OpenSSL 3 using Docker (RHEL8 base)
#
# Usage: ./build-docker-rhel8.sh [--no-cache] [--interactive] [--platform <platform>]
#
# This script builds FreeTDS in a RHEL8 container with OpenSSL 3
# and extracts the built libraries to ./output/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$SOURCE_DIR/output/linux-rhel8"

DOCKERFILE="$SCRIPT_DIR/Dockerfile.rhel8-openssl3"
IMAGE_NAME="freetds-rhel8-openssl3"

# Default values
NO_CACHE=""
PLATFORM=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --interactive|-i)
            INTERACTIVE=true
            shift
            ;;
        --platform)
            PLATFORM="--platform $2"
            shift 2
            ;;
        --amd64|--x86_64)
            PLATFORM="--platform linux/amd64"
            shift
            ;;
        --arm64|--aarch64)
            PLATFORM="--platform linux/arm64"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-cache     Build Docker image without cache"
            echo "  --interactive  Run container interactively instead of extracting artifacts"
            echo "  --platform     Specify the target platform (e.g., linux/amd64, linux/arm64)"
            echo "  --help         Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "FreeTDS RHEL8 + OpenSSL 3 Docker Build"
echo "========================================"
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required but not installed."
    exit 1
fi

# Build Docker image
echo "Building Docker image: $IMAGE_NAME"
echo ""
docker build $PLATFORM $NO_CACHE -f "$DOCKERFILE" -t "$IMAGE_NAME" "$SOURCE_DIR"

if [ "$INTERACTIVE" = true ]; then
    echo ""
    echo "Starting interactive container..."
    docker run --rm -it "$IMAGE_NAME" /bin/bash
else
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Run container and extract artifacts
    echo ""
    echo "Extracting build artifacts to: $OUTPUT_DIR"
    docker run --rm -v "$OUTPUT_DIR:/output" "$IMAGE_NAME"
    
    echo ""
    echo "========================================"
    echo "Build completed successfully!"
    echo "========================================"
    echo ""
    echo "Output directory: $OUTPUT_DIR"
    echo ""
    echo "Contents:"
    ls -la "$OUTPUT_DIR/lib/" 2>/dev/null || echo "  (no lib directory)"
    echo ""
    
    # Verify OpenSSL 3 linkage (if ldd available and running on Linux)
    if command -v ldd &> /dev/null && [ -f "$OUTPUT_DIR/lib/libfreetds.so" ]; then
        echo "Library dependencies:"
        ldd "$OUTPUT_DIR/lib/libfreetds.so" 2>/dev/null | grep -E "(ssl|crypto)" || echo "  (cannot check dependencies on this platform)"
    fi
fi
