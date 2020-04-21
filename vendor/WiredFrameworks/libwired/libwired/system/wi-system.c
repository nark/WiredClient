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

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <errno.h>

#ifdef HAVE_OPENSSL_SHA_H
#include <openssl/rand.h>
#endif

#ifdef HAVE_PATHS_H
#include <paths.h>
#endif

#ifdef HAVE_MACHINE_PARAM_H
#include <machine/param.h>
#endif

#ifdef HAVE_EXECINFO_H
#include <execinfo.h>
#endif

#include <wired/wi-assert.h>
#include <wired/wi-base.h>
#include <wired/wi-log.h>
#include <wired/wi-runtime.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

void wi_switch_user(uid_t uid, gid_t gid) {
	struct passwd	*user;
	
	if(wi_log_path) {
		if(chown(wi_string_cstring(wi_log_path), uid, gid) < 0) {
			wi_log_error(WI_STR("Could not change owner of %@: %s"),
				wi_log_path, strerror(errno));
		}
	}
	
	if(gid != getegid()) {
		user = getpwuid(uid);
		
		if(user) {
			if(initgroups(user->pw_name, gid) < 0) {
				wi_log_error(WI_STR("Could not set group privileges: %s"),
					strerror(errno));
			}
		}
			
		if(setgid(gid) < 0) {
			wi_log_error(WI_STR("Could not drop group privileges: %s"),
				strerror(errno));
		}
	}

	if(uid != geteuid()) {
		if(setuid(uid) < 0) {
			wi_log_error(WI_STR("Could not drop user privileges: %s"),
				strerror(errno));
		}
	}
}



wi_uinteger_t wi_user_id(void) {
	return geteuid();
}



wi_string_t * wi_user_name(void) {
	struct passwd	*user;
	
	user = getpwuid(wi_user_id());
	
	if(!user)
		return NULL;
	
	return wi_string_with_cstring(user->pw_name);
}



wi_string_t * wi_user_home(void) {
	struct passwd	*user;
	
	user = getpwuid(wi_user_id());
	
	if(!user)
		return NULL;
	
	return wi_string_with_cstring(user->pw_dir);
}



wi_uinteger_t wi_group_id(void) {
	return getegid();
}



wi_string_t * wi_group_name(void) {
	struct group	*group;
	
	group = getgrgid(wi_group_id());
	
	if(!group)
		return NULL;
	
	return wi_string_with_cstring(group->gr_name);
}



#pragma mark -

wi_uinteger_t wi_page_size(void) {
#if defined(HAVE_GETPAGESIZE)
	return getpagesize();
#elif defined(PAGESIZE)
	return PAGESIZE;
#elif defined(EXEC_PAGESIZE)
	return EXEC_PAGESIZE;
#elif defined(NBPG)
#ifdef CLSIZE
	return NBPG * CLSIZE
#else
	return NBPG;
#endif
#elif defined(NBPC)
	return NBPC;
#else
	return 4096;
#endif
}



#pragma mark -

pid_t wi_fork(void) {
	pid_t		pid;
	
	pid = fork();
	
	if(pid < 0)
		wi_error_set_errno(errno);
	
	return pid;
}



wi_boolean_t wi_execv(wi_string_t *program, wi_array_t *arguments) {
	wi_mutable_array_t		*argv;
	const char				**xargv;
	
	argv = wi_mutable_copy(arguments);
	
	if(wi_array_count(argv) == 0)
		wi_mutable_array_add_data(argv, program);
	else
		wi_mutable_array_insert_data_at_index(argv, program, 0);
	
	xargv = wi_array_create_argv(argv);
	
	if(execv(xargv[0], (char * const *) xargv) < 0) {
		wi_error_set_errno(errno);
		
		wi_array_destroy_argv(wi_array_count(argv), xargv);
		wi_release(argv);
	
		return false;
	}
	
	return true;
}


void * wi_malloc(size_t size) {
	void		*pointer;
	
	pointer = calloc(1, size);
	
	if(pointer == NULL)
		wi_crash();

	return pointer;
}



void * wi_realloc(void *pointer, size_t size) {
	void		*newpointer;
	
	newpointer = realloc(pointer, size);
	
	if(newpointer == NULL)
		wi_crash();
	
	return newpointer;
}



void wi_free(void *pointer) {
	if(pointer)
		free(pointer);
}



#pragma mark -

wi_array_t * wi_backtrace(void) {
#ifdef HAVE_BACKTRACE
	wi_mutable_array_t	*array;
	void				*callstack[128];
	char				**symbols;
	int					i, frames;
	
	frames		= backtrace(callstack, sizeof(callstack));
	symbols		= backtrace_symbols(callstack, frames);
	array		= wi_array_init_with_capacity(wi_mutable_array_alloc(), frames);
	
	for(i = 0; i < frames; i++)
		wi_mutable_array_add_data(array, wi_string_with_cstring(symbols[i]));
	
	free(symbols);
	
	wi_runtime_make_immutable(array);
	
	return wi_autorelease(array);
#else
	return NULL;
#endif
}



#pragma mark -

wi_string_t * wi_getenv(wi_string_t *name) {
	char			*value;
	
	value = getenv(wi_string_cstring(name));
	
	if(!value)
		return NULL;
	
	return wi_string_with_cstring(value);
}



#pragma mark -

void wi_getopt_reset(void) {
#ifdef __GLIBC__
	optind = 0;
#else
	optind = 1;
#endif

#if HAVE_DECL_OPTRESET
	optreset = 1;
#endif
}
