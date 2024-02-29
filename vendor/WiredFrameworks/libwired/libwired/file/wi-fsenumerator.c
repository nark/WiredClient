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

#include <wired/wi-error.h>
#include <wired/wi-fsenumerator.h>
#include <wired/wi-fts.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>

struct _wi_fsenumerator {
	wi_runtime_base_t					base;

	WI_FTS								*fts;
	WI_FTSENT							*ftsent;
};


static void								_wi_fsenumerator_dealloc(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_fsenumerator_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_fsenumerator_runtime_class = {
	"wi_fsenumerator_t",
	_wi_fsenumerator_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};


void wi_fsenumerator_register(void) {
	_wi_fsenumerator_runtime_id = wi_runtime_register_class(&_wi_fsenumerator_runtime_class);
}



void wi_fsenumerator_initialize(void) {
}



#pragma mark -

wi_fsenumerator_t * wi_fsenumerator_alloc(void) {
	return wi_runtime_create_instance(_wi_fsenumerator_runtime_id, sizeof(wi_fsenumerator_t));
}



wi_fsenumerator_t * wi_fsenumerator_init_with_path(wi_fsenumerator_t *fsenumerator, wi_string_t *path) {
	char	*paths[2];

	paths[0] = (char *) wi_string_cstring(path);
	paths[1] = NULL;

	errno = 0;
	fsenumerator->fts = wi_fts_open(paths, WI_FTS_NOSTAT | WI_FTS_LOGICAL, NULL);
	
	if(!fsenumerator->fts || errno != 0) {
		wi_error_set_errno(errno);
		wi_release(fsenumerator);

		return NULL;
	}

	return fsenumerator;
}



static void _wi_fsenumerator_dealloc(wi_runtime_instance_t *instance) {
	wi_fsenumerator_t		*fsenumerator = instance;

	if(fsenumerator->fts)
		wi_fts_close(fsenumerator->fts);
}



#pragma mark -

wi_fsenumerator_status_t wi_fsenumerator_get_next_path(wi_fsenumerator_t *fsenumerator, wi_string_t **path) {
	while((fsenumerator->ftsent = wi_fts_read(fsenumerator->fts))) {
		if(fsenumerator->ftsent->fts_level == 0)
			continue;

		if(fsenumerator->ftsent->fts_name[0] == '.') {
			wi_fts_set(fsenumerator->fts, fsenumerator->ftsent, WI_FTS_SKIP);
			
			continue;
		}
		
		switch(fsenumerator->ftsent->fts_info) {
			case WI_FTS_DC:
				*path = wi_string_with_cstring(fsenumerator->ftsent->fts_path);
				wi_error_set_errno(ELOOP);

				return WI_FSENUMERATOR_ERROR;
				break;

			case WI_FTS_DNR:
			case WI_FTS_ERR:
				*path = wi_string_with_cstring(fsenumerator->ftsent->fts_path);
				wi_error_set_errno(fsenumerator->ftsent->fts_errno);

				return WI_FSENUMERATOR_ERROR;
				break;

			case WI_FTS_DP:
				continue;
				break;

			default:
				*path = wi_string_with_cstring(fsenumerator->ftsent->fts_path);

				return WI_FSENUMERATOR_PATH;
				break;
		}
	}

	return WI_FSENUMERATOR_EOF;
}



void wi_fsenumerator_skip_descendents(wi_fsenumerator_t *fsenumerator) {
	if(fsenumerator->ftsent)
		wi_fts_set(fsenumerator->fts, fsenumerator->ftsent, WI_FTS_SKIP);
}



wi_uinteger_t wi_fsenumerator_level(wi_fsenumerator_t *fsenumerator) {
	return fsenumerator->ftsent ? fsenumerator->ftsent->fts_level : 0;
}
