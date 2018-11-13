/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WI_COMPAT_H
#define WI_COMPAT_H 1

#include <sys/types.h>
#include <stdarg.h>
#include <stdio.h>
#include <dirent.h>
#include <time.h>
#include <wired/wi-base.h>

WI_EXPORT char *					wi_strsep(char **, const char *);
WI_EXPORT char *					wi_strnstr(const char *, const char *, size_t);
WI_EXPORT char *					wi_strcasestr(const char *, const char *);
WI_EXPORT char *					wi_strncasestr(const char *, const char *, size_t);
WI_EXPORT char *					wi_strrnstr(const char *, const char *, size_t);
WI_EXPORT char *					wi_strrncasestr(const char *, const char *, size_t);
WI_EXPORT size_t					wi_strlcat(char *, const char *, size_t);
WI_EXPORT size_t					wi_strlcpy(char *, const char *, size_t);
WI_EXPORT int						wi_asprintf(char **, const char *, ...);
WI_EXPORT int						wi_vasprintf(char **, const char *, va_list);

WI_EXPORT FILE *					wi_tmpfile(void);

WI_EXPORT int						wi_dirfd(DIR *);

WI_EXPORT time_t					wi_timegm(struct tm *);

#endif /* WI_COMPAT_H */
