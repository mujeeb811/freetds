# FreeTDS cslib (Client Server Library) Build Scripts

This directory contains scripts to build FreeTDS cslib (libcs) as a shared library (cs.dll on Windows, libcs.so on Linux) with OpenSSL support.

## Quick Start

### Prerequisites

**Windows:**
- Visual Studio 2019 or 2022 with C++ workload
- CMake 3.5+ (included with Visual Studio)
- Git
- OpenSSL for Windows (optional, auto-detected from vcpkg or system paths)

**Linux:**
- GCC or Clang
- autoconf, automake, libtool
- OpenSSL development headers
- Git

Install on Debian/Ubuntu:
```bash
sudo apt install build-essential autoconf automake libtool libssl-dev git
```

Install on RHEL/CentOS:
```bash
sudo yum install gcc autoconf automake libtool openssl-devel git
```

## Usage

### Full Setup (Clone, Patch, Build)

```bash
# From any directory
./setup-and-build.sh --github-repo https://github.com/YOUR_USERNAME/freetds.git --tag v1.5.10

# Or if you already have the repo cloned
./setup-and-build.sh --skip-clone --source-dir /path/to/freetds
```

### Windows Only (PowerShell)

From Developer Command Prompt or PowerShell:

```powershell
# Basic build
.\build-windows.ps1

# With specific Visual Studio version
.\build-windows.ps1 -VSVersion "2019"

# With custom OpenSSL path
.\build-windows.ps1 -OpenSSLPath "C:\OpenSSL-Win64"

# Clean build
.\build-windows.ps1 -CleanBuild
```

### Linux Only (Bash)

```bash
# Basic build
./build-linux.sh

# Clean build
./build-linux.sh --clean

# Release only
./build-linux.sh --release-only

# Debug only
./build-linux.sh --debug-only
```

## Output Structure

After building, the output directory will contain:

```
output/
??? include/                    # Header files
?   ??? sybdb.h
?   ??? ctpublic.h
?   ??? config.h               # Generated
?   ??? tds_sysdep_public.h    # Generated
?   ??? freetds/
?       ??? export.h
?       ??? server.h
?       ??? tds.h
?       ??? version.h          # Generated
?       ??? sysdep_types.h     # Generated
?       ??? ...
??? lib/
?   ??? x64/
?       ??? Release/
?       ?   ??? cs.lib          # Windows import library
?       ?   ??? libcs.so        # Linux shared library
?       ??? Debug/
?           ??? cs.lib          # Windows import library
?           ??? libcs.so        # Linux shared library
??? bin/                        # Windows only
    ??? x64/
        ??? Release/
        ?   ??? cs.dll
        ?   ??? cs.pdb
        ??? Debug/
            ??? cs.dll
            ??? cs.pdb
            ??? cs.ilk
```

## Applying Changes Manually

Due to the complexity of the changes, especially the complete rewrite of `src/server/query.c`,
applying changes involves two steps:

### Step 1: Apply the basic patch

```bash
cd /path/to/freetds
git checkout v1.5.10
git checkout -b cslib-v1.5.10
git apply /path/to/build-scripts/freetds-cslib.patch
```

### Step 2: Copy modified/new files

The following files need to be copied from this repository:

**New files (create these):**
- `include/freetds/export.h`
- `src/cslib/CMakeLists.txt`
- `src/cslib/Makefile.am`
- `src/cslib/freetds_cslib.c`

**Modified files (replace with these):**
- `include/freetds/server.h` - TDS_EXPORT decorations and new function declarations
- `include/freetds/tds.h` - TDS_EXPORT decorations
- `include/freetds/utils/string.h` - TDS_EXPORT on tds_dstr_copy
- `src/server/query.c` - Completely rewritten with binary-safe query handling

You can use the `generate-patch.py` script to regenerate the basic patch:
```bash
python build-scripts/generate-patch.py
```

## What the Changes Do

1. **CMake Support for Shared Library (`BUILD_SHARED_LIB` option)**
   - Object libraries for all components (`tds_obj`, `tdssrv_obj`, etc.)
   - Shared library target combining all objects
   - Automatic symbol export on Windows (`WINDOWS_EXPORT_ALL_SYMBOLS`)

2. **Autotools Support (`--enable-cslib` option)**
   - `src/cslib/Makefile.am` for libtool-based shared library (produces `libcs.so`)
   - `CSLIB_VISIBILITY_CFLAGS` for GCC visibility control
   - Updated `configure.ac` and `src/Makefile.am`

3. **Symbol Export Header (`include/freetds/export.h`)**
   - `TDS_EXPORT` macro for public API functions
   - GCC visibility attributes for Linux
   - No-op on Windows (uses `WINDOWS_EXPORT_ALL_SYMBOLS`)

4. **Extended Query API (`src/server/query.c`)**
   - `tds_get_generic_query_ex()` - Extended query function with binary-safe mode
   - `tds_get_generic_query_len()` - Get length of last query
   - `tds_lastpacket_bin()` - Proper EOM flag checking for binary data
   - `tds_get_query_head()` - TDS7.2+ header parsing
   - `tds_free_query()` - Memory cleanup function

## Configuration Options

### CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `BUILD_SHARED_LIB` | OFF | Build combined shared library (libcs.so / cs.dll) |
| `WITH_OPENSSL` | ON | Enable OpenSSL support |
| `ENABLE_ODBC_WIDE` | ON | Enable ODBC wide character support |
| `ENABLE_ODBC_MARS` | ON | Enable MARS support |

### Autotools Options

| Option | Description |
|--------|-------------|
| `--enable-cslib` | Build combined shared library (libcs.so) |
| `--with-openssl` | Enable OpenSSL support |
| `--enable-debug` | Enable debug build |

## Troubleshooting

### Windows: CMake can't find OpenSSL

Install OpenSSL and set the path:
```powershell
.\build-windows.ps1 -OpenSSLPath "C:\Program Files\OpenSSL-Win64"
```

Or install via vcpkg:
```powershell
vcpkg install openssl:x64-windows
```

### Linux: configure fails with "OpenSSL not found"

Install OpenSSL development headers:
```bash
# Debian/Ubuntu
sudo apt install libssl-dev

# RHEL/CentOS
sudo yum install openssl-devel
```

### Windows: MSBuild not found

Run from Visual Studio Developer Command Prompt, or specify VS version:
```powershell
.\build-windows.ps1 -VSVersion "2022"
```

### Linux: autoreconf fails

Install required tools:
```bash
sudo apt install autoconf automake libtool
```

## License

FreeTDS is licensed under the GNU LGPL. See the FreeTDS documentation for details.

Note: OpenSSL has a different license that may have compatibility considerations with LGPL. See the FreeTDS User Guide for details.
