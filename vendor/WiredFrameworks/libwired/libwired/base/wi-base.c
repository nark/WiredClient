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

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <time.h>

#include <wired/wi-base.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

// Compatibility with non-clang compilers.
#ifndef __has_builtin
  #define __has_builtin(x) 0
#endif

#define _WI_ELF_STEP(byte, hash)                \
    WI_STMT_START                                \
        (hash) = ((hash) << 4) + (byte);        \
        (hash) ^= ((hash) >> 24) & 0xF0;        \
    WI_STMT_END


wi_string_t                    *wi_root_path = NULL;

wi_boolean_t                wi_chrooted = false;



void wi_initialize(void) {
    wi_runtime_register();

    wi_address_register();
    wi_array_register();
    wi_config_register();
    
#ifdef WI_CIPHERS
    wi_cipher_register();
#endif
    
    wi_data_register();
    wi_date_register();
    wi_dictionary_register();
    wi_digest_register();
    wi_enumerator_register();
    wi_error_register();
    wi_file_register();
    wi_fsenumerator_register();
    wi_fsevents_register();
    wi_host_register();
    wi_lock_register();
    wi_log_register();
    wi_null_register();
    wi_number_register();

#ifdef WI_P7
    wi_p7_message_register();
    wi_p7_socket_register();
    wi_p7_spec_register();
#endif
    
    wi_pool_register();
    wi_process_register();
    wi_random_register();
    wi_regexp_register();
    
#ifdef HAVE_OPENSSL_SHA_H
    wi_rsa_register();
#endif
    
    wi_set_register();
    wi_settings_register();
    wi_socket_register();
    wi_speed_calculator_register();
    
#ifdef WI_SQLITE3
    wi_sqlite3_register();
#endif
    
    wi_string_register();
    wi_task_register();
    
#ifdef WI_TERMCAP
    wi_terminal_register();
#endif

    wi_test_register();
    wi_thread_register();

#if WI_PTHREADS
    wi_timer_register();
#endif

    wi_url_register();
    wi_uuid_register();
    wi_version_register();
    
#ifdef HAVE_OPENSSL_SHA_H
    wi_x509_register();
#endif

    wi_lock_initialize();
    wi_runtime_initialize();

    wi_array_initialize();
    wi_dictionary_initialize();
    wi_set_initialize();

    wi_string_initialize();

    wi_address_initialize();
    wi_config_initialize();

#ifdef WI_CIPHERS
    wi_cipher_initialize();
#endif
    
    wi_data_initialize();
    wi_date_initialize();
    wi_digest_initialize();
    wi_enumerator_initialize();
    wi_error_initialize();
    wi_file_initialize();
    wi_fsenumerator_initialize();
    wi_fsevents_initialize();
    wi_host_initialize();
    wi_log_initialize();
    wi_null_initialize();
    wi_number_initialize();
    wi_pool_initialize();
    wi_process_initialize();
    wi_random_initialize();
    wi_regexp_initialize();
    
#ifdef HAVE_OPENSSL_SHA_H
    wi_rsa_initialize();
#endif

#ifdef WI_P7
    wi_p7_message_initialize();
    wi_p7_socket_initialize();
    wi_p7_spec_initialize();
#endif

    wi_settings_initialize();
    wi_socket_initialize();
    wi_speed_calculator_initialize();

#ifdef WI_SQLITE3
    wi_sqlite3_initialize();
#endif
    
    wi_task_initialize();
    
#ifdef WI_TERMCAP
    wi_terminal_initialize();
#endif

    wi_test_initialize();
    wi_thread_initialize();

#if WI_PTHREADS
    wi_timer_initialize();
#endif

    wi_url_initialize();
    wi_uuid_initialize();
    wi_version_initialize();

#ifdef HAVE_OPENSSL_SHA_H
    wi_x509_initialize();
#endif
}



void wi_load(int argc, const char **argv) {
    wi_pool_t        *pool;
    
    pool = wi_pool_init(wi_pool_alloc());
    
    wi_process_load(argc, argv);
    
    wi_release(pool);
}



#pragma mark -

void wi_abort(void) {
    abort();
}

void wi_crash(void) {
#if __has_builtin(__builtin_trap)
    __builtin_trap();
#else
    *((char *) NULL) = 0;
#endif
}

#pragma mark -

wi_hash_code_t wi_hash_cstring(const char *s, wi_uinteger_t length) {
    wi_hash_code_t    hash = length;
    const char        *end, *end4;

    if(length < 16) {
        end = s + length;
        end4 = s + (length & ~3);
        
        while(s < end4) {
            hash = (hash * 67503105) + (s[0] * 16974593) + (s[1] * 66049) + (s[2] * 257) + s[3];
            s += 4;
        }
        
        while(s < end)
            hash = (hash * 257) + *s++;
    } else {
        hash = (hash * 67503105) + (s[0] * 16974593) + (s[1] * 66049) + (s[2] * 257) + s[3];
        hash = (hash * 67503105) + (s[4] * 16974593) + (s[5] * 66049) + (s[6] * 257) + s[7];
        s += length - 8;
        hash = (hash * 67503105) + (s[0] * 16974593) + (s[1] * 66049) + (s[2] * 257) + s[3];
        hash = (hash * 67503105) + (s[4] * 16974593) + (s[5] * 66049) + (s[6] * 257) + s[7];
    }

    return hash + (hash << (length & 31));
}



wi_hash_code_t wi_hash_pointer(const void *p) {
#ifdef WI_32
    return (wi_hash_code_t) ((((uint32_t) p) >> 16) ^ ((uint32_t) p));
#else
    return (wi_hash_code_t) ((((uint64_t) p) >> 32) ^ ((uint64_t) p));
#endif
}



wi_hash_code_t wi_hash_int(int32_t i) {
    return (wi_hash_code_t) WI_ABS(i);
}



wi_hash_code_t wi_hash_double(double d) {
    double        i;

    i = rint(WI_ABS(d));

    return (wi_hash_code_t) fmod(i, (double) 0xFFFFFFFF) + ((d - i) * 0xFFFFFFFF);
}



wi_hash_code_t wi_hash_data(const unsigned char *bytes, wi_uinteger_t length) {
    wi_hash_code_t    hash = 0;
    wi_uinteger_t    i;
    
    i = length;
    
    while(i > 3) {
        _WI_ELF_STEP(bytes[length - i    ], hash);
        _WI_ELF_STEP(bytes[length - i + 1], hash);
        _WI_ELF_STEP(bytes[length - i + 2], hash);
        _WI_ELF_STEP(bytes[length - i + 3], hash);
        i -= 4;
    }

    switch(i) {
        case 3: _WI_ELF_STEP(bytes[length - 3], hash);
        case 2: _WI_ELF_STEP(bytes[length - 2], hash);
        case 1: _WI_ELF_STEP(bytes[length - 1], hash);
    }
    
    return hash;
}
