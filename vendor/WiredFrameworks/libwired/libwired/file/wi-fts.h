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

#ifndef WI_FTS_H
#define WI_FTS_H 1

#include <sys/types.h>

/*      $OpenBSD: fts.h,v 1.11 2005/06/17 20:36:55 millert Exp $        */
/*      $NetBSD: fts.h,v 1.5 1994/12/28 01:41:50 mycroft Exp $        */

/*
 * Copyright (c) 1989, 1993
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
 *
 *      @(#)fts.h        8.3 (Berkeley) 8/14/94
 */

typedef struct _wi_fts {
	struct _wi_ftsent			*fts_cur;
	struct _wi_ftsent			*fts_child;
	struct _wi_ftsent			**fts_array;
	dev_t						fts_dev;
	char						*fts_path;
	int							fts_rfd;
	size_t						fts_pathlen;
	int							fts_nitems;
	int							(*fts_compar)(const void *, const void *);
	
#define WI_FTS_COMFOLLOW		0x0001
#define WI_FTS_LOGICAL			0x0002
#define WI_FTS_NOCHDIR			0x0004
#define WI_FTS_NOSTAT			0x0008
#define WI_FTS_PHYSICAL			0x0010
#define WI_FTS_SEEDOT			0x0020
#define WI_FTS_XDEV				0x0040
#define WI_FTS_OPTIONMASK		0x00ff
	
#define WI_FTS_NAMEONLY			0x1000
#define WI_FTS_STOP				0x2000
	int							fts_options;
} WI_FTS;

typedef struct _wi_ftsent {
	struct _wi_ftsent			*fts_cycle;
	struct _wi_ftsent			*fts_parent;
	struct _wi_ftsent			*fts_link;
	long						fts_number;
	void						*fts_pointer;
	char						*fts_accpath;
	char						*fts_path;
	int							fts_errno;
	int							fts_symfd;
	size_t						fts_pathlen;
	size_t						fts_namelen;
	
	ino_t						fts_ino;
	dev_t						fts_dev;
	nlink_t						fts_nlink;
	
#define WI_FTS_ROOTPARENTLEVEL	-1
#define WI_FTS_ROOTLEVEL		0
	short						fts_level;
	
#define WI_FTS_D				1
#define WI_FTS_DC				2
#define WI_FTS_DEFAULT			3
#define WI_FTS_DNR				4
#define WI_FTS_DOT				5
#define WI_FTS_DP				6
#define WI_FTS_ERR				7
#define WI_FTS_F				8
#define WI_FTS_INIT				9
#define WI_FTS_NS				10
#define WI_FTS_NSOK				11
#define WI_FTS_SL				12
#define WI_FTS_SLNONE			13
	unsigned short				fts_info;
	
#define WI_FTS_DONTCHDIR		0x01
#define WI_FTS_SYMFOLLOW		0x02
	unsigned short				fts_flags;
	
#define WI_FTS_AGAIN			1
#define WI_FTS_FOLLOW			2
#define WI_FTS_NOINSTR			3
#define WI_FTS_SKIP				4
	unsigned short				fts_instr;
	
	struct stat					*fts_statp;
	char						fts_name[1];
} WI_FTSENT;


WI_FTS *						wi_fts_open(char * const *, int, int (*)(const WI_FTSENT **, const WI_FTSENT **));
int								wi_fts_close(WI_FTS *);
WI_FTSENT *						wi_fts_read(WI_FTS *);
WI_FTSENT *						wi_fts_children(WI_FTS *, int);
int								wi_fts_set(WI_FTS *, WI_FTSENT *, int);

#endif /* WI_FTS_H_ */
