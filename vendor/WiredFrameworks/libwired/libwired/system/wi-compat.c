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

#include "config.h"

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <dirent.h>
#include <ctype.h>
#include <float.h>
#include <time.h>

#include <wired/wi-compat.h>
#include <wired/wi-file.h>
#include <wired/wi-system.h>

/*      $OpenBSD: strsep.c,v 1.5 2003/06/11 21:08:16 deraadt Exp $        */

/*-
 * Copyright (c) 1990, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

char * wi_strsep(char **stringp, const char *delim) {
	char		*s;
	const char	*spanp;
	int			c, sc;
	char		*tok;

	if((s = *stringp) == NULL)
		return NULL;

	for(tok = s;;) {
		c		= *s++;
		spanp	= delim;

		do {
			if((sc = *spanp++) == c) {
				if(c == 0)
					s = NULL;
				else
					s[-1] = 0;

				*stringp = s;

				return tok;
			}
		} while(sc != 0);
	}
	/* NOTREACHED */
}



/*-
 * Copyright (c) 2001 Mike Barcroft <mike@FreeBSD.org>
 * Copyright (c) 1990, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Chris Torek.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

char * wi_strnstr(const char *s, const char *find, size_t slen) {
	char	c, sc;
	size_t	len;

	if((c = *find++) != '\0') {
		len = strlen(find);
		
		do {
			do {
				if(slen-- < 1 || (sc = *s++) == '\0')
					return NULL;
			} while(sc != c);
			
			if(len > slen)
				return NULL;
		} while(strncmp(s, find, len) != 0);

		s--; 
	}
	return (char *) s;
}



/*-
 * Copyright (c) 1990, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Chris Torek.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

char * wi_strcasestr(const char *s, const char *find) {
	char	c, sc;
	size_t	len;

	if((c = *find++) != '\0') {
		c	= tolower((unsigned char) c);
		len	= strlen(find);

		do {
			do {
				if((sc = *s++) == '\0')
					return NULL;
			} while((char) tolower((unsigned char) sc) != c);
		} while(strncasecmp(s, find, len) != 0);

		s--;
	}

	return (char *) s;
}



char * wi_strncasestr(const char *s, const char *find, size_t slen) {
	char	c, sc;
	size_t	len;

	if((c = *find++) != '\0') {
		c	= tolower((unsigned char) c);
		len	= strlen(find);

		do {
			do {
				if(slen-- < 1 || (sc = *s++) == '\0')
					return NULL;
			} while((char) tolower((unsigned char) sc) != c);

			if(len > slen)
				return NULL;
		} while(strncasecmp(s, find, len) != 0);

		s--;
	}

	return (char *) s;
}



char * wi_strrnstr(const char *s, const char *find, size_t slen) {
	const char	*p;
	size_t		len;

	len = strlen(find);

	for(p = s + slen - 1; p >= s; --p) {
		if(strncmp(p, find, len) == 0)
			return (char *) p;
	}

	return NULL;
}



char * wi_strrncasestr(const char *s, const char *find, size_t slen) {
	const char	*p;
	size_t		len;

	len = strlen(find);

	for(p = s + slen - 1; p >= s; --p) {
		if(strncmp(p, find, len) == 0)
			return (char *) p;
	}

	return NULL;
}



/*	$OpenBSD: strlcat.c,v 1.11 2003/06/17 21:56:24 millert Exp $	*/

/*
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

size_t wi_strlcat(char *dst, const char *src, size_t siz) {
	register char *d		= dst;
	register const char *s	= src;
	register size_t n		= siz;
	size_t					dlen;

	while(n-- != 0 && *d != '\0')
		d++;

	dlen	= d - dst;
	n		= siz - dlen;

	if(n == 0)
		return (dlen + strlen(s));

	while(*s != '\0') {
		if(n != 1) {
			*d++ = *s;
			n--;
		}
		s++;
	}

	*d = '\0';

	return (dlen + (s - src));
}



/*	$OpenBSD: strlcpy.c,v 1.7 2003/04/12 21:56:39 millert Exp $	*/

/*
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND TODD C. MILLER DISCLAIMS ALL
 * WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL TODD C. MILLER BE LIABLE
 * FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

size_t wi_strlcpy(char *dst, const char *src, size_t siz) {
	register char		*d = dst;
	register const char	*s = src;
	register size_t		n = siz;

	if(n != 0 && --n != 0) {
		do {
			if((*d++ = *s++) == 0)
				break;
		} while (--n != 0);
	}

	if(n == 0) {
		if(siz != 0)
			*d = '\0';
		while(*s++)
			;
	}

	return s - src - 1;
}



int wi_asprintf(char **buffer, const char *fmt, ...) {
	va_list		ap;
	int			result;

	va_start(ap, fmt);
	result = wi_vasprintf(buffer, fmt, ap);
	va_end(ap);

	return result;
}



int wi_vasprintf(char **buffer, const char *fmt, va_list ap) {
#ifdef HAVE_VASPRINTF
	return vasprintf(buffer, fmt, ap);
#else 
	FILE    	*tmp;
	char    	*string;
	int    		bytes;

	tmp = wi_tmpfile();

	if(!tmp)
		return -1;

	bytes = vfprintf(tmp, fmt, ap);

	if(bytes < 0) {
		fclose(tmp);

		return -1;
	}

	string = wi_malloc(bytes + 1);

	fseek(tmp, 0, SEEK_SET);
	fread(string, 1, bytes, tmp);
	fclose(tmp);

	string[bytes] = '\0';
	*buffer = string;

	return bytes;
#endif
}



#pragma mark -

FILE * wi_tmpfile(void) {
	char		path[WI_PATH_SIZE];
	int			fd;

#ifdef _PATH_TMP
	snprintf(path, sizeof(path), "%s/%s", _PATH_TMP, "tmp.XXXXXXXXXX");
#else
	snprintf(path, sizeof(path), "/tmp/%s", "tmp.XXXXXXXXXX");
#endif

	fd = mkstemp(path);

	unlink(path);

	return (fd < 0) ? NULL : fdopen(fd, "w+");
}



#pragma mark -

int wi_dirfd(DIR *dir) {
#if defined(HAVE_DIRFD) || defined(dirfd)
	return dirfd(dir);
#elif defined(HAVE_DIR_DD_FD)
	return dir->dd_fd;
#elif defined(HAVE_DIR_D_FD)
	return dir->d_fd;
#else
	return 0;
#endif
}



#pragma mark -

time_t wi_timegm(struct tm *tm) {
#ifdef HAVE_TIMEGM
	return timegm(tm);
#else
	time_t		clock;
	char		*tz;
	
	tz = getenv("TZ");
	
	setenv("TZ", "UTC", 1);
	
	tzset();
	
	clock = mktime(tm);
	
	if(tz)
		setenv("TZ", tz, 1);
	else
		unsetenv("TZ");
	
	tzset();
	
	return clock;
#endif
}
