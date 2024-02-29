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

#include "config.h"

#ifndef WI_SQLITE3

int wi_sqlite3_dummy = 0;

#else

#include <wired/wi-date.h>
#include <wired/wi-file.h>
#include <wired/wi-lock.h>
#include <wired/wi-macros.h>
#include <wired/wi-null.h>
#include <wired/wi-number.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-sqlite3.h>
#include <wired/wi-string.h>
#include <wired/wi-uuid.h>

#include <stdarg.h>
#include <string.h>

#include <pthread.h>
#include <sqlite3.h>

struct _wi_sqlite3_database {
	wi_runtime_base_t					base;
	
	sqlite3								*database;
	
	wi_recursive_lock_t					*lock;
};


static int								_wi_sqlite3_busy_handler(void *, int);

static void								_wi_sqlite3_database_dealloc(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_sqlite3_database_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_sqlite3_database_runtime_class = {
	"wi_sqlite3_database_t",
	_wi_sqlite3_database_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};


struct _wi_sqlite3_statement {
	wi_runtime_base_t					base;
	
	sqlite3_stmt						*statement;
	wi_string_t							*query;
};


static void								_wi_sqlite3_statement_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_sqlite3_statement_description(wi_runtime_instance_t *);

static void								_wi_sqlite3_bind_statement(wi_sqlite3_statement_t *, va_list);


static wi_runtime_id_t					_wi_sqlite3_statement_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_sqlite3_statement_runtime_class = {
	"wi_sqlite3_statement_t",
	_wi_sqlite3_statement_dealloc,
	NULL,
	NULL,
	_wi_sqlite3_statement_description,
	NULL
};


void wi_sqlite3_register(void) {
	_wi_sqlite3_database_runtime_id = wi_runtime_register_class(&_wi_sqlite3_database_runtime_class);
	_wi_sqlite3_statement_runtime_id = wi_runtime_register_class(&_wi_sqlite3_statement_runtime_class);
}



void wi_sqlite3_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_sqlite3_database_runtime_id(void) {
	return _wi_sqlite3_database_runtime_id;
}



#pragma mark -

wi_sqlite3_database_t * wi_sqlite3_open_database_with_path(wi_string_t *path) {
	wi_sqlite3_database_t		*database;
	
	database			= wi_autorelease(wi_runtime_create_instance(_wi_sqlite3_database_runtime_id, sizeof(wi_sqlite3_database_t)));
	database->lock		= wi_recursive_lock_init(wi_recursive_lock_alloc());
	
	if(sqlite3_open(wi_string_cstring(path), &database->database) == SQLITE_OK) {
		sqlite3_busy_handler(database->database, _wi_sqlite3_busy_handler, NULL);
	} else {
		if(database->database) {
			wi_error_set_sqlite3_error(database->database);
			
			sqlite3_close(database->database);
			database->database = NULL;
		} else {
			wi_error_set_errno(ENOMEM);
		}
		
		database = NULL;
	}
	
	return database;
}



#pragma mark -

static int _wi_sqlite3_busy_handler(void *context, int tries) {
	return 1;
}



#pragma mark -

static void _wi_sqlite3_database_dealloc(wi_runtime_instance_t *instance) {
	wi_sqlite3_database_t	*database = instance;
	
	if(database->database)
		sqlite3_close(database->database);
	
	wi_release(database->lock);
}



#pragma mark -

void wi_sqlite3_begin_immediate_transaction(wi_sqlite3_database_t *database) {
	wi_recursive_lock_lock(database->lock);
	
	if(!wi_sqlite3_execute_statement(database, WI_STR("BEGIN IMMEDIATE TRANSACTION"), NULL))
		WI_ASSERT(0, "Could not execute database statement: %m");
}



void wi_sqlite3_commit_transaction(wi_sqlite3_database_t *database) {
	if(!wi_sqlite3_execute_statement(database, WI_STR("COMMIT TRANSACTION"), NULL))
		WI_ASSERT(0, "Could not execute database statement: %m");

	wi_recursive_lock_unlock(database->lock);
}



void wi_sqlite3_rollback_transaction(wi_sqlite3_database_t *database) {
	if(!wi_sqlite3_execute_statement(database, WI_STR("ROLLBACK TRANSACTION"), NULL))
		WI_ASSERT(0, "Could not execute database statement: %m");

	wi_recursive_lock_unlock(database->lock);
}



#pragma mark -

wi_runtime_id_t wi_sqlite3_statement_runtime_id(void) {
	return _wi_sqlite3_statement_runtime_id;
}



#pragma mark -

wi_dictionary_t * wi_sqlite3_execute_statement(wi_sqlite3_database_t *database, wi_string_t *query, ...) {
	wi_sqlite3_statement_t		*statement;
	wi_dictionary_t				*results;
	va_list						ap;
	
	statement				= wi_autorelease(wi_runtime_create_instance(_wi_sqlite3_statement_runtime_id, sizeof(wi_sqlite3_statement_t)));
	statement->query		= wi_retain(query);
	
	wi_recursive_lock_lock(database->lock);

	if(
#ifdef HAVE_SQLITE3_PREPARE_V2
	   sqlite3_prepare_v2
#else
	   sqlite3_prepare
#endif
	   (database->database, wi_string_cstring(query), wi_string_length(query), &statement->statement, NULL) == SQLITE_OK) {
		va_start(ap, query);
		_wi_sqlite3_bind_statement(statement, ap);
		va_end(ap);
		
		results = wi_sqlite3_fetch_statement_results(database, statement);

		if(statement->statement) {
			sqlite3_finalize(statement->statement);
			statement->statement = NULL;
		}
	} else {
		wi_error_set_sqlite3_error_with_description(database->database, wi_description(statement));
		
		results = NULL;
	}

	wi_recursive_lock_unlock(database->lock);
	
	return results;
}



wi_sqlite3_statement_t * wi_sqlite3_prepare_statement(wi_sqlite3_database_t *database, wi_string_t *query, ...) {
	wi_sqlite3_statement_t		*statement;
	va_list						ap;
	
	statement				= wi_autorelease(wi_runtime_create_instance(_wi_sqlite3_statement_runtime_id, sizeof(wi_sqlite3_statement_t)));
	statement->query		= wi_retain(query);
	
	wi_recursive_lock_lock(database->lock);
	
	if(
#ifdef HAVE_SQLITE3_PREPARE_V2
	   sqlite3_prepare_v2
#else
	   sqlite3_prepare
#endif
	   (database->database, wi_string_cstring(query), wi_string_length(query), &statement->statement, NULL) == SQLITE_OK) {
		va_start(ap, query);
		_wi_sqlite3_bind_statement(statement, ap);
		va_end(ap);
	} else {
		wi_error_set_sqlite3_error_with_description(database->database, wi_description(statement));
		
		statement = NULL;
	}
	
	wi_recursive_lock_unlock(database->lock);
	
	return statement;
}



wi_dictionary_t * wi_sqlite3_fetch_statement_results(wi_sqlite3_database_t *database, wi_sqlite3_statement_t *statement) {
	wi_mutable_dictionary_t		*results;
	wi_runtime_instance_t		*instance;
	int							i, count, length, result;
	
	wi_recursive_lock_lock(database->lock);
	
	result = sqlite3_step(statement->statement);
	
	switch(result) {
		case SQLITE_DONE:
			results = wi_dictionary();

			sqlite3_finalize(statement->statement);
			statement->statement = NULL;
			break;
			
		case SQLITE_ROW:
			results			= wi_mutable_dictionary();
			count			= sqlite3_column_count(statement->statement);
			
			for(i = 0; i < count; i++) {
				switch(sqlite3_column_type(statement->statement, i)) {
					case SQLITE_INTEGER:
						instance	= wi_number_with_int64(sqlite3_column_int64(statement->statement, i));
						break;
						
					case SQLITE_FLOAT:
						instance	= wi_number_with_double(sqlite3_column_double(statement->statement, i));
						break;
						
					case SQLITE_TEXT: {
						instance	= wi_string_with_cstring((const char *) sqlite3_column_text(statement->statement, i));
                    } break;
						
					case SQLITE_BLOB:
						length		= sqlite3_column_bytes(statement->statement, i);
						instance	= wi_data_with_bytes(sqlite3_column_blob(statement->statement, i), length);
						break;
						
					case SQLITE_NULL:
						instance	= wi_null();
						break;
					
					default:
						instance	= NULL;
						break;
				}
				
				if(instance)
					wi_mutable_dictionary_set_data_for_key(results, instance, wi_string_with_cstring(sqlite3_column_name(statement->statement, i)));
			}
	
			wi_runtime_make_immutable(results);
			break;
			
		default:
			wi_error_set_sqlite3_error_with_description(database->database, wi_description(statement));

			sqlite3_finalize(statement->statement);
			statement->statement = NULL;

			results = NULL;
			break;
	}
	
	wi_recursive_lock_unlock(database->lock);
		
	return results;
}




#pragma mark -

int wi_sqlite3_snapshot_database_at_path(wi_sqlite3_database_t *database, wi_string_t *path) {
	wi_file_t 			*source;
    int 				rc = 0;                     /* Function return code */

    if(sqlite3_libversion_number() > 3006011) {
		
	    sqlite3 			*pFile;      /* Database connection opened on zFilename */
	    sqlite3_backup 		*pBackup;    /* Backup handle used to copy data */
	    
	    /* Open the database file identified by zFilename. */
	    rc = sqlite3_open(wi_string_cstring(path), &pFile);
	    if( rc==SQLITE_OK ){
	        
	        /* Open the sqlite3_backup object used to accomplish the transfer */
	        pBackup = sqlite3_backup_init(pFile, "main", database->database, "main");
	        if( pBackup ){
	            
	            /* Each iteration of this loop copies 5 database pages from database
	             ** pDb to the backup database. If the return value of backup_step()
	             ** indicates that there are still  further pages to copy, sleep for
	             ** 250 ms before repeating. */
	            do {
	                rc = sqlite3_backup_step(pBackup, 5);

	                if( rc==SQLITE_OK || rc==SQLITE_BUSY || rc==SQLITE_LOCKED ){
	                    sqlite3_sleep(250);
	                }
	            } while( rc==SQLITE_OK || rc==SQLITE_BUSY || rc==SQLITE_LOCKED );
	            
	            /* Release resources allocated by backup_init(). */
	            (void)sqlite3_backup_finish(pBackup);
	        }
	        rc = sqlite3_errcode(pFile);
	    }
	    
	    /* Close the database connection opened on database file zFilename
	     ** and return the result of this function. */
	    (void)sqlite3_close(pFile);

	}

	/* TODO: Compress file if suceeded (debug) */ 
	// if(rc == SQLITE_OK) {
	// 	source 	= wi_file_for_reading(path);

	// 	wi_file_compress_at_path(source, wi_string_by_appending_string(path, WI_STR(".zip")), 1);
	// }
	
    return rc;
}



#pragma mark -

static void _wi_sqlite3_statement_dealloc(wi_runtime_instance_t *instance) {
	wi_sqlite3_statement_t	*statement = instance;
	
	WI_ASSERT(statement->statement == NULL, "statement for query \"%@\" still alive in dealloc", statement->query);
	
	wi_release(statement->query);
}



static wi_string_t * _wi_sqlite3_statement_description(wi_runtime_instance_t *instance) {
	wi_sqlite3_statement_t	*statement = instance;
	
	return statement->query;
}



#pragma mark -

static void _wi_sqlite3_bind_statement(wi_sqlite3_statement_t *statement, va_list ap) {
	wi_string_t					*string;
	wi_runtime_instance_t		*instance;
	wi_runtime_id_t				id;
	wi_uinteger_t				index;
	int							result;
	
	index = 1;
	
	while((instance = va_arg(ap, wi_runtime_instance_t *))) {
		id			= wi_runtime_id(instance);
		result		= SQLITE_OK;
		
		if(id == wi_string_runtime_id()) {
			result = sqlite3_bind_text(statement->statement, index, wi_string_cstring(instance), wi_string_length(instance), SQLITE_STATIC);
		}
		else if(id == wi_number_runtime_id()) {
			switch(wi_number_storage_type(instance)) {
				case WI_NUMBER_STORAGE_INT8:
				case WI_NUMBER_STORAGE_INT16:
				case WI_NUMBER_STORAGE_INT32:
				case WI_NUMBER_STORAGE_INT64:
					result = sqlite3_bind_int64(statement->statement, index, wi_number_int64(instance));
					break;
					
				case WI_NUMBER_STORAGE_FLOAT:
				case WI_NUMBER_STORAGE_DOUBLE:
					result = sqlite3_bind_double(statement->statement, index, wi_number_double(instance));
					break;
			}
		}
		else if(id == wi_uuid_runtime_id()) {
			string = wi_uuid_string(instance);
			
			result = sqlite3_bind_text(statement->statement, index, wi_string_cstring(string), wi_string_length(string), SQLITE_STATIC);
		}
		else if(id == wi_date_runtime_id()) {
			string = wi_date_sqlite3_string(instance);
			
			result = sqlite3_bind_text(statement->statement, index, wi_string_cstring(string), wi_string_length(string), SQLITE_STATIC);
		}
		else if(id == wi_null_runtime_id()) {
			result = sqlite3_bind_null(statement->statement, index);
		}
		else if(id == wi_data_runtime_id()) {
			result = sqlite3_bind_blob(statement->statement, index, wi_data_bytes(instance), wi_data_length(instance), SQLITE_STATIC);
		}
		else {
			WI_ASSERT(0, "%@ is not a supported data type", instance);
		}
		
		WI_ASSERT(result == SQLITE_OK, "error %d while binding parameter %u", result, index);
		
		index++;
	}
}

#endif
