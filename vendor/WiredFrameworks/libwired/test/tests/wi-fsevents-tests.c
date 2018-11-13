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

#include <wired/wired.h>

WI_TEST_EXPORT void						wi_test_fsevents(void);


#ifdef WI_PTHREADS
static void								wi_test_fsevents_thread(wi_runtime_instance_t *);
static void								wi_test_fsevents_callback(wi_string_t *);


static wi_fsevents_t					*wi_test_fsevents_fsevents;
static wi_condition_lock_t				*wi_test_fsevents_lock;
static wi_fsevents_t					*wi_test_fsevents_path;
#endif


void wi_test_fsevents(void) {
#ifdef WI_PTHREADS
	wi_string_t			*directory;
	
	wi_test_fsevents_fsevents = wi_fsevents_init(wi_fsevents_alloc());
	
	if(!wi_test_fsevents_fsevents) {
		if(wi_error_domain() != WI_ERROR_DOMAIN_LIBWIRED && wi_error_code() != WI_ERROR_FSEVENTS_NOTSUPP)
			WI_TEST_ASSERT_NOT_NULL(wi_test_fsevents_fsevents, "%m");
		
		return;
	}
	
	directory = wi_fs_temporary_path_with_template(WI_STR("/tmp/libwired-fsevents.XXXXXXXX"));
	
	wi_fs_create_directory(directory, 0700);
	
	wi_fsevents_add_path(wi_test_fsevents_fsevents, directory);
	wi_fsevents_set_callback(wi_test_fsevents_fsevents, wi_test_fsevents_callback);
	
	wi_test_fsevents_lock = wi_condition_lock_init_with_condition(wi_condition_lock_alloc(), 0);
	
	if(!wi_thread_create_thread(wi_test_fsevents_thread, NULL))
		WI_TEST_FAIL("%m");
	
	if(wi_condition_lock_lock_when_condition(wi_test_fsevents_lock, 1, 1.0))
		wi_condition_lock_unlock(wi_test_fsevents_lock);
	else
		WI_TEST_FAIL("Timed out waiting for fsevents thread");
	
	wi_string_write_to_file(WI_STR("foo"), wi_string_by_appending_path_component(directory, WI_STR("file")));
	
	if(wi_condition_lock_lock_when_condition(wi_test_fsevents_lock, 2, 1.0)) {
		wi_fs_delete_path(directory);
	
		if(!wi_test_fsevents_path)
			WI_TEST_FAIL("No fsevents callback received");
		else
			WI_TEST_ASSERT_EQUAL_INSTANCES(wi_test_fsevents_path, directory, "");
		
		wi_condition_lock_unlock(wi_test_fsevents_lock);
	} else {
		wi_fs_delete_path(directory);
	
		WI_TEST_FAIL("Timed out waiting for fsevents result");
	}

	wi_release(wi_test_fsevents_lock);
	wi_release(wi_test_fsevents_fsevents);
	wi_release(wi_test_fsevents_path);
#endif
}



#ifdef WI_PTHREADS

static void wi_test_fsevents_thread(wi_runtime_instance_t *instance) {
	wi_pool_t		*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	wi_condition_lock_lock(wi_test_fsevents_lock);
	wi_condition_lock_unlock_with_condition(wi_test_fsevents_lock, 1);
	
	if(!wi_fsevents_run_with_timeout(wi_test_fsevents_fsevents, 1.0))
		WI_TEST_FAIL("%m");
	
	wi_condition_lock_lock(wi_test_fsevents_lock);
	wi_condition_lock_unlock_with_condition(wi_test_fsevents_lock, 2);
	
	wi_release(pool);
}



static void wi_test_fsevents_callback(wi_string_t *path) {
	wi_condition_lock_lock(wi_test_fsevents_lock);
	wi_test_fsevents_path = wi_retain(path);
	wi_condition_lock_unlock(wi_test_fsevents_lock);
}

#endif
