# Makefile.am for FreeTDS cslib (Client Server Library)
# This creates libcs.so from the static libraries:
# libtds, libtdssrv, libreplacements, and libtdsutils

AM_CPPFLAGS = -I$(top_srcdir)/include

# On GCC, hide symbols by default and use TDS_EXPORT for public API
# This matches the CMake build behavior
AM_CFLAGS = @CSLIB_VISIBILITY_CFLAGS@

# Build a shared library
lib_LTLIBRARIES = libcs.la

# The shared library links all the static libraries together
# We use a dummy source file as libtool requires at least one source
libcs_la_SOURCES = freetds_cslib.c

# Link all the component libraries
# Important: Only link the top-level convenience libraries directly.
# Do NOT list libraries that are already linked by other libraries here,
# as that causes multiple definition errors.
# Dependency chain:
#   libtds.la - standalone
#   libtdsutils.la - standalone  
#   libreplacements.la -> libtdsutils.la
#   libtdssrv.la -> libtds.la, libreplacements.la
# So we only need libtdssrv.la (which pulls in everything)
libcs_la_LIBADD = \
	../server/libtdssrv.la \
	$(NETWORK_LIBS) \
	$(LTLIBICONV) \
	$(FREETDS_LIBGCC) \
	$(PTHREAD_LIBS)

# Version info: current:revision:age
# See: https://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
# -no-undefined is required for Windows/MinGW builds
libcs_la_LDFLAGS = -version-info 0:0:0 -no-undefined $(FREETDS_SYMBOLIC)

EXTRA_DIST = CMakeLists.txt
