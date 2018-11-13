/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
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

#include <sys/param.h>
#include <sys/types.h>
#include <sys/utsname.h>

#ifdef HAVE_SYS_SYSCTL_H
#include <sys/sysctl.h>
#endif

#ifdef HAVE_SYS_SYSTEMINFO_H
#include <sys/systeminfo.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <netdb.h>

#ifdef HAVE_MACH_O_ARCH_H
#include <mach-o/arch.h>
#endif

#include <wired/wi-array.h>
#include <wired/wi-compat.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-process.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

struct _wi_process {
	wi_runtime_base_t					base;
	
	wi_string_t							*name;
	wi_string_t							*path;
	wi_array_t							*arguments;
	
	wi_string_t							*os_name;
	wi_string_t							*os_release;
	wi_string_t							*arch;
};


static wi_process_t *					_wi_process_alloc(void);
static wi_process_t *					_wi_process_init_with_argv(wi_process_t *, int, const char **);
static void								_wi_process_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_process_description(wi_runtime_instance_t *);


static wi_process_t						*_wi_process_shared_process;

static wi_runtime_id_t					_wi_process_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_process_runtime_class = {
	"wi_process_t",
	_wi_process_dealloc,
	NULL,
	NULL,
	_wi_process_description,
	NULL
};



void wi_process_register(void) {
	_wi_process_runtime_id = wi_runtime_register_class(&_wi_process_runtime_class);
}



void wi_process_initialize(void) {
}



void wi_process_load(int argc, const char **argv) {
	_wi_process_shared_process = _wi_process_init_with_argv(_wi_process_alloc(), argc, argv);
}



#pragma mark -

wi_runtime_id_t wi_process_runtime_id(void) {
	return _wi_process_runtime_id;
}



#pragma mark -

wi_process_t * wi_process(void) {
	return _wi_process_shared_process;
}



#pragma mark -

static wi_process_t * _wi_process_alloc(void) {
	return wi_runtime_create_instance(_wi_process_runtime_id, sizeof(wi_process_t));
}



static wi_process_t * _wi_process_init_with_argv(wi_process_t *process, int argc, const char **argv) {
	wi_array_t			*array;
	wi_string_t			*string;
	struct utsname		name;
#if defined(HAVE_NXGETLOCALARCHINFO)
	const NXArchInfo	*archinfo;
	cpu_type_t			cputype;
	size_t				cputypesize;
#elif defined(HAVE_SYSINFO) && defined(SI_ARCHITECTURE)
	char				buffer[SYS_NMLN];
#endif

	
	array = wi_array_init_with_argv(wi_array_alloc(), argc, argv);
	
	string = wi_array_first_data(array);
	
	if(string) {
		process->path = wi_retain(string);
		process->name = wi_retain(wi_string_last_path_component(process->path));
	} else {
		process->path = wi_retain(WI_STR("unknown"));
		process->name = wi_retain(process->path);
	}
	
	if(wi_array_count(array) <= 1)
		process->arguments = wi_array_init(wi_array_alloc());
	else
		process->arguments = wi_retain(wi_array_subarray_with_range(array, wi_make_range(1, wi_array_count(array) - 1)));
	
	wi_release(array);
	
	uname(&name);
	
	process->os_name = wi_string_init_with_cstring(wi_string_alloc(), name.sysname);
	process->os_release = wi_string_init_with_cstring(wi_string_alloc(), name.release);

#if defined(HAVE_NXGETLOCALARCHINFO)
	cputypesize = sizeof(cputype);
	
	if(sysctlbyname("sysctl.proc_cputype", &cputype, &cputypesize, NULL, 0) < 0)
		cputype = NXGetLocalArchInfo()->cputype;
	
	archinfo = NXGetArchInfoFromCpuType(cputype, CPU_SUBTYPE_MULTIPLE);
	
	if(archinfo)
		process->arch = wi_string_init_with_cstring(wi_string_alloc(), archinfo->name);
#elif defined(HAVE_SYSINFO) && defined(SI_ARCHITECTURE)
	if(sysinfo(SI_ARCHITECTURE, buffer, sizeof(buffer)) >= 0)
		process->arch = wi_string_init_with_cstring(wi_string_alloc(), buffer);
#endif

	if(!process->arch)
		process->arch = wi_string_init_with_cstring(wi_string_alloc(), name.machine);

	return process;
}



static void _wi_process_dealloc(wi_runtime_instance_t *instance) {
	wi_process_t		*process = instance;
	
	wi_release(process->name);
	wi_release(process->path);
	wi_release(process->arguments);

	wi_release(process->os_name);
	wi_release(process->os_release);
	wi_release(process->arch);
}



static wi_string_t * _wi_process_description(wi_runtime_instance_t *instance) {
	wi_process_t		*process = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{name = %@, arguments = %@}"),
		wi_runtime_class_name(process),
		process,
		process->name,
		process->arguments);
}



#pragma mark -

void wi_process_set_name(wi_process_t *process, wi_string_t *name) {
#ifdef HAVE_SETPROCTITLE
	setproctitle("%s", wi_string_cstring(process->name));
#endif
}



wi_string_t * wi_process_name(wi_process_t *process) {
	return process->name;
}



wi_string_t * wi_process_path(wi_process_t *process) {
	return process->path;
}



wi_array_t * wi_process_arguments(wi_process_t *process) {
	return process->arguments;
}



wi_boolean_t wi_process_set_hostname(wi_process_t *process, wi_string_t *hostname) {
	if(sethostname((char *) wi_string_cstring(hostname), (int)wi_string_length(hostname))) {
		wi_error_set_errno(errno);
		
		return false;
	}
	
	return true;
}



wi_string_t * wi_process_hostname(wi_process_t *process) {
	char	hostname[NI_MAXHOST];
	
	if(gethostname(hostname, sizeof(hostname)) < 0)
		return NULL;
	
	return wi_string_with_cstring(hostname);
}



#pragma mark -

wi_string_t * wi_process_os_name(wi_process_t *process) {
	return process->os_name;
}



wi_string_t * wi_process_os_release(wi_process_t *process) {
	return process->os_release;
}



wi_string_t * wi_process_os_arch(wi_process_t *process) {
	return process->arch;
}
