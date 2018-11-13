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

#ifndef WI_DATE_H
#define WI_DATE_H 1

#include <sys/time.h>
#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_date					wi_date_t;
typedef struct _wi_date					wi_mutable_date_t;


WI_EXPORT wi_time_interval_t			wi_time_interval(void);
WI_EXPORT wi_string_t *					wi_time_interval_string(wi_time_interval_t);
WI_EXPORT wi_string_t *					wi_time_interval_string_with_format(wi_time_interval_t, wi_string_t *);
WI_EXPORT wi_string_t *					wi_time_interval_rfc3339_string(wi_time_interval_t);
WI_EXPORT wi_string_t *					wi_time_interval_sqlite3_string(wi_time_interval_t);

WI_EXPORT wi_runtime_id_t				wi_date_runtime_id(void);

WI_EXPORT wi_date_t *					wi_date(void);
WI_EXPORT wi_date_t *					wi_date_with_time_interval(wi_time_interval_t);
WI_EXPORT wi_date_t *					wi_date_with_time(time_t);
WI_EXPORT wi_date_t *					wi_date_with_rfc3339_string(wi_string_t *);
WI_EXPORT wi_date_t *					wi_date_with_sqlite3_string(wi_string_t *);

WI_EXPORT wi_date_t *					wi_date_alloc(void);
WI_EXPORT wi_mutable_date_t *			wi_mutable_date_alloc(void);
WI_EXPORT wi_date_t *					wi_date_init(wi_date_t *);
WI_EXPORT wi_date_t *					wi_date_init_with_time_interval(wi_date_t *, wi_time_interval_t);
WI_EXPORT wi_date_t *					wi_date_init_with_time(wi_date_t *, time_t);
WI_EXPORT wi_date_t *					wi_date_init_with_tv(wi_date_t *, struct timeval);
WI_EXPORT wi_date_t *					wi_date_init_with_ts(wi_date_t *, struct timespec);
WI_EXPORT wi_date_t *					wi_date_init_with_string(wi_date_t *, wi_string_t *, wi_string_t *);
WI_EXPORT wi_date_t *					wi_date_init_with_rfc3339_string(wi_date_t *, wi_string_t *);

WI_EXPORT wi_integer_t					wi_date_compare(wi_runtime_instance_t *, wi_runtime_instance_t *);
WI_EXPORT wi_boolean_t                  wi_date_valid_expiration_date(wi_date_t *);

WI_EXPORT wi_time_interval_t			wi_date_time_interval(wi_date_t *);

WI_EXPORT wi_time_interval_t			wi_date_time_interval_since_now(wi_date_t *);
WI_EXPORT wi_time_interval_t			wi_date_time_interval_since_date(wi_date_t *, wi_date_t *);

WI_EXPORT wi_string_t *					wi_date_string_with_format(wi_date_t *, wi_string_t *);
WI_EXPORT wi_string_t *					wi_date_rfc3339_string(wi_date_t *);
WI_EXPORT wi_string_t *					wi_date_sqlite3_string(wi_date_t *);
WI_EXPORT wi_string_t *					wi_date_time_interval_string(wi_date_t *);

WI_EXPORT void							wi_mutable_date_add_time_interval(wi_mutable_date_t *, wi_time_interval_t);
WI_EXPORT void							wi_mutable_date_set_time_interval(wi_mutable_date_t *, wi_time_interval_t);

#endif /* WI_DATE_H */
