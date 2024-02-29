# Process this file with autoconf to produce a configure script
AC_INIT([libwired], [1.0], [dev@read-write.fr])
AC_PREREQ([2.57])
AC_CONFIG_SRCDIR([config.h.in])
AC_CONFIG_HEADER([config.h])

# Include shared macros
m4_include([config.m4])

# Get host
AC_CANONICAL_HOST

# These are used in the source code
AC_DEFINE([WI_VERSION], ["AC_PACKAGE_VERSION"], [Application version])

# These are used in the Makefile
AC_SUBST([WI_VERSION], ["AC_PACKAGE_VERSION"])


#######################################################################
# Checks for compilers

AC_PROG_CC
AC_PROG_CPP
AC_PROG_INSTALL
AC_PROG_MAKE_SET


#######################################################################
# Checks for flags

# Check for warnings
AC_MSG_CHECKING([for warning flags])
AC_ARG_ENABLE([warnings], AC_HELP_STRING([--enable-warnings], [enable warnings]))

if test -n "$enable_warnings"; then
	WI_INCLUDE_WARNING_FLAG([-W])
	WI_INCLUDE_WARNING_FLAG([-Wall])
	WI_INCLUDE_WARNING_FLAG([-Wno-unknown-pragmas])
	WI_INCLUDE_WARNING_FLAG([-Wno-unused-parameter])
	WI_INCLUDE_WARNING_FLAG([-Wsign-compare])
	WI_INCLUDE_WARNING_FLAG([-Wstrict-prototypes])
	WI_INCLUDE_WARNING_FLAG([-Wmissing-prototypes])
	WI_INCLUDE_WARNING_FLAG([-Wmissing-declarations])
	WI_INCLUDE_WARNING_FLAG([-Wredundant-decls])
	WI_INCLUDE_WARNING_FLAG([-Wno-long-double])

	AC_MSG_RESULT([$WARNFLAGS])
else
	AC_MSG_RESULT([none])
fi


# Check for pthreads support
AC_ARG_ENABLE([pthreads], AC_HELP_STRING([--enable-pthreads], [enable pthreads support]))


# Check for OpenSSL support
AC_ARG_ENABLE([ssl], AC_HELP_STRING([--enable-ssl], [enable OpenSSL support]))


# Check for termcap support
AC_ARG_ENABLE([termcap], AC_HELP_STRING([--enable-termcap], [enable termcap support]))


# Check for iconv support
AC_ARG_ENABLE([iconv], AC_HELP_STRING([--enable-iconv], [enable iconv support]))


# Check for libxml2 support
AC_ARG_ENABLE([libxml2], AC_HELP_STRING([--enable-libxml2], [enable libxml2 support]))


# Check for sqlite3 support
AC_ARG_ENABLE([sqlite3], AC_HELP_STRING([--enable-sqlite3], [enable sqlite3 support]))


# Check for P7 support
AC_ARG_ENABLE([p7], AC_HELP_STRING([--enable-p7], [enable P7 support]))


# Check for object directory name
AC_ARG_WITH([objdir])

if test -n "$with_objdir"; then
	AC_SUBST([objdir], ["$with_objdir"])
else
	AC_SUBST([objdir], ['obj'])
fi


# Check for run directory name
AC_ARG_WITH([rundir])

if test -n "$with_rundir"; then
	AC_SUBST([rundir], ["$with_rundir"])
else
	AC_SUBST([rundir], ['run'])
fi


# Check for maintainer mode
AC_ARG_ENABLE([maintainer_mode])

if test -n "$enable_maintainer_mode"; then
	AC_SUBST([WI_MAINTAINER], [1])
else
	AC_SUBST([WI_MAINTAINER], [0])
fi


######################################################################
# Checks for additional paths

WI_INCLUDE_EXTRA_INCLUDE_PATHS
WI_INCLUDE_EXTRA_LIBRARY_PATHS


#######################################################################
# Checks for libraries

WI_INCLUDE_LIBWIRED_LIBRARIES

if test -n "$enable_pthreads"; then
	WI_INCLUDE_PTHREADS
fi

if test -n "$enable_ssl"; then
	WI_INCLUDE_OPENSSL_LIBRARIES
fi

if test -n "$enable_termcap"; then
	WI_INCLUDE_TERMCAP_LIBRARY
fi

if test -n "$enable_iconv"; then
	WI_INCLUDE_ICONV_LIBRARY
fi

if test -n "$enable_libxml2"; then
	WI_INCLUDE_LIBXML2_LIBRARY
fi

if test -n "$enable_sqlite3"; then
	WI_INCLUDE_SQLITE3_LIBRARY
fi

if test -n "$enable_p7"; then
	WI_INCLUDE_P7_LIBRARIES
fi


# Check for glibc (Linux)
AC_MSG_CHECKING([for glibc])
AC_COMPILE_IFELSE([AC_LANG_SOURCE([
	#include <features.h>
	#ifndef __GLIBC__
	chokeme
	#endif
])], [
	AC_DEFINE([HAVE_GLIBC], [1], [Define to 1 if you have glibc.])
	AC_DEFINE([_GNU_SOURCE], [1], [Define to 1 if you have glibc.])
	AC_MSG_RESULT([yes])
], [
	AC_MSG_RESULT([no])
])


# Check if the sockaddr structs have length members
AC_CHECK_MEMBERS([struct sockaddr.sa_len, struct sockaddr_in.sin_len, struct sockaddr_in6.sin6_len], [], [], [
	#include <sys/types.h>
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <netdb.h>
])


# Check if syslog has facilitynames
AC_CHECK_DECL([facilitynames], [
	AC_DEFINE([HAVE_SYSLOG_FACILITYNAMES], [1], [Define to 1 if you have the declartion of 'facilitynames' and to 0 if you don't.])
], [], [
	#include <stdlib.h>
	#define SYSLOG_NAMES
	#include <syslog.h>
])


# Check if DIR structs have dirfd member
AC_CHECK_MEMBERS([DIR.d_fd, DIR.dd_fd], [], [], [
	#include <sys/types.h>
	#include <dirent.h>
])


# Check if stat struct has st_birthtime member
AC_CHECK_MEMBERS([struct stat.st_birthtime, struct stat64.st_birthtime], [], [], [
	#define _DARWIN_USE_64_BIT_INODE
	#include <sys/types.h>
	#include <sys/stat.h>
])


#######################################################################
# Checks for header files

AC_CHECK_HEADERS([ \
	mach-o/arch.h \
	machine/param.h \
	sys/attr.h \
	sys/event.h \
	sys/inotify.h \
	sys/sockio.h \
	sys/statfs.h \
	sys/statvfs.h \
	sys/sysctl.h \
	sys/systeminfo.h \
	netinet/in_systm.h \
	netinet/ip.h \
	inotifytools/inotify.h \
	getopt.h \
	ifaddrs.h \
	net/if_dl.h \
	paths.h \
	execinfo.h \
], [], [], [
	#include <sys/types.h>
])


#######################################################################
# Checks for typedefs, structures, and compiler characteristics

AC_CHECK_DECLS([optreset])
AC_SYS_LARGEFILE
AC_CHECK_TYPES([intmax_t])
AC_CHECK_TYPES([ptrdiff_t])
AC_DEFINE([_DARWIN_USE_64_BIT_INODE], [1], [64-bit ino_t on Darwin])


#######################################################################
# Checks for library functions

AC_FUNC_FSEEKO
AC_CHECK_FUNCS([ \
	MDItemCreate \
	NXGetLocalArchInfo \
	backtrace \
	dirfd \
	getifaddrs \
	getpagesize \
	pthread_attr_setschedpolicy \
	qsort_r \
	sched_get_priority_max \
	sched_get_priority_min \
	setproctitle \
	sqlite3_extended_errcode \
	sqlite3_prepare_v2 \
	srandom \
	stat64 \
	statvfs \
	strcasestr \
	strlcat \
	strlcpy \
	strsep \
	sysinfo \
	timegm \
	vasprintf \
	vfprintf \
])


#######################################################################
# Output

AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([p7/examples/Makefile])

AC_OUTPUT


#######################################################################
# Print summary

if test -n "$enable_pthreads"; then enable_pthreads_string=yes; else enable_pthreads_string=no; fi
if test -n "$enable_ssl"; then enable_ssl_string=yes; else enable_ssl_string=no; fi
if test -n "$enable_termcap"; then enable_termcap_string=yes; else enable_termcap_string=no; fi
if test -n "$enable_iconv"; then enable_iconv_string=yes; else enable_iconv_string=no; fi
if test -n "$enable_libxml2"; then enable_libxml2_string=yes; else enable_libxml2_string=no; fi
if test -n "$enable_sqlite3"; then enable_sqlite3_string=yes; else enable_sqlite3_string=no; fi
if test -n "$enable_p7"; then enable_p7_string=yes; else enable_p7_string=no; fi

echo ""
echo "libwired has been configured with the following options:"

echo ""
echo "    pthreads support: $enable_pthreads_string"
echo "     OpenSSL support: $enable_ssl_string"
echo "     termcap support: $enable_termcap_string"
echo "       iconv support: $enable_iconv_string"
echo "     libxml2 support: $enable_libxml2_string"
echo "     sqlite3 support: $enable_sqlite3_string"
echo "          P7 support: $enable_p7_string"

echo ""
echo "                Host: ${host}"
echo "            Compiler: ${CC}"
echo "      Compiler flags: ${CFLAGS}"
echo "  Preprocessor flags: ${CPPFLAGS}"
echo "        Linker flags: ${LDFLAGS}"
echo "           Libraries: ${LIBS}"

echo ""
