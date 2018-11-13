/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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

#ifndef WI_SQLITE3_H
#define WI_SQLITE3_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_sqlite3_database			wi_sqlite3_database_t;
typedef struct _wi_sqlite3_statement		wi_sqlite3_statement_t;


WI_EXPORT wi_runtime_id_t					wi_sqlite3_database_runtime_id(void);

WI_EXPORT wi_sqlite3_database_t *			wi_sqlite3_open_database_with_path(wi_string_t *);

WI_EXPORT void								wi_sqlite3_begin_immediate_transaction(wi_sqlite3_database_t *);
WI_EXPORT void								wi_sqlite3_commit_transaction(wi_sqlite3_database_t *);
WI_EXPORT void								wi_sqlite3_rollback_transaction(wi_sqlite3_database_t *);

WI_EXPORT wi_runtime_id_t					wi_sqlite3_statement_runtime_id(void);

WI_EXPORT wi_dictionary_t *					wi_sqlite3_execute_statement(wi_sqlite3_database_t *, wi_string_t *, ...) WI_SENTINEL;
WI_EXPORT wi_sqlite3_statement_t *			wi_sqlite3_prepare_statement(wi_sqlite3_database_t *, wi_string_t *, ...) WI_SENTINEL;
WI_EXPORT wi_dictionary_t *					wi_sqlite3_fetch_statement_results(wi_sqlite3_database_t *, wi_sqlite3_statement_t *);

WI_EXPORT int								wi_sqlite3_snapshot_database_at_path(wi_sqlite3_database_t *, wi_string_t *);

#endif /* WI_SQLITE3_H */
