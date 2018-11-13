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


/**
 * @file wi-private.h 
 * @brief Private stuff used by libwired but not included in the API
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 *
 */

#ifndef WI_PRIVATE_H
#define WI_PRIVATE_H 1

#include <sys/types.h>
#include <regex.h>

#include <wired/wi-array.h>
#include <wired/wi-assert.h>
#include <wired/wi-base.h>
#include <wired/wi-enumerator.h>
#include <wired/wi-error.h>
#include <wired/wi-fsenumerator.h>
#include <wired/wi-set.h>
#include <wired/wi-thread.h>

#define WI_RUNTIME_MAGIC				0xAC1DFEED

#define WI_RUNTIME_BASE(instance)											\
	((wi_runtime_base_t *) instance)

#define WI_RUNTIME_ASSERT_MUTABLE(instance)									\
	WI_ASSERT(wi_runtime_options((instance)) & WI_RUNTIME_OPTION_MUTABLE,	\
		"%@ is not mutable", (instance))


struct _wi_enumerator_context {
	wi_uinteger_t						index;
	void								*bucket;
};
typedef struct _wi_enumerator_context	wi_enumerator_context_t;


typedef void *							wi_enumerator_func_t(wi_runtime_instance_t *, wi_enumerator_context_t *);


WI_EXPORT void							wi_address_register(void);
WI_EXPORT void							wi_array_register(void);
WI_EXPORT void							wi_cipher_register(void);
WI_EXPORT void							wi_config_register(void);
WI_EXPORT void							wi_data_register(void);
WI_EXPORT void							wi_date_register(void);
WI_EXPORT void							wi_dictionary_register(void);
WI_EXPORT void							wi_digest_register(void);
WI_EXPORT void							wi_enumerator_register(void);
WI_EXPORT void							wi_error_register(void);
WI_EXPORT void							wi_file_register(void);
WI_EXPORT void							wi_fsenumerator_register(void);
WI_EXPORT void							wi_fsevents_register(void);
WI_EXPORT void							wi_host_register(void);
WI_EXPORT void							wi_lock_register(void);
WI_EXPORT void							wi_log_register(void);
WI_EXPORT void							wi_null_register(void);
WI_EXPORT void							wi_number_register(void);
WI_EXPORT void							wi_p7_message_register(void);
WI_EXPORT void							wi_p7_socket_register(void);
WI_EXPORT void							wi_p7_spec_register(void);
WI_EXPORT void							wi_pool_register(void);
WI_EXPORT void							wi_process_register(void);
WI_EXPORT void							wi_random_register(void);
WI_EXPORT void							wi_regexp_register(void);
WI_EXPORT void							wi_rsa_register(void);
WI_EXPORT void							wi_runtime_register(void);
WI_EXPORT void							wi_set_register(void);
WI_EXPORT void							wi_settings_register(void);
WI_EXPORT void							wi_socket_register(void);
WI_EXPORT void							wi_speed_calculator_register(void);
WI_EXPORT void							wi_sqlite3_register(void);
WI_EXPORT void							wi_string_register(void);
WI_EXPORT void							wi_task_register(void);
WI_EXPORT void							wi_terminal_register(void);
WI_EXPORT void							wi_test_register(void);
WI_EXPORT void							wi_timer_register(void);
WI_EXPORT void							wi_thread_register(void);
WI_EXPORT void							wi_url_register(void);
WI_EXPORT void							wi_uuid_register(void);
WI_EXPORT void							wi_version_register(void);
WI_EXPORT void							wi_x509_register(void);

WI_EXPORT void							wi_address_initialize(void);
WI_EXPORT void							wi_array_initialize(void);
WI_EXPORT void							wi_cipher_initialize(void);
WI_EXPORT void							wi_config_initialize(void);
WI_EXPORT void							wi_data_initialize(void);
WI_EXPORT void							wi_date_initialize(void);
WI_EXPORT void							wi_dictionary_initialize(void);
WI_EXPORT void							wi_digest_initialize(void);
WI_EXPORT void							wi_enumerator_initialize(void);
WI_EXPORT void							wi_error_initialize(void);
WI_EXPORT void							wi_file_initialize(void);
WI_EXPORT void							wi_fsenumerator_initialize(void);
WI_EXPORT void							wi_fsevents_initialize(void);
WI_EXPORT void							wi_host_initialize(void);
WI_EXPORT void							wi_lock_initialize(void);
WI_EXPORT void							wi_log_initialize(void);
WI_EXPORT void							wi_null_initialize(void);
WI_EXPORT void							wi_number_initialize(void);
WI_EXPORT void							wi_p7_message_initialize(void);
WI_EXPORT void							wi_p7_socket_initialize(void);
WI_EXPORT void							wi_p7_spec_initialize(void);
WI_EXPORT void							wi_pool_initialize(void);
WI_EXPORT void							wi_process_initialize(void);
WI_EXPORT void							wi_random_initialize(void);
WI_EXPORT void							wi_regexp_initialize(void);
WI_EXPORT void							wi_rsa_initialize(void);
WI_EXPORT void							wi_runtime_initialize(void);
WI_EXPORT void							wi_set_initialize(void);
WI_EXPORT void							wi_settings_initialize(void);
WI_EXPORT void							wi_socket_initialize(void);
WI_EXPORT void							wi_speed_calculator_initialize(void);
WI_EXPORT void							wi_sqlite3_initialize(void);
WI_EXPORT void							wi_string_initialize(void);
WI_EXPORT void							wi_task_initialize(void);
WI_EXPORT void							wi_terminal_initialize(void);
WI_EXPORT void							wi_test_initialize(void);
WI_EXPORT void							wi_timer_initialize(void);
WI_EXPORT void							wi_thread_initialize(void);
WI_EXPORT void							wi_url_initialize(void);
WI_EXPORT void							wi_uuid_initialize(void);
WI_EXPORT void							wi_version_initialize(void);
WI_EXPORT void							wi_x509_initialize(void);

WI_EXPORT void							wi_process_load(int, const char **);

WI_EXPORT wi_hash_code_t				wi_hash_cstring(const char *, wi_uinteger_t);
WI_EXPORT wi_hash_code_t				wi_hash_pointer(const void *);
WI_EXPORT wi_hash_code_t				wi_hash_int(int);
WI_EXPORT wi_hash_code_t				wi_hash_double(double);
WI_EXPORT wi_hash_code_t				wi_hash_data(const unsigned char *, wi_uinteger_t);

WI_EXPORT wi_enumerator_t *				wi_enumerator_alloc(void);
WI_EXPORT wi_enumerator_t *				wi_enumerator_init_with_collection(wi_enumerator_t *, wi_runtime_instance_t *, wi_enumerator_func_t *);

WI_EXPORT void *						wi_enumerator_array_data_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);
WI_EXPORT void *						wi_enumerator_array_reverse_data_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);
WI_EXPORT void *						wi_enumerator_hash_key_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);
WI_EXPORT void *						wi_enumerator_hash_data_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);
WI_EXPORT void *						wi_enumerator_dictionary_key_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);
WI_EXPORT void *						wi_enumerator_dictionary_data_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);
WI_EXPORT void *						wi_enumerator_set_data_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);

WI_EXPORT void							wi_error_enter_thread(void);
WI_EXPORT void							wi_error_set_error(wi_error_domain_t, int);
WI_EXPORT void							wi_error_set_error_with_string(wi_error_domain_t, int, wi_string_t *);
WI_EXPORT void							wi_error_set_errno(int);

#ifdef HAVE_OPENSSL_SHA_H
WI_EXPORT void							wi_error_set_openssl_error(void);
#endif

#ifdef HAVE_OPENSSL_SSL_H
WI_EXPORT void							wi_error_set_openssl_ssl_error_with_result(void *, int);
#endif

#ifdef HAVE_COMMONCRYPTO_COMMONCRYPTOR_H
WI_EXPORT void							wi_error_set_commoncrypto_error(int);
#endif

#ifdef WI_LIBXML2
WI_EXPORT void							wi_error_set_libxml2_error(void);
#endif

#ifdef WI_SQLITE3
WI_EXPORT void							wi_error_set_sqlite3_error(void *);
WI_EXPORT void							wi_error_set_sqlite3_error_with_description(void *, wi_string_t *);
#endif

WI_EXPORT void							wi_error_set_regex_error(regex_t *, int);

#ifdef WI_ZLIB
WI_EXPORT void							wi_error_set_zlib_error(int);
#endif

WI_EXPORT void							wi_error_set_carbon_error(int);
WI_EXPORT void							wi_error_set_libwired_error(int);
WI_EXPORT void							wi_error_set_libwired_error_with_string(int, wi_string_t *);
WI_EXPORT void							wi_error_set_libwired_error_with_format(int, wi_string_t *, ...);

WI_EXPORT wi_fsenumerator_t *			wi_fsenumerator_alloc(void);
WI_EXPORT wi_fsenumerator_t *			wi_fsenumerator_init_with_path(wi_fsenumerator_t *, wi_string_t *);

WI_EXPORT void							wi_runtime_make_immutable(wi_runtime_instance_t *);

WI_EXPORT void							wi_socket_exit_thread(void);

WI_EXPORT void							wi_thread_set_poolstack(wi_thread_t *, void *);
WI_EXPORT void *						wi_thread_poolstack(wi_thread_t *);

#endif /* WI_PRIVATE_H */
