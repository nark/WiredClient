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

#include <sys/time.h>
#include <string.h>
#include <time.h>

#include <wired/wi-compat.h>
#include <wired/wi-date.h>
#include <wired/wi-macros.h>
#include <wired/wi-pool.h>
#include <wired/wi-private.h>
#include <wired/wi-regexp.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#define _WI_DATE_EPSILON				0.001


struct _wi_date {
	wi_runtime_base_t					base;
	
	wi_time_interval_t					interval;
};


static wi_runtime_instance_t *			_wi_date_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_date_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_hash_code_t					_wi_date_hash(wi_runtime_instance_t *);
static wi_string_t *					_wi_date_description(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_date_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_date_runtime_class = {
	"wi_date_t",
	NULL,
	_wi_date_copy,
	_wi_date_is_equal,
	_wi_date_description,
	_wi_date_hash
};



void wi_date_register(void) {
	_wi_date_runtime_id = wi_runtime_register_class(&_wi_date_runtime_class);
}



void wi_date_initialize(void) {
}



#pragma mark -

wi_time_interval_t wi_time_interval(void) {
	struct timeval	tv;

	gettimeofday(&tv, NULL);
	
	return (wi_time_interval_t) wi_tvtod(tv);
}



wi_string_t * wi_time_interval_string(wi_time_interval_t interval) {
	wi_uinteger_t	days, hours, minutes, seconds;
	
	seconds = interval;
	
	days = seconds / 86400;
	seconds -= days * 86400;

	hours = seconds / 3600;
	seconds -= hours * 3600;

	minutes = seconds / 60;
	seconds -= minutes * 60;

	if(days > 0) {
		return wi_string_with_format(WI_STR("%lu:%.2lu:%.2lu:%.2lu days"),
			days, hours, minutes, seconds);
	}
	else if(hours > 0) {
		return wi_string_with_format(WI_STR("%.2lu:%.2lu:%.2lu hours"),
			hours, minutes, seconds);
	}
	else if(minutes > 0) {
		return wi_string_with_format(WI_STR("%.2lu:%.2lu minutes"),
			minutes, seconds);
	}
	else {
		return wi_string_with_format(WI_STR("00:%.2lu seconds"),
			seconds);
	}
}



wi_string_t * wi_time_interval_string_with_format(wi_time_interval_t interval, wi_string_t *format) {
	struct tm	tm;
	char		string[1024];
	time_t		time;
	
	time = interval;

	memset(&tm, 0, sizeof(tm));
	
	if(wi_string_has_suffix(format, WI_STR("Z")))
		gmtime_r(&time, &tm);
	else
		localtime_r(&time, &tm);
	
	(void) strftime(string, sizeof(string), wi_string_cstring(format), &tm);
	
	return wi_string_with_cstring(string);
}



wi_string_t * wi_time_interval_rfc3339_string(wi_time_interval_t interval) {
	wi_mutable_string_t		*string;

	string = wi_mutable_copy(wi_time_interval_string_with_format(interval, WI_STR("%Y-%m-%dT%H:%M:%S%z")));

	wi_mutable_string_insert_string_at_index(string, WI_STR(":"), 22);

	wi_runtime_make_immutable(string);

	return wi_autorelease(string);
}



wi_string_t * wi_time_interval_sqlite3_string(wi_time_interval_t interval) {
	return wi_time_interval_string_with_format(interval, WI_STR("%Y-%m-%d %H:%M:%S"));
}



#pragma mark -

wi_runtime_id_t wi_date_runtime_id(void) {
	return _wi_date_runtime_id;
}



#pragma mark -

wi_date_t * wi_date(void) {
	return wi_autorelease(wi_date_init(wi_date_alloc()));
}



wi_date_t * wi_date_with_time_interval(wi_time_interval_t interval) {
	return wi_autorelease(wi_date_init_with_time_interval(wi_date_alloc(), interval));
}



wi_date_t * wi_date_with_time(time_t time) {
	return wi_autorelease(wi_date_init_with_time(wi_date_alloc(), time));
}



wi_date_t * wi_date_with_rfc3339_string(wi_string_t *string) {
	return wi_autorelease(wi_date_init_with_rfc3339_string(wi_date_alloc(), string));
}



wi_date_t * wi_date_with_sqlite3_string(wi_string_t *string) {
	struct tm		tm;
	time_t			time;
	wi_uinteger_t	hours, minutes;
	
	time = wi_time_interval();
	
	localtime_r(&time, &tm);
	
	hours		= WI_ABS(tm.tm_gmtoff) / 3600;
	minutes		= (WI_ABS(tm.tm_gmtoff) % 3600) / 60;
	string		= wi_string_by_appending_format(string, WI_STR(" %@%.2lu%.2lu"),
		(tm.tm_gmtoff > 0)
			? WI_STR("+")
			: WI_STR("-"),
		hours,
		minutes);
	
	return wi_autorelease(wi_date_init_with_string(wi_date_alloc(), string, WI_STR("%Y-%m-%d %H:%M:%S %z")));
}



#pragma mark -

wi_date_t * wi_date_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_date_runtime_id, sizeof(wi_date_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_mutable_date_t * wi_mutable_date_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_date_runtime_id, sizeof(wi_date_t), WI_RUNTIME_OPTION_MUTABLE);
}



wi_date_t * wi_date_init(wi_date_t *date) {
	return wi_date_init_with_time_interval(date, wi_time_interval());
}



wi_date_t * wi_date_init_with_time_interval(wi_date_t *date, wi_time_interval_t interval) {
	date->interval = interval;
	
	return date;
}



wi_date_t * wi_date_init_with_time(wi_date_t *date, time_t time) {
	return wi_date_init_with_time_interval(date, (wi_time_interval_t) time);
}



wi_date_t * wi_date_init_with_tv(wi_date_t *date, struct timeval tv) {
	return wi_date_init_with_time_interval(date, (wi_time_interval_t) wi_tvtod(tv));
}



wi_date_t * wi_date_init_with_ts(wi_date_t *date, struct timespec ts) {
	return wi_date_init_with_time_interval(date, (wi_time_interval_t) wi_tstod(ts));
}



wi_date_t * wi_date_init_with_string(wi_date_t *date, wi_string_t *string, wi_string_t *format) {
	wi_regexp_t			*regexp;
	wi_string_t			*match;
	struct tm			tm;
	time_t				clock;
	wi_uinteger_t		offset, hours, minutes;

	memset(&tm, 0, sizeof(tm));

	if(!strptime(wi_string_cstring(string), wi_string_cstring(format), &tm)) {
		wi_release(date);
		
		return NULL;
	}

	offset = 0;

	if(wi_string_contains_string(format, WI_STR("%z"), WI_STRING_CASE_INSENSITIVE)) {
		regexp		= wi_regexp_with_string(WI_STR("/((\\+|\\-)[0-9]{4})/"));
		match		= wi_regexp_string_by_matching_string(regexp, string, 1);

		if(match) {
			hours		= wi_string_uinteger(wi_string_substring_with_range(match, wi_make_range(1, 2)));
			minutes		= wi_string_uinteger(wi_string_substring_with_range(match, wi_make_range(3, 2)));

			offset = (hours * 3600) + (minutes * 60);

			if(wi_string_has_prefix(match, WI_STR("-")))
				offset = -offset;
		}
	}

	clock = wi_timegm(&tm) - offset;
	
	return wi_date_init_with_time(date, clock);
}



wi_date_t * wi_date_init_with_rfc3339_string(wi_date_t *date, wi_string_t *string) {
	wi_mutable_string_t		*fullstring;
	wi_string_t				*timezone;

	if(wi_string_length(string) >= 19) {
		fullstring	= wi_autorelease(wi_mutable_copy(string));
		timezone	= wi_string_substring_from_index(fullstring, 19);
		
		if(wi_is_equal(timezone, WI_STR("Z"))) {
			wi_mutable_string_delete_characters_in_range(fullstring, wi_make_range(19, 1));

			return wi_date_init_with_string(date, fullstring, WI_STR("%Y-%m-%dT%H:%M:%S"));
		}
		else if(wi_string_length(timezone) == 6) {
			wi_mutable_string_delete_characters_in_range(fullstring, wi_make_range(22, 1));

			return wi_date_init_with_string(date, fullstring, WI_STR("%Y-%m-%dT%H:%M:%S%z"));
		}
	}
	
	wi_release(date);

	return NULL;
}



static wi_runtime_instance_t * _wi_date_copy(wi_runtime_instance_t *instance) {
	wi_date_t		*date = instance;
	
	return wi_date_init_with_time_interval(wi_date_alloc(), date->interval);
}



static wi_boolean_t _wi_date_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_date_t		*date1 = instance1;
	wi_date_t		*date2 = instance2;
	
	return (WI_MAX(date1->interval, date2->interval) - WI_MIN(date1->interval, date2->interval) < _WI_DATE_EPSILON);
}



static wi_hash_code_t _wi_date_hash(wi_runtime_instance_t *instance) {
	wi_date_t		*date = instance;
	
	return wi_hash_double(date->interval);
}



static wi_string_t * _wi_date_description(wi_runtime_instance_t *instance) {
	wi_date_t		*date = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{date = %@}"),
		wi_runtime_class_name(date),
		date,
		wi_time_interval_string_with_format(date->interval, WI_STR("%Y-%m-%d %H:%M:%S %z")));
}



#pragma mark -

wi_integer_t wi_date_compare(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_date_t			*date1 = instance1;
	wi_date_t			*date2 = instance2;
	
	if(date1->interval > date2->interval)
		return 1;
	else if(date2->interval > date1->interval)
		return -1;
	
	return 0;
}

wi_boolean_t wi_date_valid_expiration_date(wi_date_t *date) {
    wi_time_interval_t  interval;
    wi_date_t           *now = wi_date();
    
    if(!date)
        return false;
    
    interval = wi_date_time_interval_since_date(now, date);
    return (interval > 0) ? true : false;
}


#pragma mark -

wi_time_interval_t wi_date_time_interval(wi_date_t *date) {
	return date->interval;
}



#pragma mark -

wi_time_interval_t wi_date_time_interval_since_now(wi_date_t *date) {
	return wi_time_interval() - date->interval;
}



wi_time_interval_t wi_date_time_interval_since_date(wi_date_t *date, wi_date_t *otherdate) {
	return otherdate->interval - date->interval;
}



#pragma mark -

wi_string_t * wi_date_string_with_format(wi_date_t *date, wi_string_t *format) {
	return wi_time_interval_string_with_format(date->interval, format);
}



wi_string_t * wi_date_rfc3339_string(wi_date_t *date) {
	return wi_time_interval_rfc3339_string(date->interval);
}



wi_string_t * wi_date_sqlite3_string(wi_date_t *date) {
	return wi_time_interval_sqlite3_string(date->interval);
}



wi_string_t * wi_date_time_interval_string(wi_date_t *date) {
	return wi_time_interval_string(date->interval);
}



#pragma mark -

void wi_mutable_date_add_time_interval(wi_mutable_date_t *date, wi_time_interval_t interval) {
	WI_RUNTIME_ASSERT_MUTABLE(date);
	
	date->interval += interval;
}



void wi_mutable_date_set_time_interval(wi_mutable_date_t *date, wi_time_interval_t interval) {
	WI_RUNTIME_ASSERT_MUTABLE(date);
	
	date->interval = interval;
}
