SUBDIRS	     = utils replacements tds
DIST_SUBDIRS = utils replacements tds server pool ctlib dblib odbc apps cslib

if INCPOOL
SUBDIRS += server pool
else !INCPOOL
if INCSERVER
SUBDIRS += server
else !INCSERVER
# If building cslib, we need server even if not explicitly enabled
if BUILD_CSLIB
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

# Build cslib (libcs.so) if enabled
if BUILD_CSLIB
SUBDIRS += cslib
endif
