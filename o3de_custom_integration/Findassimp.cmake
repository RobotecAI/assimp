#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# --- MODIFIED TO USE LOCAL ASSIMP BUILD ---
#

# assimp depends on ZLIB. This part remains unchanged.
if (NOT TARGET ZLIB::ZLIB)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(ZLIB REQUIRED MODULE)
    endif()
    find_package(ZLIB REQUIRED) # Ensure ZLIB is found
endif()

# Target definition check remains unchanged.
set(TARGET_WITH_NAMESPACE "3rdParty::assimp")
if (TARGET ${TARGET_WITH_NAMESPACE})
    message(STATUS "FindAssimp.cmake: Target ${TARGET_WITH_NAMESPACE} already exists. Skipping redefinition.")
    return()
endif()

set(LIB_NAME "assimp")

# --- MODIFICATION START ---
# Point to your local Assimp build directory.
# !!! IMPORTANT: Replace "/home/YOUR_USERNAME" with the actual absolute path to your home directory !!!
set(ASSIMP_LOCAL_ROOT "/home/mzak/tools/my_assimp_install") 

# Assume standard build structure: includes in 'include', libs/binaries in 'lib'
# Adjust these paths if your local build structure is different.
set(${LIB_NAME}_INCLUDE_DIR ${ASSIMP_LOCAL_ROOT}/include)
set(${LIB_NAME}_LIBS_DIR ${ASSIMP_LOCAL_ROOT}/lib) 
# Often shared libs (.so/.dll) are in 'lib' too, but sometimes 'bin'. Adjust if needed.
set(${LIB_NAME}_BIN_DIR ${ASSIMP_LOCAL_ROOT}/lib) 

# --- NEW CHECK ---
# Explicitly try to find a known Assimp header ONLY in the desired local location.
# This helps confirm the path is correct and accessible *before* defining targets.
find_path(ASSIMP_CHECK_INCLUDE_DIR NAMES assimp/scene.h PATHS ${${LIB_NAME}_INCLUDE_DIR} NO_DEFAULT_PATH)
if (NOT ASSIMP_CHECK_INCLUDE_DIR)
    message(FATAL_ERROR "FindAssimp.cmake: Could not find 'scene.h' in the specified local include directory: ${${LIB_NAME}_INCLUDE_DIR}. Check the path and permissions. Make sure ASSIMP_LOCAL_ROOT is set correctly.")
else()
    message(STATUS "FindAssimp.cmake: Found Assimp header 'scene.h' in ${ASSIMP_CHECK_INCLUDE_DIR}. Proceeding with local build configuration.")
endif()
# --- END NEW CHECK ---


# --- VERIFY LIBRARY NAMES ---
# !!! IMPORTANT: Check the actual filenames in your ${ASSIMP_LOCAL_ROOT}/lib (and potentially /bin) directory !!!
# Replace the filenames below if your local build produces different names.
# Common names are used as placeholders.

if (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    # Example: Assumes shared lib is libassimp.so and static is libassimp.a
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_BIN_DIR}/libassimp.so) # Adjust if you have specific debug names
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_BIN_DIR}/libassimp.so)
    set(${LIB_NAME}_STATIC_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/libassimp.a) # Adjust if you have specific debug names
    set(${LIB_NAME}_STATIC_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/libassimp.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Mac")
    # Example: Assumes shared lib is libassimp.dylib and static is libassimp.a
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_BIN_DIR}/libassimp.dylib) # Adjust if you have specific debug names
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_BIN_DIR}/libassimp.dylib)
    set(${LIB_NAME}_STATIC_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/libassimp.a) # Adjust if you have specific debug names
    set(${LIB_NAME}_STATIC_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/libassimp.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    # Example: Assumes shared is assimp.dll/assimp.lib (import lib) and static is assimp-static.lib
    # Adjust based on your MSVC build settings (e.g., -mt, -mtd suffixes)
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_BIN_DIR}/assimpd.dll) # Or assimp-vcXXX-mtd.dll ? Check your build output
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_BIN_DIR}/assimp.dll)  # Or assimp-vcXXX-mt.dll ? Check your build output
    set(${LIB_NAME}_IMPORT_LIBRARY_DEBUG ${${LIB_NAME}_LIBS_DIR}/assimpd.lib) # Import lib for DLL
    set(${LIB_NAME}_IMPORT_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/assimp.lib) # Import lib for DLL
    set(${LIB_NAME}_STATIC_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/assimp-staticd.lib) # Example name for static debug
    set(${LIB_NAME}_STATIC_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/assimp-static.lib) # Example name for static release

    # Windows needs the import library for linking against DLLs
    set(${LIB_NAME}_LINK_LIBRARY_DEBUG ${${LIB_NAME}_IMPORT_LIBRARY_DEBUG})
    set(${LIB_NAME}_LINK_LIBRARY_RELEASE ${${LIB_NAME}_IMPORT_LIBRARY_RELEASE})
    # If you built ONLY static Assimp locally, uncomment the lines below and comment the two lines above
    # set(${LIB_NAME}_LINK_LIBRARY_DEBUG ${${LIB_NAME}_STATIC_LIBRARY_DEBUG})
    # set(${LIB_NAME}_LINK_LIBRARY_RELEASE ${${LIB_NAME}_STATIC_LIBRARY_RELEASE})
endif()
# --- MODIFICATION END ---


# set it to a generator expression for multi-config situations
set(${LIB_NAME}_DYNLIB $<IF:$<CONFIG:Debug>,${${LIB_NAME}_LIBRARY_DEBUG},${${LIB_NAME}_LIBRARY_RELEASE}>)

# Create the imported targets using the paths determined above.

# Static library wrapper
add_library(${TARGET_WITH_NAMESPACE}::imported STATIC IMPORTED)
set_target_properties(${TARGET_WITH_NAMESPACE}::imported
    PROPERTIES
        # Use the verified static library paths
        IMPORTED_LOCATION_DEBUG ${${LIB_NAME}_STATIC_LIBRARY_DEBUG}
        IMPORTED_LOCATION_PROFILE ${${LIB_NAME}_STATIC_LIBRARY_RELEASE} # Assuming profile uses release build
        IMPORTED_LOCATION_RELEASE ${${LIB_NAME}_STATIC_LIBRARY_RELEASE}
)
target_link_libraries(${TARGET_WITH_NAMESPACE}::imported
                            INTERFACE 3rdParty::zlib # Link against ZLIB
)

# Main interface library (links static wrapper, provides include dirs, points to DLL if applicable)
add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

# --- MODIFICATION ---
# Use standard target_include_directories instead of the ly_ helper
# This might affect precedence compared to system paths added elsewhere.
target_include_directories(${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_INCLUDE_DIR})
# --- END MODIFICATION ---


# Set properties based on whether we are linking dynamically or statically on Windows
if (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    # If linking against DLL, set IMPORTED_IMPLIB property
    # Check if we defined LINK_LIBRARY_DEBUG/RELEASE (meaning we likely target DLLs)
    if (DEFINED ${LIB_NAME}_LINK_LIBRARY_DEBUG)
         set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES
            INTERFACE_IMPORTED_IMPLIB_DEBUG "${${LIB_NAME}_LINK_LIBRARY_DEBUG}"
            INTERFACE_IMPORTED_IMPLIB_PROFILE "${${LIB_NAME}_LINK_LIBRARY_RELEASE}" # Assuming profile uses release build
            INTERFACE_IMPORTED_IMPLIB_RELEASE "${${LIB_NAME}_LINK_LIBRARY_RELEASE}"
            INTERFACE_IMPORTED_LOCATION_DEBUG "${${LIB_NAME}_LIBRARY_DEBUG}" # Point to the DLL itself
            INTERFACE_IMPORTED_LOCATION_PROFILE "${${LIB_NAME}_LIBRARY_RELEASE}"
            INTERFACE_IMPORTED_LOCATION_RELEASE "${${LIB_NAME}_LIBRARY_RELEASE}"
         )
    endif()
    # If linking statically (no DLL involved directly via this target)
    # the static lib is handled via the ::imported target linked below.
endif()

# Link the static part (::imported) into the main interface target
target_link_libraries(${TARGET_WITH_NAMESPACE}
                            INTERFACE ${TARGET_WITH_NAMESPACE}::imported
)


# Define runtime dependencies (the shared library files that need to be copied)
set(3RDPARTY_ASSIMP_RUNTIME_DEPENDENCIES "")
if (EXISTS "${${LIB_NAME}_LIBRARY_DEBUG}")
    list(APPEND 3RDPARTY_ASSIMP_RUNTIME_DEPENDENCIES "${${LIB_NAME}_LIBRARY_DEBUG}")
endif()
if (EXISTS "${${LIB_NAME}_LIBRARY_RELEASE}")
     # Avoid duplicates if debug/release names are the same
    if (NOT "${${LIB_NAME}_LIBRARY_DEBUG}" STREQUAL "${${LIB_NAME}_LIBRARY_RELEASE}")
       list(APPEND 3RDPARTY_ASSIMP_RUNTIME_DEPENDENCIES "${${LIB_NAME}_LIBRARY_RELEASE}")
    endif()
endif()


# --- MODIFICATION ---
# Comment out PyAssimp installation unless you specifically built it locally 
# and know the path relative to your ASSIMP_LOCAL_ROOT.
# ly_pip_install_local_package_editable(${CMAKE_CURRENT_LIST_DIR}/assimp/port/PyAssimp pyassimp) 
message(STATUS "FindAssimp.cmake: Configured to use local Assimp build from ${ASSIMP_LOCAL_ROOT}")

set(${LIB_NAME}_FOUND True)
