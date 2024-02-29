/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
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
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include <wired/wi-array.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-task.h>

struct _wi_task {
	wi_runtime_base_t					base;
	
	wi_string_t							*launch_path;
	wi_mutable_array_t					*arguments;
	
	pid_t								pid;
	wi_boolean_t						running;
};

static void								_wi_task_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_task_description(wi_runtime_instance_t *);

static wi_runtime_id_t					_wi_task_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_task_runtime_class = {
	"wi_task_t",
	_wi_task_dealloc,
	NULL,
	NULL,
	_wi_task_description,
	NULL
};



void wi_task_register(void) {
	_wi_task_runtime_id = wi_runtime_register_class(&_wi_task_runtime_class);
}



void wi_task_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_task_runtime_id(void) {
	return _wi_task_runtime_id;
}



#pragma mark -

wi_task_t * wi_task_launched_task_with_path(wi_string_t *path, wi_array_t *arguments) {
	wi_task_t		*task;
	
	task = wi_task_init(wi_task_alloc());
	wi_task_set_launch_path(task, path);
	wi_task_set_arguments(task, arguments);
	
	wi_task_launch(task);
	
	return wi_autorelease(task);
}



#pragma mark -

wi_task_t * wi_task_alloc(void) {
	return wi_runtime_create_instance(_wi_task_runtime_id, sizeof(wi_task_t));
}



wi_task_t * wi_task_init(wi_task_t *task) {
	return task;
}



static void _wi_task_dealloc(wi_runtime_instance_t *instance) {
	wi_task_t		*task = instance;
	int				status;
	
	if(task->running)
		(void) waitpid(task->pid, &status, WNOHANG);
	
	wi_release(task->launch_path);
	wi_release(task->arguments);
}



static wi_string_t * _wi_task_description(wi_runtime_instance_t *instance) {
	wi_task_t		*task = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{path = %@, arguments = %@}"),
		wi_runtime_class_name(task),
		task,
		wi_task_launch_path(task),
		wi_task_arguments(task));
}



#pragma mark -

void wi_task_set_launch_path(wi_task_t *task, wi_string_t *launch_path) {
	wi_retain(launch_path);
	wi_release(task->launch_path);
	
	task->launch_path = launch_path;
}



wi_string_t * wi_task_launch_path(wi_task_t *task) {
	return task->launch_path;
}



void wi_task_set_arguments(wi_task_t *task, wi_array_t *arguments) {
	wi_release(task->arguments);
	task->arguments = wi_mutable_copy(arguments);
}



wi_array_t * wi_task_arguments(wi_task_t *task) {
	return task->arguments;
}



#pragma mark -

wi_boolean_t wi_task_launch(wi_task_t *task) {
	const char		**argv;
	const char		*launch_path;
	pid_t			pid;
	int				i, count;
	
	pid = fork();
	
	if(pid < 0) {
		wi_error_set_errno(errno);
		
		return false;
	}
	
	if(pid == 0) {
		count = getdtablesize();
		
		for(i = 3; i < count; i++)
			(void) close(i);
		
		launch_path = wi_string_cstring(task->launch_path);
		wi_mutable_array_insert_data_at_index(task->arguments, task->launch_path, 0);
		argv = wi_array_create_argv(task->arguments);
		
		if(execv(launch_path, (char * const *) argv) < 0) {
			printf("execve: %s: %s\n", launch_path, strerror(errno));
			
			exit(1);
		}
	} else {
		task->pid = pid;
		task->running = true;
	}
	
	return true;
}



wi_integer_t wi_task_wait_until_exit(wi_task_t *task) {
	int		status;
	
	if(waitpid(task->pid, &status, 0) < 0) {
		wi_error_set_errno(errno);
		
		return -1;
	}
	
	task->running = false;
	
	return status;
}
