/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#ifdef HAVE_SYS_EVENT_H
#include <sys/event.h>
#endif

#ifdef HAVE_SYS_INOTIFY_H
#include <sys/inotify.h>
#endif

#ifdef HAVE_INOTIFYTOOLS_INOTIFY_H
#include <inotifytools/inotify.h>
#endif

#include <wired/wi-error.h>
#include <wired/wi-fsevents.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>

#if defined(HAVE_SYS_EVENT_H)
#define _WI_FSEVENTS_KQUEUE				1
#define _WI_FSEVENTS_ANY				1
#elif defined(HAVE_SYS_INOTIFY_H) || defined(HAVE_INOTIFYTOOLS_INOTIFY_H)
#define _WI_FSEVENTS_INOTIFY			1
#define _WI_FSEVENTS_ANY				1
#endif

#ifdef _WI_FSEVENTS_INOTIFY
#define _WI_FSEVENTS_INOTIFY_MASK		(IN_CREATE | IN_DELETE | IN_MOVE)
#endif


struct _wi_fsevents {
	wi_runtime_base_t					base;
	
#if defined(_WI_FSEVENTS_KQUEUE)
	int									kqueue;
#elif defined(_WI_FSEVENTS_INOTIFY)
	int									inotify;
#endif
	
	wi_fsevents_callback_t				*callback;
	wi_mutable_set_t					*paths;
	wi_mutable_dictionary_t				*fds_for_paths;

#ifdef _WI_FSEVENTS_INOTIFY
	wi_mutable_dictionary_t				*paths_for_fds;
#endif
};


static void								_wi_fsevents_dealloc(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_fsevents_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_fsevents_runtime_class = {
	"wi_fsevents_t",
	_wi_fsevents_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};



void wi_fsevents_register(void) {
	_wi_fsevents_runtime_id = wi_runtime_register_class(&_wi_fsevents_runtime_class);
}



void wi_fsevents_initialize(void) {
}



#pragma mark -	

wi_runtime_id_t wi_fsevents_runtime_id(void) {
	return _wi_fsevents_runtime_id;
}



#pragma mark -

wi_fsevents_t * wi_fsevents_alloc(void) {
	return wi_runtime_create_instance(_wi_fsevents_runtime_id, sizeof(wi_fsevents_t));
}



wi_fsevents_t * wi_fsevents_init(wi_fsevents_t *fsevents) {
#if defined(_WI_FSEVENTS_KQUEUE)
	fsevents->kqueue = kqueue();
	
	if(fsevents->kqueue < 0) {
		wi_error_set_errno(errno);
		
		wi_release(fsevents);
		
		return NULL;
	}
#elif defined(_WI_FSEVENTS_INOTIFY)
	fsevents->inotify = inotify_init();

	if(fsevents->inotify < 0) {
		wi_error_set_errno(errno);
		
		wi_release(fsevents);
		
		return NULL;
	}
#else
	wi_error_set_libwired_error(WI_ERROR_FSEVENTS_NOTSUPP);
	
	wi_release(fsevents);
	
	return NULL;
#endif
	
	fsevents->paths			= wi_set_init_with_capacity(wi_mutable_set_alloc(), 0, true);
	fsevents->fds_for_paths	= wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(), 0,
		wi_dictionary_default_key_callbacks, wi_dictionary_null_value_callbacks);

#ifdef _WI_FSEVENTS_INOTIFY
	fsevents->paths_for_fds	= wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(), 0,
		wi_dictionary_null_key_callbacks, wi_dictionary_default_value_callbacks);
#endif
	
	return fsevents;
}



static void _wi_fsevents_dealloc(wi_runtime_instance_t *instance) {
	wi_fsevents_t		*fsevents = instance;
	
	wi_fsevents_remove_all_paths(fsevents);
	
#if defined(_WI_FSEVENTS_KQUEUE)
	close(fsevents->kqueue);
#elif defined(_WI_FSEVENTS_INOTIFY)
	close(fsevents->inotify);
#endif
	
	wi_release(fsevents->paths);
	wi_release(fsevents->fds_for_paths);

#ifdef _WI_FSEVENTS_INOTIFY
	wi_release(fsevents->paths_for_fds);
#endif
}



#pragma mark -

wi_boolean_t wi_fsevents_run_with_timeout(wi_fsevents_t *fsevents, wi_time_interval_t timeout) {
#if defined(_WI_FSEVENTS_KQUEUE)
	struct kevent			event;
	struct timespec			ts;
	int						result;
#elif defined(_WI_FSEVENTS_INOTIFY)
	wi_string_t				*path;
	struct inotify_event	*event;
	struct timeval			tv;
	char					buffer[1024];
	fd_set					rfds;
	ssize_t					i, result;
	int						state;
#endif
	
#if defined(_WI_FSEVENTS_KQUEUE)
	do {
		ts = wi_dtots(timeout);
		result = kevent(fsevents->kqueue, NULL, 0, &event, 1, (timeout > 0.0) ? &ts : NULL);
		
		if(result < 0) {
			wi_error_set_errno(errno);
			
			return false;
		}
		else if(result > 0) {
			if(event.filter == EVFILT_VNODE) {
				if(fsevents->callback)
					(*fsevents->callback)(event.udata);
			}
		}
	} while(timeout == 0.0);
#elif defined(_WI_FSEVENTS_INOTIFY)
	do {
		FD_ZERO(&rfds);
		FD_SET(fsevents->inotify, &rfds);

		tv = wi_dtotv(timeout);
		state = select(fsevents->inotify + 1, &rfds, NULL, NULL, (timeout > 0.0) ? &tv : NULL);

		if(state < 0) {
			wi_error_set_errno(errno);

			return false;
		}
		else if(state > 0) {
			result = read(fsevents->inotify, buffer, sizeof(buffer));

			if(result < 0) {
				wi_error_set_errno(errno);

				return false;
			}
			else if(result > 0) {
				i = 0;

				while(i < result) {
					event = (struct inotify_event *) &buffer[i];
					path = wi_dictionary_data_for_key(fsevents->paths_for_fds, (void *) (intptr_t) event->wd);

					if(_WI_FSEVENTS_INOTIFY_MASK & event->mask && path)
						(*fsevents->callback)(path);

					i += sizeof(*event) + event->len;
				}
			}
		}
	} while(timeout == 0.0);
#endif
	
	return true;
}



#pragma mark -

void wi_fsevents_set_callback(wi_fsevents_t *fsevents, wi_fsevents_callback_t *callback) {
	fsevents->callback = callback;
}



#pragma mark -

wi_boolean_t wi_fsevents_add_path(wi_fsevents_t *fsevents, wi_string_t *path) {
#if defined(_WI_FSEVENTS_KQUEUE)
	struct kevent	ev;
	int				fd;
#elif defined(_WI_FSEVENTS_INOTIFY)
	int				fd;
#endif
	
#if defined(_WI_FSEVENTS_KQUEUE)
	if(!wi_set_contains_data(fsevents->paths, path)) {
		fd = open(wi_string_cstring(path),
#ifdef O_EVTONLY
				  O_EVTONLY,
#else
				  O_RDONLY,
#endif
				  0);
		
		if(fd < 0) {
			wi_error_set_errno(errno);
			
			return false;
		}
		
		EV_SET(&ev, fd, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, NOTE_WRITE | NOTE_DELETE | NOTE_RENAME, 0, path);
		
		if(kevent(fsevents->kqueue, &ev, 1, NULL, 0, NULL) < 0) {
			wi_error_set_errno(errno);
			
			close(fd);
			
			return false;
		}
		
		wi_mutable_dictionary_set_data_for_key(fsevents->fds_for_paths, (void *) (intptr_t) fd, path);
	}
	
	wi_mutable_set_add_data(fsevents->paths, path);
#elif defined(_WI_FSEVENTS_INOTIFY)
	if(!wi_set_contains_data(fsevents->paths, path)) {
		fd = inotify_add_watch(fsevents->inotify, wi_string_cstring(path), _WI_FSEVENTS_INOTIFY_MASK);

		if(fd < 0) {
			wi_error_set_errno(errno);
			
			return false;
		}

		wi_mutable_dictionary_set_data_for_key(fsevents->fds_for_paths, (void *) (intptr_t) fd, path);
		wi_mutable_dictionary_set_data_for_key(fsevents->paths_for_fds, path, (void *) (intptr_t) fd);
	}

	wi_mutable_set_add_data(fsevents->paths, path);
#endif
	
	return true;
}



void wi_fsevents_remove_path(wi_fsevents_t *fsevents, wi_string_t *path) {
#ifdef _WI_FSEVENTS_ANY
	int			fd;
	
	if(wi_set_count_for_data(fsevents->paths, path) == 1) {
		fd = (int) (intptr_t) wi_dictionary_data_for_key(fsevents->fds_for_paths, path);
		
		if(fd == 0)
			return;
		
#if defined(_WI_FSEVENTS_KQUEUE)
		close(fd);
#elif defined(_WI_FSEVENTS_INOTIFY)
		inotify_rm_watch(fsevents->inotify, fd);

		wi_mutable_dictionary_remove_data_for_key(fsevents->fds_for_paths, (void *) (intptr_t) path);
#endif
		
		wi_mutable_dictionary_remove_data_for_key(fsevents->fds_for_paths, path);
	}
	
	wi_mutable_set_remove_data(fsevents->paths, path);
#endif
}



void wi_fsevents_remove_all_paths(wi_fsevents_t *fsevents) {
#ifdef _WI_FSEVENTS_ANY
	wi_enumerator_t		*enumerator;
	int					fd;
	
	enumerator = wi_dictionary_data_enumerator(fsevents->fds_for_paths);
	
	while((fd = (int) (intptr_t) wi_enumerator_next_data(enumerator))) {
#if defined(_WI_FSEVENTS_KQUEUE)
		close(fd);
#elif defined(_WI_FSEVENTS_INOTIFY)
		inotify_rm_watch(fsevents->inotify, fd);
#endif
	}
	
	wi_mutable_set_remove_all_data(fsevents->paths);
	wi_mutable_dictionary_remove_all_data(fsevents->fds_for_paths);

#ifdef _WI_FSEVENTS_INOTIFY
	wi_mutable_dictionary_remove_all_data(fsevents->paths_for_fds);
#endif
#endif
}
