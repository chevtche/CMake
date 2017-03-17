# Copyright (c) 2013-2017 Stefan.Eilemann@epfl.ch
#                         Raphael.Dumusc@epfl.ch
# Info: http://www.itk.org/Wiki/CMake:Component_Install_With_CPack
#
# Configures the packaging of the project using CPack.
#
# Also includes CommonPackageConfig (legacy, to be removed in the future).
#
# Input:
# * COMMON_PACKAGE_ABI add the ABI version to the package name (default: ON)

# No support for subproject packaging
if(NOT PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  include(CommonPackageConfig)
  return()
endif()

if(NOT DEFINED COMMON_PACKAGE_ABI)
  set(COMMON_PACKAGE_ABI ON)
endif()

if(NOT CPACK_PROJECT_NAME)
  set(CPACK_PROJECT_NAME ${PROJECT_NAME})
endif()

if(NOT CPACK_PACKAGE_NAME)
  set(CPACK_PACKAGE_NAME ${CPACK_PROJECT_NAME})
endif()

if(NOT CPACK_PACKAGE_DESCRIPTION_SUMMARY)
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${${UPPER_PROJECT_NAME}_DESCRIPTION})
endif()

if(NOT CPACK_PACKAGE_LICENSE)
  set(CPACK_PACKAGE_LICENSE ${${UPPER_PROJECT_NAME}_LICENSE})
endif()
if(NOT CPACK_PACKAGE_LICENSE)
  message(FATAL_ERROR "Missing CPACK_PACKAGE_LICENSE")
endif()

if(NOT CPACK_RESOURCE_FILE_LICENSE)
  set(CPACK_RESOURCE_FILE_LICENSE ${PROJECT_SOURCE_DIR}/LICENSE.txt)
endif()
if(NOT EXISTS ${CPACK_RESOURCE_FILE_LICENSE})
  message(AUTHOR_WARNING "${CPACK_RESOURCE_FILE_LICENSE} file not found, provide one or set CPACK_RESOURCE_FILE_LICENSE to point to an existing one.")
endif()

if(NOT CPACK_PACKAGE_CONTACT)
  set(CPACK_PACKAGE_CONTACT ${${UPPER_PROJECT_NAME}_MAINTAINER})
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  if(EXISTS ${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.in.spec)
    configure_file(${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.in.spec
      ${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.spec @ONLY)
  endif()

  string(TOLOWER ${CPACK_PACKAGE_NAME} LOWER_PACKAGE_NAME_PREFIX)
  set(CPACK_PACKAGE_NAME "${LOWER_PACKAGE_NAME_PREFIX}")

  set(OLD_PACKAGES)
  if(COMMON_PACKAGE_ABI AND ${PROJECT_NAME}_VERSION_ABI)
    set(CPACK_PACKAGE_NAME "${CPACK_PACKAGE_NAME}${${PROJECT_NAME}_VERSION_ABI}")
    math(EXPR NUM_OLD_PACKAGES "${${PROJECT_NAME}_VERSION_ABI} - 1")
    foreach(i RANGE ${NUM_OLD_PACKAGES})
      list(APPEND OLD_PACKAGES "${LOWER_PACKAGE_NAME_PREFIX}${i},")
    endforeach()
    list(APPEND OLD_PACKAGES "${LOWER_PACKAGE_NAME_PREFIX}")
    string(REGEX REPLACE ";" " " OLD_PACKAGES ${OLD_PACKAGES})
  endif()
endif()

if(NOT APPLE)
  # deb lintian insists on URL
  set(CPACK_PACKAGE_VENDOR "http://${CPACK_PACKAGE_VENDOR}")
endif()

set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
if(NOT CPACK_DEBIAN_BUILD_DEPENDS)
  set(CPACK_DEBIAN_BUILD_DEPENDS cmake doxygen git graphviz pkg-config
      ${${UPPER_PROJECT_NAME}_DEB_DEPENDS})
endif()

# Default component definition
if(NOT CPACK_COMPONENTS_ALL)
  set(CPACK_COMPONENTS_ALL unspecified lib dev doc apps examples)

  set(CPACK_COMPONENT_UNSPECIFIED_DISPLAY_NAME "Unspecified")
  set(CPACK_COMPONENT_UNSPECIFIED_DESCRIPTION
    "Unspecified Component - set COMPONENT in CMake install() command")

  set(CPACK_COMPONENT_LIB_DISPLAY_NAME "${CPACK_PROJECT_NAME} Libraries")
  set(CPACK_COMPONENT_LIB_DESCRIPTION "${CPACK_PROJECT_NAME} Runtime Libraries")

  set(CPACK_COMPONENT_DEV_DISPLAY_NAME
    "${CPACK_PROJECT_NAME} Development Files")
  set(CPACK_COMPONENT_DEV_DESCRIPTION
    "Header and Library Files for ${CPACK_PROJECT_NAME} Development")
  set(CPACK_COMPONENT_DEV_DEPENDS lib)

  set(CPACK_COMPONENT_DOC_DISPLAY_NAME "${CPACK_PROJECT_NAME} Documentation")
  set(CPACK_COMPONENT_DOC_DESCRIPTION "${CPACK_PROJECT_NAME} Documentation")
  set(CPACK_COMPONENT_DOC_DEPENDS lib)

  set(CPACK_COMPONENT_APPS_DISPLAY_NAME "${CPACK_PROJECT_NAME} Applications")
  set(CPACK_COMPONENT_APPS_DESCRIPTION "${CPACK_PROJECT_NAME} Applications")
  set(CPACK_COMPONENT_APPS_DEPENDS lib)

  set(CPACK_COMPONENT_EXAMPLES_DISPLAY_NAME "${CPACK_PROJECT_NAME} Examples")
  set(CPACK_COMPONENT_EXAMPLES_DESCRIPTION
    "${CPACK_PROJECT_NAME} Example Source Code")
  set(CPACK_COMPONENT_EXAMPLES_DEPENDS dev)
elseif(CPACK_COMPONENTS_ALL STREQUAL "none")
  set(CPACK_COMPONENTS_ALL)
endif()

include(LSBInfo)

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  find_program(RPM_EXE rpmbuild)
  find_program(DEB_EXE debuild)
endif()

# Auto-package-version magic
include(GitInfo)
set(CMAKE_PACKAGE_VERSION "" CACHE
  STRING "Additional build version for packages")
mark_as_advanced(CMAKE_PACKAGE_VERSION)

if(GIT_REVISION)
  if(NOT PACKAGE_VERSION_REVISION STREQUAL GIT_REVISION)
    if(PACKAGE_VERSION_REVISION)
      if(CMAKE_PACKAGE_VERSION)
        math(EXPR CMAKE_PACKAGE_VERSION "${CMAKE_PACKAGE_VERSION} + 1")
      else()
        set(CMAKE_PACKAGE_VERSION "1")
      endif()
    else()
      set(CMAKE_PACKAGE_VERSION "")
    endif()
    set(CMAKE_PACKAGE_VERSION ${CMAKE_PACKAGE_VERSION} CACHE STRING
      "Additional build version for packages" FORCE)
  endif()
  set(PACKAGE_VERSION_REVISION ${GIT_REVISION} CACHE INTERNAL "" FORCE)
endif()

# Heuristics to figure out cpack generator
if(MSVC)
  set(CPACK_GENERATOR "NSIS")
  set(CPACK_NSIS_MODIFY_PATH ON)
elseif(APPLE)
  set(CPACK_GENERATOR "PackageMaker")
  set(CPACK_OSX_PACKAGE_VERSION "${${UPPER_PROJECT_NAME}_OSX_VERSION}")
elseif(LSB_DISTRIBUTOR_ID MATCHES "Ubuntu")
  set(CPACK_GENERATOR "DEB")
elseif(LSB_DISTRIBUTOR_ID MATCHES "RedHatEnterpriseServer")
  set(CPACK_GENERATOR "RPM")
elseif(DEB_EXE)
  set(CPACK_GENERATOR "DEB")
elseif(RPM_EXE)
  set(CPACK_GENERATOR "RPM")
else()
  set(CPACK_GENERATOR "TGZ")
endif()

if(CPACK_GENERATOR STREQUAL "RPM")
  set(CPACK_RPM_PACKAGE_GROUP "Development/Libraries")
  set(CPACK_RPM_PACKAGE_LICENSE ${CPACK_PACKAGE_LICENSE})
  set(CPACK_RPM_PACKAGE_RELEASE ${CMAKE_PACKAGE_VERSION})
  set(CPACK_RPM_PACKAGE_VERSION ${PROJECT_VERSION})
  set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}.${CMAKE_SYSTEM_PROCESSOR}")
  if(NOT CPACK_RPM_POST_INSTALL_SCRIPT_FILE)
    set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${CMAKE_CURRENT_LIST_DIR}/rpmPostInstall.sh")
  endif()
  set(CPACK_RPM_PACKAGE_OBSOLETES ${OLD_PACKAGES})
    set(PACKAGE_FILE_NAME ${CPACK_PACKAGE_FILE_NAME}.rpm)
else()
  if(CMAKE_PACKAGE_VERSION)
    set(CPACK_PACKAGE_VERSION
      ${CPACK_PACKAGE_VERSION}-${CMAKE_PACKAGE_VERSION})
  endif()

  if(CPACK_GENERATOR STREQUAL "DEB")
    # Follow Debian package naming conventions:
    # https://www.debian.org/doc/manuals/debian-faq/ch-pkg_basics.en.html

    # Build version, e.g. 1.3.2~xenial or 1.3.2-1~xenial when re-releasing.
    # Note: the ~codename is not part of any standard and could be omitted.
    if(NOT CPACK_DEBIAN_PACKAGE_VERSION)
      set(CPACK_DEBIAN_PACKAGE_VERSION
        "${CPACK_PACKAGE_VERSION}~${LSB_CODENAME}")
    endif()

    # Get architecture name, e.g. amd64. Reference:
    # https://www.debian.org/doc/debian-policy/ch-customized-programs.html#s-arch-spec
    execute_process(COMMAND dpkg --print-architecture OUTPUT_VARIABLE _deb_arch
      OUTPUT_STRIP_TRAILING_WHITESPACE)

    set(CPACK_PACKAGE_FILE_NAME
      "${CPACK_PACKAGE_NAME}_${CPACK_DEBIAN_PACKAGE_VERSION}_${_deb_arch}")

    if(NOT CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA)
      set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "/sbin/ldconfig")
    endif()

    if(NOT CPACK_DEBIAN_PACKAGE_MAINTAINER)
      set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_CONTACT}")
    endif()

    set(CPACK_DEBIAN_PACKAGE_CONFLICTS ${OLD_PACKAGES})
    set(PACKAGE_FILE_NAME ${CPACK_PACKAGE_FILE_NAME}.deb)
  endif()
endif()

set(CPACK_STRIP_FILES TRUE)
include(InstallRequiredSystemLibraries)

set(CPACK_PACKAGE_FILE_NAME_BACKUP "${CPACK_PACKAGE_FILE_NAME}")
include(CPack)
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_NAME_BACKUP}")

include(CommonPackageConfig)
