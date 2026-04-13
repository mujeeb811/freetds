add_subdirectory(unittests)

if(WIN32)
	set(add_SRCS md5.c)
else(WIN32)
	set(add_SRCS md4.c md5.c des.c hmac_md5.c)
endif(WIN32)

set(TDSUTILS_SOURCES
	dlist.c
	getpassarg.c
	sleep.c
	tds_cond.c
	win_mutex.c
	threadsafe.c
	bjoern-utf8.c
	tdsstring.c
	strndup.c
	net.c
	smp.c
	path.c
	${add_SRCS}
)

# Object library for use by shared library
add_library(tdsutils_obj OBJECT ${TDSUTILS_SOURCES})
target_include_directories(tdsutils_obj PUBLIC "${CMAKE_SOURCE_DIR}/include" "${CMAKE_BINARY_DIR}/include")
set_target_properties(tdsutils_obj PROPERTIES POSITION_INDEPENDENT_CODE ON)

add_library(tdsutils STATIC ${TDSUTILS_SOURCES})
if (NOT WIN32)
	set_target_properties(tdsutils PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()

if(WIN32)
INSTALL(TARGETS tdsutils
	PUBLIC_HEADER DESTINATION include
		RUNTIME DESTINATION bin
		LIBRARY DESTINATION lib
		ARCHIVE DESTINATION lib
	)
endif(WIN32)
