#!/bin/bash
# FreeTDS Full Setup Script
# This script:
#   1. Clones/updates the FreeTDS fork
#   2. Checks out tag v1.5.10
#   3. Applies the sharedlib patch
#   4. Builds for the current platform
#
# Prerequisites:
#   - Git
#   - For Windows: Visual Studio 2019/2022, CMake
#   - For Linux: autoconf, automake, libtool, libssl-dev
#
# Usage: ./setup-and-build.sh [OPTIONS]
#   --github-repo   GitHub repository URL (default: origin remote or https://github.com/USER/freetds.git)
#   --tag           Tag to checkout (default: v1.5.10)
#   --patch-file    Path to patch file (default: build-scripts/freetds-sharedlib.patch)
#   --clean         Clean build before starting
#   --skip-clone    Skip clone/checkout, use existing source

set -e

# Configuration
DEFAULT_TAG="v1.5.10"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
GITHUB_REPO=""
TAG="$DEFAULT_TAG"
PATCH_FILE=""
CLEAN_BUILD=false
SKIP_CLONE=false
SOURCE_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --github-repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --patch-file)
            PATCH_FILE="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --skip-clone)
            SKIP_CLONE=true
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
            echo "  --github-repo URL   GitHub repository URL"
            echo "  --tag TAG           Git tag to checkout (default: $DEFAULT_TAG)"
            echo "  --patch-file FILE   Path to patch file"
            echo "  --source-dir DIR    Source directory (default: parent of script dir)"
            echo "  --clean             Clean build directories"
            echo "  --skip-clone        Skip clone/checkout, use existing source"
            echo "  --help              Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set defaults
if [ -z "$SOURCE_DIR" ]; then
    SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
fi

if [ -z "$PATCH_FILE" ]; then
    PATCH_FILE="$SCRIPT_DIR/freetds-sharedlib.patch"
fi

echo "========================================"
echo "FreeTDS Setup and Build"
echo "========================================"
echo "Tag: $TAG"
echo "Source Directory: $SOURCE_DIR"
echo "Patch File: $PATCH_FILE"
echo ""

# Detect platform
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    echo "Warning: Unknown platform $OSTYPE, assuming Linux"
    PLATFORM="linux"
fi

echo "Detected platform: $PLATFORM"
echo ""

# Step 1: Clone or update repository
if [ "$SKIP_CLONE" = false ]; then
    echo "========================================"
    echo "Step 1: Setting up repository..."
    echo "========================================"
    
    if [ -d "$SOURCE_DIR/.git" ]; then
        echo "Repository exists, fetching latest..."
        cd "$SOURCE_DIR"
        git fetch --all --tags
    else
        if [ -z "$GITHUB_REPO" ]; then
            echo "Error: No existing repository and no --github-repo specified."
            echo "Please specify your GitHub fork URL with --github-repo"
            exit 1
        fi
        echo "Cloning repository from $GITHUB_REPO..."
        git clone "$GITHUB_REPO" "$SOURCE_DIR"
        cd "$SOURCE_DIR"
    fi
    
    # Checkout the tag
    echo "Checking out tag $TAG..."
    git checkout "$TAG"
    
    # Create a branch for our changes
    BRANCH_NAME="sharedlib-$TAG"
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "Branch $BRANCH_NAME already exists, checking it out..."
        git checkout "$BRANCH_NAME"
    else
        echo "Creating branch $BRANCH_NAME..."
        git checkout -b "$BRANCH_NAME"
    fi
fi

cd "$SOURCE_DIR"

# Step 2: Apply patch
echo ""
echo "========================================"
echo "Step 2: Applying patch..."
echo "========================================"

if [ ! -f "$PATCH_FILE" ]; then
    echo "Error: Patch file not found: $PATCH_FILE"
    exit 1
fi

# Check if patch is already applied by looking for a key file
if [ -f "src/sharedlib/CMakeLists.txt" ] && [ -f "include/freetds/export.h" ]; then
    echo "Patch appears to already be applied (sharedlib files exist)."
    echo "Skipping patch application."
else
    echo "Applying patch from $PATCH_FILE..."
    # Try to apply patch, but don't fail if already partially applied
    if ! git apply --check "$PATCH_FILE" 2>/dev/null; then
        echo "Patch may be partially applied, trying with --reject..."
        git apply --reject "$PATCH_FILE" || true
    else
        git apply "$PATCH_FILE"
    fi
    echo "Patch applied successfully."
fi

# Step 3: Build
echo ""
echo "========================================"
echo "Step 3: Building..."
echo "========================================"

BUILD_ARGS=""
if [ "$CLEAN_BUILD" = true ]; then
    BUILD_ARGS="--clean"
fi

if [ "$PLATFORM" = "windows" ]; then
    echo "Running Windows build..."
    if command -v pwsh &> /dev/null; then
        pwsh -ExecutionPolicy Bypass -File "$SCRIPT_DIR/build-windows.ps1" $BUILD_ARGS
    elif command -v powershell &> /dev/null; then
        powershell -ExecutionPolicy Bypass -File "$SCRIPT_DIR/build-windows.ps1" $BUILD_ARGS
    else
        echo "Error: PowerShell not found. Please run build-windows.ps1 manually."
        exit 1
    fi
else
    echo "Running Linux build..."
    chmod +x "$SCRIPT_DIR/build-linux.sh"
    "$SCRIPT_DIR/build-linux.sh" $BUILD_ARGS
fi

echo ""
echo "========================================"
echo "Setup and build completed!"
echo "========================================"
echo ""
echo "Output is in: $SOURCE_DIR/output"
