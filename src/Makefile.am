SUBDIRS	     = utils replacements tds
DIST_SUBDIRS = utils replacements tds server pool ctlib dblib odbc apps sharedlib

if INCPOOL
SUBDIRS += server pool
else !INCPOOL
if INCSERVER
SUBDIRS += server
else !INCSERVER
# If building shared library, we need server even if not explicitly enabled
if BUILD_SHAREDLIB
SUBDIRS += server
endif
endif
endif

SUBDIRS	+= ctlib dblib

if ODBC
SUBDIRS	+= odbc
endif

if INCAPPS
SUBDIRS += apps
endif

# Build shared library (libfreetds.so) if enabled
if BUILD_SHAREDLIB
SUBDIRS += sharedlib
endif
