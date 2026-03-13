# Makefile.am for FreeTDS shared library
# This creates libfreetds.so from the static libraries:
# libtds, libtdssrv, libreplacements, and libtdsutils

AM_CPPFLAGS = -I$(top_srcdir)/include

# On GCC, hide symbols by default and use TDS_EXPORT for public API
# This matches the CMake build behavior
# Note: $ac_compiler_gnu is set by configure.ac
AM_CFLAGS = @SHAREDLIB_VISIBILITY_CFLAGS@

# Build a shared library
lib_LTLIBRARIES = libfreetds.la

# The shared library links all the static libraries together
# We use a dummy source file as libtool requires at least one source
libfreetds_la_SOURCES = freetds_sharedlib.c

# Link all the component libraries
# Note: Order matters - dependencies should come after dependents
libfreetds_la_LIBADD = \
	../tds/libtds.la \
	../server/libtdssrv.la \
	../replacements/libreplacements.la \
	../utils/libtdsutils.la \
	$(NETWORK_LIBS) \
	$(LTLIBICONV) \
	$(FREETDS_LIBGCC) \
	$(PTHREAD_LIBS)

# Version info: current:revision:age
# See: https://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
# -no-undefined is required for Windows/MinGW builds
libfreetds_la_LDFLAGS = -version-info 0:0:0 -no-undefined $(FREETDS_SYMBOLIC)

EXTRA_DIST = CMakeLists.txt
