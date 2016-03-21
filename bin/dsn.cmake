function(ms_add_project PROJ_LANG PROJ_TYPE PROJ_NAME PROJ_SRC PROJ_INC_PATH PROJ_LIBS PROJ_LIB_PATH PROJ_BINPLACES DO_INSTALL)
    if(DEFINED DSN_DEBUG_CMAKE)
        message(STATUS "PROJ_LANG = ${PROJ_LANG}")
        message(STATUS "PROJ_TYPE = ${PROJ_TYPE}")
        message(STATUS "PROJ_NAME = ${PROJ_NAME}")
        message(STATUS "PROJ_SRC = ${PROJ_SRC}")
        message(STATUS "PROJ_INC_PATH = ${PROJ_INC_PATH}")
        message(STATUS "PROJ_LIBS = ${PROJ_LIBS}")
        message(STATUS "PROJ_LIB_PATH = ${PROJ_LIB_PATH}")
        message(STATUS "PROJ_BINPLACES = ${PROJ_BINPLACES}")
        message(STATUS "DO_INSTALL = ${DO_INSTALL}")
    endif() 
    
    if(PROJ_LANG STREQUAL "")
        message(FATAL_ERROR "Invalid project language.")
    endif()

    if(NOT((PROJ_TYPE STREQUAL "STATIC") OR (PROJ_TYPE STREQUAL "SHARED") OR (PROJ_TYPE STREQUAL "EXECUTABLE")))
        #"MODULE" is not used yet
        message(FATAL_ERROR "Invalid project type.")
    endif()
    
    if(PROJ_NAME STREQUAL "")
        message(FATAL_ERROR "Invalid project name.")
    endif()

    if(PROJ_SRC STREQUAL "")
        message(FATAL_ERROR "No source files.")
    endif()

    set(INSTALL_DIR "lib")
    if(PROJ_TYPE STREQUAL "EXECUTABLE")
        set(INSTALL_DIR "bin/${PROJ_NAME}")
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJ_NAME}")
        set(OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
        if(NOT WIN32)
            execute_process(COMMAND sh -c "echo ${PROJ_NAME} ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_BINARY_DIR}/${INSTALL_DIR} ' ' >> ${CMAKE_SOURCE_DIR}/.matchfile")
        endif()
    elseif(PROJ_TYPE STREQUAL "STATIC")
        set(OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
        if(NOT WIN32)
            execute_process(COMMAND sh -c "echo ${PROJ_NAME} ${CMAKE_CURRENT_SOURCE_DIR} ${OUTPUT_DIRECTORY} ' ' >> ${CMAKE_SOURCE_DIR}/.matchfile")
        endif()
    elseif(PROJ_TYPE STREQUAL "SHARED")
        set(OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
        if(NOT WIN32)
            execute_process(COMMAND sh -c "echo ${PROJ_NAME} ${CMAKE_CURRENT_SOURCE_DIR} ${OUTPUT_DIRECTORY} ' ' >> ${CMAKE_SOURCE_DIR}/.matchfile")
        endif()
    endif()

    if(DEFINED DSN_DEBUG_CMAKE)
        message(STATUS "OUTPUT_DIRECTORY = ${OUTPUT_DIRECTORY}")
    endif()

    if(PROJ_LANG STREQUAL "CXX")
        if(NOT (PROJ_INC_PATH STREQUAL ""))
            include_directories(${PROJ_INC_PATH})
        endif()
        if(NOT (PROJ_LIB_PATH STREQUAL ""))
            link_directories(${PROJ_LIB_PATH})
        endif()
          
        if(PROJ_TYPE STREQUAL "STATIC")
            if(MSVC)
                add_definitions(-D_LIB)
            endif()
            add_library(${PROJ_NAME} ${PROJ_TYPE} ${PROJ_SRC})
        elseif(PROJ_TYPE STREQUAL "SHARED")
            add_library(${PROJ_NAME} ${PROJ_TYPE} ${PROJ_SRC})
        elseif(PROJ_TYPE STREQUAL "EXECUTABLE")
            if(MSVC)
                add_definitions(-D_CONSOLE)
            endif()
            add_executable(${PROJ_NAME} ${PROJ_SRC})
        endif()

        if((PROJ_TYPE STREQUAL "SHARED") OR (PROJ_TYPE STREQUAL "EXECUTABLE"))
            if(PROJ_TYPE STREQUAL "SHARED")
                set(LINK_MODE PRIVATE)
            else()
                set(LINK_MODE PUBLIC)
            endif()
            target_link_libraries(${PROJ_NAME} "${LINK_MODE}" ${PROJ_LIBS})
        endif()
        
        if(DO_INSTALL)
            install(TARGETS ${PROJ_NAME} DESTINATION "${INSTALL_DIR}")
            #if (WIN32)
            #    install(FILES "${PROJ_NAME}.pdb" DESTINATION "${INSTALL_DIR}")
            #endif()
        endif()
    endif()
    
    if(PROJ_LANG STREQUAL "CS")
        #Check msbuild
        if(MSVC)
            set(MY_CSC "msbuild.exe")
        else()
            set(MY_CSC "xbuild")
        endif()
        get_filename_component(MY_CSC "${MY_CSC}" PROGRAM)
        if(NOT EXISTS "${MY_CSC}")
            if(MSVC)
                message(FATAL_ERROR "Cannot find msbuild.exe. Please install Visual Studio and run cmake within Visual Studio build command console.")
            else()
                message(FATAL_ERROR "Cannot find xbuild. Please install mono and xbuild.")
            endif()
        endif()

        set(MY_PROJ_SRC "${PROJ_SRC}")
        set(MY_OUTPUT_DIRECTORY "${OUTPUT_DIRECTORY}")
        set(MY_CURRENT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
        if(MSVC)
            file(TO_NATIVE_PATH "${MY_PROJ_SRC}" MY_PROJ_SRC)
            file(TO_NATIVE_PATH "${MY_OUTPUT_DIRECTORY}" MY_OUTPUT_DIRECTORY)
            file(TO_NATIVE_PATH "${MY_CURRENT_SOURCE_DIR}" MY_CURRENT_SOURCE_DIR)
        endif()
        configure_file("${PROJ_NAME}.csproj.template" "${PROJ_NAME}.csproj")
        include_external_msproject(
            "${PROJ_NAME}"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJ_NAME}.csproj"
            TYPE FAE04EC0-301F-11D3-BF4B-00C04F79EFBC
            )
        if(DSN_BUILD_RUNTIME)
            set(DSN_CORE_DLL_FILES "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/")
        else()
            set(DSN_CORE_DLL_FILES "${DSN_ROOT}/lib/")
        endif()
        if (NOT MSVC)
            set(DSN_CORE_DLL_FILES "${DSN_CORE_DLL_FILES}lib")
        endif()
        set(DSN_CORE_DLL_FILES "${DSN_CORE_DLL_FILES}dsn.core.*")
        file(GLOB DSN_CORE_DLL_FILES "${DSN_CORE_DLL_FILES}")
        execute_process(
            COMMAND ${MY_CSC} "${CMAKE_CURRENT_BINARY_DIR}/${PROJ_NAME}.csproj"
            )
        foreach(CORE_FILE ${DSN_CORE_DLL_FILES})
            execute_process(COMMAND ${CMAKE_COMMAND} -E copy ${CORE_FILE} "${OUTPUT_DIRECTORY}/")
        endforeach()
    endif()
               
    if(PROJ_LANG STREQUAL "JAVA")
        add_jar(${PROJ_NAME}
            SOURCES ${PROJ_SRC}
            INCLUDE_JARS ${PROJ_LIBS}
            OUTPUT_DIR ${OUTPUT_DIRECTORY}
        )
    endif()

    if((PROJ_TYPE STREQUAL "EXECUTABLE") AND (NOT (PROJ_BINPLACES STREQUAL "")))
        foreach(BF ${PROJ_BINPLACES})
            get_filename_component(BF "${BF}" ABSOLUTE)
            add_custom_command(
                TARGET ${PROJ_NAME}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy ${BF} "${OUTPUT_DIRECTORY}/"
                )
            if(DO_INSTALL)
                install(FILES ${BF} DESTINATION "${INSTALL_DIR}")
            endif()
        endforeach()
    endif()
endfunction(ms_add_project)

macro(ms_add_compiler_flags LANGUAGES SUFFIXES FLAGS)
    foreach(LANG ${LANGUAGES})
        foreach(SUFFIX ${SUFFIXES})
            if(SUFFIX STREQUAL "<EMPTY>")
                set(SUFFIX "")
            else()
                string(TOUPPER ${SUFFIX} SUFFIX)
                set(SUFFIX "_${SUFFIX}")
            endif()
            set(FLAG_VAR "CMAKE_${LANG}_FLAGS${SUFFIX}")
            set(${FLAG_VAR} "${${FLAG_VAR}} ${FLAGS}" PARENT_SCOPE)
            message(STATUS ${FLAG_VAR} ":" ${${FLAG_VAR}})
        endforeach()
    endforeach()
endmacro(ms_add_compiler_flags)

macro(ms_link_static_runtime FLAG_VAR)
    if(MSVC)
        if(${FLAG_VAR} MATCHES "/MD")
            string(REPLACE "/MD"  "/MT" "${FLAG_VAR}" "${${FLAG_VAR}}")
            #Save persistently
            set(${FLAG_VAR} ${${FLAG_VAR}} CACHE STRING "" FORCE)
        endif()
    endif()
endmacro(ms_link_static_runtime)

macro(ms_replace_compiler_flags REPLACE_OPTION)
    set(SUFFIXES "")
    if((NOT DEFINED CMAKE_CONFIGURATION_TYPES) OR (CMAKE_CONFIGURATION_TYPES STREQUAL ""))
        #set(SUFFIXES "_DEBUG" "_RELEASE" "_MINSIZEREL" "_RELWITHDEBINFO")
        if((DEFINED CMAKE_BUILD_TYPE) AND (NOT (CMAKE_BUILD_TYPE STREQUAL "")))
            string(TOUPPER ${CMAKE_BUILD_TYPE} SUFFIXES)
            set(SUFFIXES "_${SUFFIXES}")
        endif()
    else()
        foreach(SUFFIX ${CMAKE_CONFIGURATION_TYPES})
            string(TOUPPER ${SUFFIX} SUFFIX)
            set(SUFFIXES ${SUFFIXES} "_${SUFFIX}")
        endforeach()
    endif()

    foreach(SUFFIX "" ${SUFFIXES})
        foreach(LANG C CXX)
            set(FLAG_VAR "CMAKE_${LANG}_FLAGS${SUFFIX}")
            if(${REPLACE_OPTION} STREQUAL "STATIC_LINK")
                ms_link_static_runtime(${FLAG_VAR})
            endif()
        endforeach()
        #message(STATUS ${FLAG_VAR} ":" ${${FLAG_VAR}})
    endforeach()
endmacro(ms_replace_compiler_flags)

function(ms_check_cxx11_support)
    if(UNIX)
        include(CheckCXXCompilerFlag)        
        CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
    else()
        if(MSVC_VERSION LESS 1700)
            set(COMPILER_SUPPORTS_CXX11 0)
        else()
            set(COMPILER_SUPPORTS_CXX11 1)
        endif()
    endif()

    if(COMPILER_SUPPORTS_CXX11)
    else()
        message(FATAL_ERROR "You need a compiler with C++11 support.")
    endif()
endfunction(ms_check_cxx11_support)

macro(ms_find_source_files LANG SOURCE_DIR GLOB_OPTION PROJ_SRC)
    set(TEMP_PROJ_SRC "")
    if(${LANG} STREQUAL "CXX")
        file(${GLOB_OPTION}
            TEMP_PROJ_SRC
            "${SOURCE_DIR}/*.cpp"
            "${SOURCE_DIR}/*.cc"
            "${SOURCE_DIR}/*.c"
            "${SOURCE_DIR}/*.h"
            "${SOURCE_DIR}/*.hpp"
            )
    elseif(${LANG} STREQUAL "CS")
        file(${GLOB_OPTION}
            TEMP_PROJ_SRC
            "${SOURCE_DIR}/*.cs"
            )
    elseif(${LANG} STREQUAL "JAVA")
        file(${GLOB_OPTION}
            TEMP_PROJ_SRC
            "${SOURCE_DIR}/*.java"
            )
    endif()

    if(DEFINED DSN_DEBUG_CMAKE)
        message(STATUS "LANG = ${LANG}")
        message(STATUS "SOURCE_DIR = ${SOURCE_DIR}")
        message(STATUS "GLOB_OPTION = ${GLOB_OPTION}")
        message(STATUS "PROJ_SRC = ${${PROJ_SRC}}")
    endif()
    
    set(${PROJ_SRC} ${${PROJ_SRC}} ${TEMP_PROJ_SRC})
endmacro(ms_find_source_files)

function(dsn_add_project)
    if((NOT DEFINED MY_PROJ_LANG) OR (MY_PROJ_LANG STREQUAL ""))
        message(FATAL_ERROR "MY_PROJ_LANG is empty.")
    endif()
    if((NOT DEFINED MY_PROJ_TYPE) OR (MY_PROJ_TYPE STREQUAL ""))
        message(FATAL_ERROR "MY_PROJ_TYPE is empty.")
    endif()
    if((NOT DEFINED MY_PROJ_NAME) OR (MY_PROJ_NAME STREQUAL ""))
        message(FATAL_ERROR "MY_PROJ_NAME is empty.")
    endif()
    if(NOT DEFINED MY_SRC_SEARCH_MODE)
        set(MY_SRC_SEARCH_MODE "GLOB")
    endif()
    if(NOT DEFINED MY_PROJ_SRC)
        set(MY_PROJ_SRC "")
    endif()
    set(TEMP_SRC "")
    ms_find_source_files("${MY_PROJ_LANG}" "${CMAKE_CURRENT_SOURCE_DIR}" ${MY_SRC_SEARCH_MODE} TEMP_SRC)
    set(MY_PROJ_SRC ${TEMP_SRC} ${MY_PROJ_SRC})
    if(NOT DEFINED MY_PROJ_INC_PATH)
        set(MY_PROJ_INC_PATH "")
    endif()
    if(NOT DEFINED MY_PROJ_LIBS)
        set(MY_PROJ_LIBS "")
    endif()
    if(NOT DEFINED MY_PROJ_LIB_PATH)
        set(MY_PROJ_LIB_PATH "")
    endif()
    if(NOT DEFINED MY_PROJ_BINPLACES)
        set(MY_PROJ_BINPLACES "")
    endif()
    if(NOT DEFINED MY_BOOST_PACKAGES)
        set(MY_BOOST_PACKAGES "")
    endif()
    if(NOT DEFINED MY_DO_INSTALL)
        if(DSN_BUILD_RUNTIME AND (MY_PROJ_TYPE STREQUAL "EXECUTABLE"))
            set(MY_DO_INSTALL FALSE)
        else()
            set(MY_DO_INSTALL TRUE)
        endif()
    endif()
    
    if(MY_PROJ_LANG STREQUAL "CXX")
        set(MY_BOOST_LIBS "")
        if(NOT (MY_BOOST_PACKAGES STREQUAL ""))
            ms_setup_boost(TRUE "${MY_BOOST_PACKAGES}" MY_BOOST_LIBS)
        endif()
    
        if(DSN_SERIALIZATION_TYPE STREQUAL "thrift")
            include_directories(${THRIFT_INCLUDE_DIR})
        endif()

        if((MY_PROJ_TYPE STREQUAL "SHARED") OR (MY_PROJ_TYPE STREQUAL "EXECUTABLE"))
            if(DSN_BUILD_RUNTIME AND(DEFINED DSN_IN_CORE) AND DSN_IN_CORE)
                set(TEMP_LIBS "")
            else()
                set(TEMP_LIBS dsn.dev.cpp dsn.core)
            endif()
            set(MY_PROJ_LIBS ${MY_PROJ_LIBS} ${MY_BOOST_LIBS} ${TEMP_LIBS})
            if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
                set(MY_PROJ_LIBS ${MY_PROJ_LIBS} ${DSN_SYSTEM_LIBS})
            else()
                set(MY_PROJ_LIBS ${DSN_SYSTEM_LIBS} ${MY_PROJ_LIBS})
            endif()
            #message(STATUS "MY_PROJ_LIBS = ${MY_PROJ_LIBS}")
            if(DSN_SERIALIZATION_TYPE STREQUAL "thrift")
                if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
                    set(MY_PROJ_LIBS ${MY_PROJ_LIBS} thrift)
                else()
                    message(FATAL_ERROR "thrift serialization currently only support Linux")
                endif()
            endif()
        endif()
    endif()

    if(DEFINED DSN_DEBUG_CMAKE)
        message(STATUS "MY_PROJ_TYPE = ${MY_PROJ_TYPE}")
        message(STATUS "MY_PROJ_NAME = ${MY_PROJ_NAME}")
        message(STATUS "MY_PROJ_SRC = ${MY_PROJ_SRC}")
        message(STATUS "MY_SRC_SEARCH_MODE = ${MY_SRC_SEARCH_MODE}")
        message(STATUS "MY_PROJ_INC_PATH = ${MY_PROJ_INC_PATH}")
        message(STATUS "MY_PROJ_LIBS = ${MY_PROJ_LIBS}")
        message(STATUS "MY_PROJ_LIB_PATH = ${MY_PROJ_LIB_PATH}")
        message(STATUS "MY_PROJ_BINPLACES = ${MY_PROJ_BINPLACES}")
        message(STATUS "MY_DO_INSTALL = ${MY_DO_INSTALL}")
        message(STATUS "MY_BOOST_PACKAGES = ${MY_BOOST_PACKAGES}")
        message(STATUS "MY_BOOST_LIBS = ${MY_BOOST_LIBS}")
    endif()
    
    ms_add_project("${MY_PROJ_LANG}" "${MY_PROJ_TYPE}" "${MY_PROJ_NAME}" "${MY_PROJ_SRC}" "${MY_PROJ_INC_PATH}" "${MY_PROJ_LIBS}" "${MY_PROJ_LIB_PATH}" "${MY_BINPLACES}" "${MY_DO_INSTALL}")
    if(DSN_SERIALIZATION_TYPE STREQUAL "thrift")
        add_dependencies(${MY_PROJ_NAME} libthrift)
    endif()
endfunction(dsn_add_project)

function(dsn_add_cs_shared_library)
    set(MY_PROJ_LANG "CS")
    set(MY_PROJ_TYPE "SHARED")
    dsn_add_cs_project()
endfunction(dsn_add_cs_shared_library)

function(dsn_add_cs_executable)
    set(MY_PROJ_LANG "CS")
    set(MY_PROJ_TYPE "EXECUTABLE")
    dsn_add_cs_project()
endfunction(dsn_add_cs_executable)

function(dsn_add_cs_project)
    dsn_add_project()
endfunction(dsn_add_cs_project)

function(dsn_add_java_shared_library)
    set(MY_PROJ_LANG "JAVA")
    set(MY_PROJ_TYPE "SHARED")
    dsn_add_java_project()
endfunction(dsn_add_java_shared_library)

function(dsn_add_java_executable)
    set(MY_PROJ_LANG "JAVA")
    set(MY_PROJ_TYPE "EXECUTABLE")
    dsn_add_java_project()
endfunction(dsn_add_java_executable)

function(dsn_add_java_project)
    find_package(Java REQUIRED)
    include(UseJava)
    dsn_add_project()
endfunction(dsn_add_java_project)

function(dsn_add_static_library)
    set(MY_PROJ_LANG "CXX")
    set(MY_PROJ_TYPE "STATIC")
    dsn_add_project()
endfunction(dsn_add_static_library)

function(dsn_add_shared_library)
    set(MY_PROJ_LANG "CXX")
    set(MY_PROJ_TYPE "SHARED")
    dsn_add_project()
endfunction(dsn_add_shared_library)

function(dsn_add_executable)
    set(MY_PROJ_LANG "CXX")
    set(MY_PROJ_TYPE "EXECUTABLE")
    dsn_add_project()
endfunction(dsn_add_executable)

function(dsn_setup_compiler_flags)
    ms_replace_compiler_flags("STATIC_LINK")

    if(UNIX)
        if(CMAKE_USE_PTHREADS_INIT)
            add_compile_options(-pthread)
        endif()   
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            add_definitions(-D_DEBUG)
        else()
            add_definitions(-O2)
        endif()
        add_compile_options(-std=c++11)
        if(DEFINED DSN_PEDANTIC)
            add_compile_options(-Werror)
        endif()
    elseif(MSVC)
        add_definitions(-D_CRT_SECURE_NO_WARNINGS)
        add_definitions(-DWIN32_LEAN_AND_MEAN)        
        add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
        add_definitions(-D_WINSOCK_DEPRECATED_NO_WARNINGS=1)
        add_definitions(-D_WIN32_WINNT=0x0600)
        add_definitions(-D_UNICODE)
        add_definitions(-DUNICODE)
        add_compile_options(-MP)
        if(DEFINED DSN_PEDANTIC)
            add_compile_options(-WX)
        endif()
    endif()
endfunction(dsn_setup_compiler_flags)

macro(ms_setup_boost STATIC_LINK PACKAGES BOOST_LIBS)
    if(DEFINED DSN_DEBUG_CMAKE)
        message(STATUS "BOOST_PACKAGES = ${PACKAGES}")
    endif()
    
    set(Boost_USE_MULTITHREADED            ON)
    if(MSVC)#${STATIC_LINK})
        set(Boost_USE_STATIC_LIBS        ON)
        set(Boost_USE_STATIC_RUNTIME    ON)
    else()
        set(Boost_USE_STATIC_LIBS        OFF)
        set(Boost_USE_STATIC_RUNTIME    OFF)
    endif()

    find_package(Boost COMPONENTS ${PACKAGES} REQUIRED)

    if(NOT Boost_FOUND)
        message(FATAL_ERROR "Cannot find library boost")
    endif()

    set(TEMP_LIBS "")
    foreach(PACKAGE ${PACKAGES})
        string(TOUPPER ${PACKAGE} PACKAGE)
        set(TEMP_LIBS ${TEMP_LIBS} ${Boost_${PACKAGE}_LIBRARY})
    endforeach()
    set(${BOOST_LIBS} ${TEMP_LIBS})
endmacro(ms_setup_boost)

function(dsn_setup_packages)
    if(UNIX)
        set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
    endif()
    find_package(Threads REQUIRED)
        
    set(DSN_SYSTEM_LIBS "")

    if(UNIX AND (NOT APPLE))
        find_library(DSN_LIB_RT NAMES rt)
        if(DSN_LIB_RT STREQUAL "DSN_LIB_RT-NOTFOUND")
            message(FATAL_ERROR "Cannot find library rt")
        endif()
        set(DSN_SYSTEM_LIBS ${DSN_SYSTEM_LIBS} ${DSN_LIB_RT})
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        find_library(DSN_LIB_AIO NAMES aio)
        if(DSN_LIB_AIO STREQUAL "DSN_LIB_AIO-NOTFOUND")
            message(FATAL_ERROR "Cannot find library aio")
        endif()
        set(DSN_SYSTEM_LIBS ${DSN_SYSTEM_LIBS} ${DSN_LIB_AIO})
    endif()

    if((CMAKE_SYSTEM_NAME STREQUAL "Linux"))
        find_library(DSN_LIB_DL NAMES dl)
        if(DSN_LIB_DL STREQUAL "DSN_LIB_DL-NOTFOUND")
            message(FATAL_ERROR "Cannot find library dl")
        endif()
        set(DSN_SYSTEM_LIBS ${DSN_SYSTEM_LIBS} ${DSN_LIB_DL})
    endif()

    if((CMAKE_SYSTEM_NAME STREQUAL "FreeBSD"))
        find_library(DSN_LIB_UTIL NAMES util)
        if(DSN_LIB_UTIL STREQUAL "DSN_LIB_UTIL-NOTFOUND")
            message(FATAL_ERROR "Cannot find library util")
        endif()
        set(DSN_SYSTEM_LIBS ${DSN_SYSTEM_LIBS} ${DSN_LIB_UTIL})
    endif()

    set(DSN_SYSTEM_LIBS
        ${DSN_SYSTEM_LIBS}
        ${CMAKE_THREAD_LIBS_INIT}
        CACHE STRING "rDSN system libs" FORCE
    )
endfunction(dsn_setup_packages)

function(dsn_set_output_path)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE STRING "" FORCE)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE STRING "" FORCE)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE STRING "" FORCE)
endfunction(dsn_set_output_path)

function(dsn_setup_include_path)
    if(DEFINED BOOST_ROOT)
        include_directories(${BOOST_ROOT}/include)
    endif()
    include_directories(${BOOST_INCLUDEDIR})
    if(DSN_BUILD_RUNTIME)
        include_directories(${CMAKE_SOURCE_DIR}/include)
    else()
        include_directories(${DSN_ROOT}/include)
    endif()
endfunction(dsn_setup_include_path)

function(dsn_setup_link_path)
    link_directories(${BOOST_LIBRARYDIR} ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
    if(DSN_BUILD_RUNTIME)
    else()
        link_directories(${DSN_ROOT}/lib)
    endif()
endfunction(dsn_setup_link_path)

function(dsn_setup_install)
    if(DSN_BUILD_RUNTIME)
        install(DIRECTORY include/ DESTINATION include)
        install(DIRECTORY bin/ DESTINATION bin USE_SOURCE_PERMISSIONS)
        install(DIRECTORY ${PROJECT_BINARY_DIR}/lib/ DESTINATION lib)
        #if(MSVC)
        #    install(FILES "bin/dsn.cg.bat" DESTINATION bin)
        #else()
        #    install(PROGRAMS "bin/dsn.cg.sh" DESTINATION bin)
        #    install(PROGRAMS "bin/Linux/thrift" DESTINATION bin/Linux)
        #    install(PROGRAMS "bin/Linux/protoc" DESTINATION bin/Linux)
        #    install(PROGRAMS "bin/Darwin/thrift" DESTINATION bin/Darwin)
        #    install(PROGRAMS "bin/Darwin/protoc" DESTINATION bin/Darwin)
        #    install(PROGRAMS "bin/FreeBSD/thrift" DESTINATION bin/FreeBSD)
        #    install(PROGRAMS "bin/FreeBSD/protoc" DESTINATION bin/FreeBSD)
        #endif()
    endif()
endfunction(dsn_setup_install)

function(dsn_add_pseudo_projects)
    if(DSN_BUILD_RUNTIME AND MSVC_IDE)
        file(GLOB_RECURSE
            PROJ_SRC
            "${CMAKE_SOURCE_DIR}/include/*.h"
            "${CMAKE_SOURCE_DIR}/include/*.hpp"
            )
        add_custom_target("dsn.include" SOURCES ${PROJ_SRC})
    endif()
endfunction(dsn_add_pseudo_projects)

function(dsn_setup_serialization)
    if(NOT DEFINED DSN_SERIALIZATION_TYPE)
        set(DSN_SERIALIZATION_TYPE "dsn")
    endif()

    if(DSN_SERIALIZATION_TYPE STREQUAL "dsn")
        message(STATUS "use default serialization method")
    elseif(DSN_SERIALIZATION_TYPE STREQUAL "thrift")
        message(STATUS "use thrift serialization method")
        add_definitions(-DDSN_NOT_USE_DEFAULT_SERIALIZATION)
    else()
        message(FATAL_ERROR "not support other serialization method")
    endif()
endfunction(dsn_setup_serialization)

function(dsn_common_setup)
    if(NOT WIN32)
        execute_process(COMMAND sh -c "rm -rf ${CMAKE_SOURCE_DIR}/.matchfile")
    endif()

    if(NOT (UNIX OR WIN32))
        message(FATAL_ERROR "Only Unix and Windows are supported.")
    endif()

    if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
        message(FATAL_ERROR "In-source builds are not allowed.")
    endif()

    if(NOT DEFINED DSN_BUILD_RUNTIME)
        set(DSN_BUILD_RUNTIME FALSE)
    endif()
    
    message (STATUS "Installation directory: CMAKE_INSTALL_PREFIX = " ${CMAKE_INSTALL_PREFIX})    
    set(DSN_ROOT2 "$ENV{DSN_ROOT}")
    if((NOT (DSN_ROOT2 STREQUAL "")) AND (EXISTS "${DSN_ROOT2}/"))
        set(CMAKE_INSTALL_PREFIX ${DSN_ROOT2} CACHE STRING "" FORCE)
        message (STATUS "Installation directory redefined w/ ENV{DSN_ROOT}: " ${CMAKE_INSTALL_PREFIX})    
    endif()
    
    set(BUILD_SHARED_LIBS OFF)
    ms_check_cxx11_support()
    dsn_setup_packages()
    dsn_setup_serialization()
    dsn_setup_compiler_flags()
    dsn_setup_include_path()
    dsn_set_output_path()
    dsn_setup_link_path()
    dsn_setup_install()
endfunction(dsn_common_setup)
