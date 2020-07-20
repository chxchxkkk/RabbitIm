include(CheckCXXCompilerFlag)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
include(GenerateExportHeader)
include(CheckIncludeFile)
include(CheckIncludeFileCXX)
include(CheckFunctionExists)
include(cmake/RabbitImUtils.cmake)

#打开 qt 编译工具
SET(CMAKE_AUTOUIC ON)
SET(CMAKE_AUTOMOC ON)
SET(CMAKE_AUTORCC ON)
SET(CMAKE_INCLUDE_CURRENT_DIR ON)
SET(CMAKE_VERBOSE_MAKEFILE ON)

#需要的QT组件  
SET(QT_COMPONENTS Core Gui Widgets Network Xml Multimedia)
find_package(Qt5 COMPONENTS ${QT_COMPONENTS} REQUIRED)
message("Qt5_VERSION:${Qt5_VERSION}")
if(Qt5_VERSION VERSION_LESS "5.0.0")
    message(FATAL_ERROR "Current qt version:${Qt5_VERSION}, Qt must greater then 5.0.0")
endif()
FOREACH(_COMPONENT ${QT_COMPONENTS})
    SET(QT_LIBRARIES ${QT_LIBRARIES} ${Qt5${_COMPONENT}_LIBRARIES})
ENDFOREACH()
FIND_PACKAGE(Qt5 COMPONENTS WebKitWidgets)
IF(Qt5WebKitWidgets_FOUND)
    ADD_DEFINITIONS(-DRABBITIM_WEBKIT)
    SET(QT_LIBRARIES ${QT_LIBRARIES} ${Qt5WebKitWidgets_LIBRARIES})
ENDIF(Qt5WebKitWidgets_FOUND)
get_filename_component(QT_INSTALL_DIR "${Qt5_DIR}/../../.." ABSOLUTE)

if(NOT DEFINED CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif(NOT DEFINED CMAKE_BUILD_TYPE)
string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
if(BUILD_TYPE STREQUAL "debug")
    ADD_DEFINITIONS(-DDEBUG) # -DDEBUG_VIDEO_TIME )
    SET(RABBIT_CONFIG Debug)
else()
    SET(RABBIT_CONFIG Release)
endif()

set(RABBITIM_ARCHITECTURE "${CMAKE_SYSTEM_NAME}")
# ----------------------------------------------------------------------------
# Detect compiler and target platform architecture
# ----------------------------------------------------------------------------
if(NOT ANDROID)
    if(X86_64 OR CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(RABBITIM_ARCHITECTURE x86_64)
    elseif(X86 OR CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(RABBITIM_ARCHITECTURE x86)
    endif()
else()
    set(RABBITIM_ARCHITECTURE ${CMAKE_SYSTEM_PROCESSOR})
endif()

IF(MSVC)
    # This option is to enable the /MP switch for Visual Studio 2005 and above compilers
    OPTION(WIN32_USE_MP "Set to ON to build with the /MP option (Visual Studio 2005 and above)." ON)
    MARK_AS_ADVANCED(WIN32_USE_MP)
    IF(WIN32_USE_MP)
        #SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
        add_compile_options(/MP)
        add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")
    ENDIF(WIN32_USE_MP)
ENDIF(MSVC)

IF(CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
    OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_compile_options(-std=c++0x)
    if(BUILD_TYPE STREQUAL "debug")
        add_compile_options(-g -ggdb)
    else()
        add_compile_options(-O3)
    endif()
ENDIF()

# Add definitions for static/style library 
SET(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libs")
MESSAGE("Build shared library: ${BUILD_SHARED_LIBS}")
IF(BUILD_SHARED_LIBS)
    ADD_DEFINITIONS(-DQT_SHARED)
    add_definitions(-DBUILD_SHARED_LIBS)
    if (CMAKE_COMPILER_IS_GNUCXX AND NOT MINGW)
       # Just setting CMAKE_POSITION_INDEPENDENT_CODE should be enough to set
       # -fPIC for GCC but sometimes it still doesn't get set, so make sure it
       # does.
       add_definitions("-fPIC")
    endif()
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
ELSE(BUILD_SHARED_LIBS)
    ADD_DEFINITIONS(-DQT_STATIC -DRABBITIM_STATIC)
    set(CMAKE_LD_FLAGS "${CMAKE_LD_FLAGS} -static") 
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")   
ENDIF(BUILD_SHARED_LIBS)

# Exit for blacklisted compilers (those that don't support C++11 very well)
#  MSVC++ 8.0  _MSC_VER == 1400 (Visual Studio 2005)
#  Clang 3.0
SET(BAD_CXX_MESSAGE "")
IF(MSVC)
    IF(MSVC_VERSION LESS 1800)
      SET(BAD_CXX_MESSAGE "MSVC 2013 or higher")
    ENDIF()
ENDIF()
IF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    IF(${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 3.1.0)
      SET(BAD_CXX_MESSAGE "Clang v3.1.0 or higher")
    ENDIF()
ENDIF()
IF(BAD_CXX_MESSAGE)
    MESSAGE(FATAL_ERROR "\nSorry, ${BAD_CXX_MESSAGE} is required to build this software. Please retry using a modern compiler that supports C++11 lambdas.")
ENDIF()

IF(MSVC)
    SET(RABBITIM_SYSTEM windows)
    SET(BUILD_TARGE windows_msvc)
    SET(RABBIT_TOOLCHAIN_VERSION $ENV{RABBIT_TOOLCHAIN_VERSION})
    if(NOT RABBIT_TOOLCHAIN_VERSION)
        SET(VisualStudioVersion $ENV{VisualStudioVersion})
        #mark_as_advanced(VisualStudioVersion)
        if(VisualStudioVersion VERSION_EQUAL 12.0)
            SET(RABBIT_TOOLCHAIN_VERSION 12)
        elseif(VisualStudioVersion VERSION_EQUAL 14.0)
            SET(RABBIT_TOOLCHAIN_VERSION 14)
        elseif(VisualStudioVersion VERSION_EQUAL 15.0)
            SET(RABBIT_TOOLCHAIN_VERSION 15)
        elseif(VisualStudioVersion VERSION_EQUAL 16.0)
            SET(RABBIT_TOOLCHAIN_VERSION 16)
        else()
            message(FATAL_ERROR "Don't support msvc version: ${VisualStudioVersion}; please use msvc 2013, 2015, 2017, or set variable RABBIT_TOOLCHAIN_VERSION")
        endif()
    endif()
    add_compile_options("/wd4819")  #删除不是GBK字符的警告  
    
#    if(Qt5_VERSION VERSION_LESS "5.7.0")
#        SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SUBSYSTEM:WINDOWS\",5.01\"")
#    endif() 
    ADD_DEFINITIONS(-DWINDOWS)
ELSEIF(MINGW)
    SET(RABBITIM_SYSTEM windows)
    SET(BUILD_TARGE windows_mingw)
    SET(RABBIT_TOOLCHAIN_VERSION $ENV{RABBIT_TOOLCHAIN_VERSION})
    if(NOT RABBIT_TOOLCHAIN_VERSION)
        SET(RABBIT_TOOLCHAIN_VERSION 530)
    endif()
    # Windows compatibility
    #SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-subsystem,windows")
    # Statically link with libgcc
    #SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static -static-libgcc -static-libstdc++ ")
    ADD_DEFINITIONS(-DWINDOWS)
ELSEIF(ANDROID)
    SET(RABBITIM_SYSTEM android)
    SET(BUILD_TARGE android)
    SET(BUILD_SHARED_LIBS OFF CACHE FORCE) #android用静态编译  
    ADD_DEFINITIONS(-DMOBILE)
    INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/android/jni)
    FIND_PACKAGE(Qt5AndroidExtras REQUIRED)
    SET(QT_LIBRARIES ${QT_LIBRARIES} ${Qt5AndroidExtras_LIBRARIES})
    #SET(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -Wno-psabi -march=armv7-a -mfloat-abi=softfp -mfpu=vfp -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums  -Wa,--noexecstack -gdwarf-2 -marm -fno-omit-frame-pointer -Wall -Wno-psabi -W -fPIE)
    SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined -Wl,-z,noexecstack -shared --sysroot=${ANDROID_SYSROOT}")
ELSE(LINUX OR UNIX)
    SET(RABBITIM_SYSTEM unix)
    SET(BUILD_TARGE unix)
    ADD_DEFINITIONS(-DUNIX)
ENDIF()
IF(NOT DEFINED THIRD_LIBRARY_PATH)
    SET(THIRD_LIBRARY_PATH $ENV{THIRD_LIBRARY_PATH})
ENDIF()
IF(NOT DEFINED THIRD_LIBRARY_PATH)
    SET(THIRD_LIBRARY_PATH ${CMAKE_SOURCE_DIR}/ThirdLibrary/${BUILD_TARGE}${RABBIT_TOOLCHAIN_VERSION}_${RABBITIM_ARCHITECTURE}_${RABBIT_CONFIG}_qt${Qt5_VERSION}) #第三方开发包目录
ENDIF()
IF(NOT BUILD_SHARED_LIBS AND EXISTS "${THIRD_LIBRARY_PATH}_static")
    SET(THIRD_LIBRARY_PATH ${THIRD_LIBRARY_PATH}_static)
ENDIF()
INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR} 
    ${CMAKE_SOURCE_DIR}/Widgets/FrmCustom
    ${CMAKE_SOURCE_DIR}/common
    ${THIRD_LIBRARY_PATH}/include)        #第三方包含头文件目录
SET(THIRD_LIB_DIR ${THIRD_LIBRARY_PATH}/lib) #第三方库目录
LINK_DIRECTORIES(${THIRD_LIB_DIR})
ADD_DEFINITIONS(-DRABBITIM_SYSTEM="${RABBITIM_SYSTEM}")

file(GLOB dirs ${THIRD_LIBRARY_PATH}/lib/cmake/*)
foreach(d ${dirs})
    IF(IS_DIRECTORY ${d})
        list(APPEND CMAKE_MODULE_PATH ${d})
        list(APPEND CMAKE_PREFIX_PATH ${d})
    ENDIF()
endforeach(d)

mark_as_advanced(THIRD_LIBRARY_PATH)

#pkgconfig模块
#IF(MINGW)
#    set(ENV{PKG_CONFIG_PATH} "${THIRD_LIB_DIR}/pkgconfig" ENV{PKG_CONFIG_PATH})
#ELSEIF(ANDROID)
#    set(ENV{PKG_CONFIG_PATH} "${THIRD_LIB_DIR}/pkgconfig")
#    set(ENV{PKG_CONFIG_SYSROOT_DIR} "${THIRD_LIBRARY_PATH}")
#    set(ENV{PKG_CONFIG_LIBDIR} "${THIRD_LIB_DIR}/pkgconfig")
#ELSE()
#    set(ENV{PKG_CONFIG_PATH} "${THIRD_LIB_DIR}/pkgconfig" ENV{PKG_CONFIG_PATH})
#ENDIF()

#设置 find_package 搜索目录,(find_XXX.cmake)
#SET(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${THIRD_LIBRARY_PATH} ${CMAKE_MODULE_PATH})
#FIND_PACKAGE(PkgConfig)
##允许 pkg-config 在 CMAKE_PREFIX_PATH 中搜索库
#SET(PKG_CONFIG_USE_CMAKE_PREFIX_PATH TRUE)
##设置库的搜索路径
SET(CMAKE_PREFIX_PATH ${THIRD_LIB_DIR}/pkgconfig ${THIRD_LIB_DIR} ${THIRD_LIBRARY_PATH} ${CMAKE_PREFIX_PATH})
IF(ANDROID)
    SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${THIRD_LIBRARY_PATH}/sdk/native/jni)
    SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${THIRD_LIBRARY_PATH}/libs/${ANDROID_ABI}/pkgconfig)
    SET(THIRD_LIB_DIR ${THIRD_LIB_DIR} ${THIRD_LIBRARY_PATH}/libs/${ANDROID_ABI})
ENDIF(ANDROID)
#message("CMAKE_PREFIX_PATH:${CMAKE_PREFIX_PATH}")
