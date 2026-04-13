set(TDSSRV_SOURCES
	query.c
	server.c
	login.c
)

# Object library for use by shared library
add_library(tdssrv_obj OBJECT ${TDSSRV_SOURCES})
target_include_directories(tdssrv_obj PUBLIC "${CMAKE_SOURCE_DIR}/include" "${CMAKE_BINARY_DIR}/include")
set_target_properties(tdssrv_obj PROPERTIES POSITION_INDEPENDENT_CODE ON)

add_library(tdssrv STATIC ${TDSSRV_SOURCES})
if (NOT WIN32)
	set_target_properties(tdssrv PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()

INSTALL(TARGETS tdssrv
	PUBLIC_HEADER DESTINATION include
		RUNTIME DESTINATION bin
		LIBRARY DESTINATION lib
		ARCHIVE DESTINATION lib
	)
