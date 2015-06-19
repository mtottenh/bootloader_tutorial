#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])
AC_INIT([homegrown_bootloader], [1.0], [bugs@maxtottenham.com])
AC_CONFIG_SRCDIR([src/utils/boot_install.c])
AC_CONFIG_HEADERS([config.h])

# Checks for programs.
AC_PROG_CC
AC_PROG_CC_STDC
AC_PROG_INSTALL
AC_CHECK_TOOL(OBJCOPY, objcopy)
AC_CHECK_TOOL(PANDOC, pandoc)

if test -z "$OBJCOPY"; then
		AC_MSG_ERROR([*** objcopy not found])
fi

if test -z "$PANDOC"; then
        AC_MSG_ERROR([*** pandoc not found])
fi

# Checks for libraries.

# Checks for header files.
AC_CHECK_HEADERS([fcntl.h stdint.h stdlib.h string.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT8_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_MMAP

AC_CONFIG_FILES([Makefile
                 src/Makefile
                 src/kernel/Makefile
                 src/kernel/boot/Makefile
                 src/kernel/boot/i386/Makefile
                 src/utils/Makefile
                 doc/Makefile])
AC_OUTPUT
