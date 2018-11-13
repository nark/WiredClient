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

#ifndef WI_SYSTEM_H
#define WI_SYSTEM_H 1

#include <sys/types.h>
#include <unistd.h>
#include <pwd.h>
#include <grp.h>
#include <wired/wi-base.h>

WI_EXPORT void					wi_switch_user(uid_t, gid_t);
WI_EXPORT wi_uinteger_t			wi_user_id(void);
WI_EXPORT wi_string_t *			wi_user_name(void);
WI_EXPORT wi_string_t *			wi_user_home(void);
WI_EXPORT wi_uinteger_t			wi_group_id(void);
WI_EXPORT wi_string_t *			wi_group_name(void);

WI_EXPORT wi_uinteger_t			wi_page_size(void);

WI_EXPORT pid_t					wi_fork(void);
WI_EXPORT wi_boolean_t			wi_execv(wi_string_t *, wi_array_t *);

WI_EXPORT void *				wi_malloc(size_t);
WI_EXPORT void *				wi_realloc(void *, size_t);
WI_EXPORT void					wi_free(void *);

WI_EXPORT wi_array_t *			wi_backtrace(void);

WI_EXPORT wi_string_t *			wi_getenv(wi_string_t *);

WI_EXPORT void					wi_getopt_reset(void);

#endif /* WI_SYSTEM_H */
