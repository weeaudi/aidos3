cmake_minimum_required(VERSION 3.10)

include(ExternalProject)

#----------------------------------------------------------------------------
# Check for required tools
#----------------------------------------------------------------------------
# Check for Nasm
find_program(NASM_EXECUTABLE nasm)
if(NOT NASM_EXECUTABLE)
  message(FATAL_ERROR "Nasm is not installed. Please install Nasm.")
endif()

set(CMAKE_ASM_COMPILER ${NASM_EXECUTABLE})
enable_language(ASM_NASM)

# Check for kconfig-mconf (part of kconfig-frontends)
find_program(KCONFIG_MCONF_EXECUTABLE kconfig-mconf)
if(NOT KCONFIG_MCONF_EXECUTABLE)
  message(STATUS "kconfig-mconf is not available. Please install kconfig-frontends to use configuration.")
  set(GCC_VERSION 13.2.0)
  set(GCC_URL https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz)

  set(BINUTILS_VERSION 2.41)
  set(BINUTILS_URL https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz)

  set(TARGET x86_64-elf)
  set(PREFIX_DIR "Tools/${TARGET}")

  set(LOCAL_DEPS_DIR "${CMAKE_BINARY_DIR}/deps")
  set(GMP_PREFIX "${LOCAL_DEPS_DIR}/gmp")
  set(MPC_PREFIX "${LOCAL_DEPS_DIR}/mpc")
  set(MPFR_PREFIX "${LOCAL_DEPS_DIR}/mpfr")

  set(VERSION_NUMBER 0.0.3)

else()

  #----------------------------------------------------------------------------
  # Run kconfig-mconf if configuration does not exist
  #----------------------------------------------------------------------------
  # Path to the generated configuration file
  set(CONFIG_FILE "${CMAKE_BINARY_DIR}/.config")

  if(EXISTS ${CONFIG_FILE})
    message(STATUS "Parsing configuration file: ${CONFIG_FILE}")
    file(STRINGS "${CONFIG_FILE}" CONFIG_LINES)

    foreach(line IN LISTS CONFIG_LINES)
      # Skip comment lines.
      if(line MATCHES "^#")
        continue()
      endif()
      # Match lines like: CONFIG_VARNAME="value"
      if(line MATCHES "^CONFIG_([A-Za-z0-9_]+)=(.*)")
        set(varName ${CMAKE_MATCH_1})
        set(varValue ${CMAKE_MATCH_2})
        # Remove any surrounding quotes from the value
        string(REGEX REPLACE "^\"(.*)\"$" "\\1" varValue "${varValue}")
        message(STATUS "Parsed variable: ${varName} = ${varValue}")
        # Set the variable in the CMake cache (or as a normal variable)
        set(${varName} "${varValue}" CACHE STRING "Parsed from .config")
      endif()
    endforeach()
  else()
    message(STATUS "Configuration file not found.  Please run kconfig-mconf ../Kconfig to
  generate the configuration.")
    set(GCC_VERSION 13.2.0)
    set(GCC_URL https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz)

    set(BINUTILS_VERSION 2.41)
    set(BINUTILS_URL https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz)

    set(TARGET x86_64-elf)
    set(PREFIX_DIR "Tools/${TARGET}")

    set(LOCAL_DEPS_DIR "${CMAKE_BINARY_DIR}/deps")
    set(GMP_PREFIX "${LOCAL_DEPS_DIR}/gmp")
    set(MPC_PREFIX "${LOCAL_DEPS_DIR}/mpc")
    set(MPFR_PREFIX "${LOCAL_DEPS_DIR}/mpfr")

    set(VERSION_NUMBER 0.0.3)
  endif()

endif()

project(aidos3 VERSION ${VERSION_NUMBER})

# Substitute placeholders
string(REPLACE "@GCC_VERSION@" "${GCC_VERSION}" GCC_URL "${GCC_URL}")
string(REPLACE "@BINUTILS_VERSION@" "${BINUTILS_VERSION}" BINUTILS_URL "${BINUTILS_URL}")
string(REPLACE "@TARGET@" "${TARGET}" PREFIX_DIR "${PREFIX_DIR}")

#----------------------------------------------------------------------------
# Check for required dependencies
#----------------------------------------------------------------------------

# Detect system paths for Windows and Unix-like OSes
if (WIN32)
    set(SYSTEM_INCLUDE_PATHS "C:/msys64/mingw64/include" "C:/mingw-w64/include" "C:/local/include" $ENV{INCLUDE})
    set(SYSTEM_LIBRARY_PATHS "C:/msys64/mingw64/lib" "C:/mingw-w64/lib" "C:/local/lib" $ENV{LIB})
else()
    set(SYSTEM_INCLUDE_PATHS "/usr/include" "/usr/local/include" $ENV{CPATH})
    set(SYSTEM_LIBRARY_PATHS "/usr/lib" "/usr/local/lib" $ENV{LIBRARY_PATH})
endif()

# Check for GMP, MPFR, MPC in system paths
find_path(GMP_INCLUDE_DIR gmp.h PATHS ${SYSTEM_INCLUDE_PATHS})
find_library(GMP_LIBRARY gmp PATHS ${SYSTEM_LIBRARY_PATHS})

find_path(MPFR_INCLUDE_DIR mpfr.h PATHS ${SYSTEM_INCLUDE_PATHS})
find_library(MPFR_LIBRARY mpfr PATHS ${SYSTEM_LIBRARY_PATHS})

find_path(MPC_INCLUDE_DIR mpc.h PATHS ${SYSTEM_INCLUDE_PATHS})
find_library(MPC_LIBRARY mpc PATHS ${SYSTEM_LIBRARY_PATHS})

# Macro to add an external project if missing
macro(AddIfMissing NAME URL PREFIX)
    if (NOT EXISTS ${${NAME}_INCLUDE_DIR} OR NOT EXISTS ${${NAME}_LIBRARY})
      if(NOT WIN32)
        ExternalProject_Add(
            ${NAME}
            URL ${URL}
            PREFIX ${PREFIX}
            CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${PREFIX} ${ARGN}
            BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} -j16
            INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
            DOWNLOAD_EXTRACT_TIMESTAMP true
        )
        message(STATUS "${NAME} not found. Building from source.")
        set(${NAME}_PREFIX ${PREFIX})
      else()
        message(WARNING SKIPPING ${NAME})
      endif()
    else()
        message(STATUS "${NAME} found in system path: ${${NAME}_INCLUDE_DIR}")
        set(${NAME}_PREFIX ${${NAME}_INCLUDE_DIR})
    endif()
endmacro()

# Download and build dependencies only if missing
AddIfMissing(GMP  "https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz"  ${GMP_PREFIX})
AddIfMissing(MPFR "https://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.xz" ${MPFR_PREFIX} --with-gmp=${GMP_PREFIX})
AddIfMissing(MPC  "https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz"  ${MPC_PREFIX}  --with-gmp=${GMP_PREFIX} --with-mpfr=${MPFR_PREFIX})

# Set paths for GCC
set(GMP_PATH ${GMP_PREFIX})
set(MPFR_PATH ${MPFR_PREFIX})
set(MPC_PATH ${MPC_PREFIX})

# If system versions exist, use them instead of the local ones
if (GMP_LIBRARY AND GMP_INCLUDE_DIR)
    set(GMP_PATH "")
endif()

if (MPFR_LIBRARY AND MPFR_INCLUDE_DIR)
    set(MPFR_PATH "")
endif()

if (MPC_LIBRARY AND MPC_INCLUDE_DIR)
    set(MPC_PATH "")
endif()

#----------------------------------------------------------------------------
# Add external projects for build tools
#----------------------------------------------------------------------------

message(STATUS ${PREFIX_DIR})
message(STATUS ${CMAKE_SOURCE_DIR})
message(STATUS ${CMAKE_SOURCE_DIR}/${PREFIX_DIR})
if(NOT WIN32)
ExternalProject_Add(
  binutils
  URL ${BINUTILS_URL}
  URL_MD5 9ef8d27543a854eaecc8ceeadc100697
  PREFIX "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}"
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --target=${TARGET} --prefix=${CMAKE_SOURCE_DIR}/${PREFIX_DIR} --with-sysroot= --disable-nls --disable-werror
  BUILD_COMMAND make -j16
  INSTALL_COMMAND make install
  DOWNLOAD_EXTRACT_TIMESTAMP true
)

ExternalProject_Add(
  gcc
  DEPENDS binutils
  URL ${GCC_URL}
  URL_MD5 aeb5ac806c34d47e725bdd025f34bac4
  PREFIX "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}"
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --target=${TARGET} --prefix=${CMAKE_SOURCE_DIR}/${PREFIX_DIR} --disable-nls --enable-languages=c,c++ --without-headers --with-gmp=${GMP_PATH} --with-mpfr=${MPFR_PATH} --with-mpc=${MPC_PATH}
  BUILD_COMMAND make -j16 all-gcc all-target-libgcc
  INSTALL_COMMAND make install-gcc install-target-libgcc
  DOWNLOAD_EXTRACT_TIMESTAMP true
)
else()
  MESSAGE(WARNING GCC AND BINUTILS MUST BE INSTALLED MANNUALLY)
endif()

if(NOT WIN32)
  set(CMAKE_C_COMPILER "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}/bin/${TARGET}-gcc")
  set(CMAKE_CXX_COMPILER "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}/bin/${TARGET}-g++")
  set(CMAKE_ASM_NASM_FLAGS "-f elf64 -g")
  set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <DEFINES> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")
  set(CMAKE_LINKER "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}/bin/${TARGET}-g++")
  set(CMAKE_AR "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}/bin/${TARGET}-ar")
  set(CMAKE_NM "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}/bin/${TARGET}-nm")
  set(CMAKE_OBJCOPY "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}/bin/${TARGET}-objcopy")
  set(CMAKE_OBJDUMP "${CMAKE_SOURCE_DIR}/${PREFIX_DIR}/bin/${TARGET}-objdump")
else()
  find_program(GCC_EXECUTABLE gcc)
  if(NOT GCC_EXECUTABLE)
    message(FATAL_ERROR "GCC is not installed. Please install GCC.")
  endif()
  set(CMAKE_C_COMPILER GCC_EXECUTABLE)
  
  find_program(GXX_EXECUTABLE g++)
  if(NOT GXX_EXECUTABLE)
    message(FATAL_ERROR "G++ is not installed. Please install G++.")
  endif()
  set(CMAKE_CXX_COMPILER GPP_EXECUTABLE)
  
  set(CMAKE_ASM_NASM_FLAGS "-f elf64 -g")
  set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <DEFINES> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")
  
endif()

add_subdirectory(${CMAKE_SOURCE_DIR}/src)
add_subdirectory(${CMAKE_SOURCE_DIR}/image)

set(DISK_IMAGE "${CMAKE_BINARY_DIR}/out/aidos_${CMAKE_PROJECT_VERSION}.raw")

set(CMAKE_VS_STARTUP_PROJECT "run")
add_custom_target(run
  COMMAND qemu-system-x86_64 -hda ${DISK_IMAGE}
  DEPENDS build_disk
  COMMENT "Running the boot image in QEMU"
)

add_custom_target(debug
  COMMAND qemu-system-x86_64 -debugcon stdio -hda ${DISK_IMAGE} -s -S
  DEPENDS build_disk stage1_debug_output stage2_debug_output
  COMMENT "Debugging the boot image in QEMU"
)
