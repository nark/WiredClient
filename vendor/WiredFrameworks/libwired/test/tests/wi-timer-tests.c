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

WI_TEST_EXPORT void						wi_test_timer(void);


#ifdef WI_PTHREADS
static void								_wi_test_timer_function(wi_timer_t *);


static wi_uinteger_t					_wi_test_timer_hits;
static wi_condition_lock_t				*_wi_test_timer_lock;
#endif


void wi_test_timer(void) {
#ifdef WI_PTHREADS
	wi_timer_t		*timer;
	
	_wi_test_timer_lock = wi_autorelease(wi_condition_lock_init_with_condition(wi_condition_lock_alloc(), 0));
	
	timer = wi_autorelease(wi_timer_init_with_function(wi_timer_alloc(), _wi_test_timer_function, 0.001, false));
	wi_timer_schedule(timer);
	
	if(wi_condition_lock_lock_when_condition(_wi_test_timer_lock, 1, 1.0)) {
		WI_TEST_ASSERT_EQUALS(_wi_test_timer_hits, 5U, "");
		wi_condition_lock_unlock(_wi_test_timer_lock);
	} else {
		WI_TEST_FAIL("Timed out waiting for timer, currently at %u %s",
			_wi_test_timer_hits, _wi_test_timer_hits == 1 ? "hit" : "hits");
	}
#endif
}



#ifdef WI_PTHREADS

static void _wi_test_timer_function(wi_timer_t *timer) {
	wi_condition_lock_lock(_wi_test_timer_lock);
	
	if(++_wi_test_timer_hits == 5) {
		wi_timer_invalidate(timer);
		wi_condition_lock_unlock_with_condition(_wi_test_timer_lock, 1);
	} else {
		wi_timer_schedule(timer);
		wi_condition_lock_unlock_with_condition(_wi_test_timer_lock, 0);
	}
}

#endif
