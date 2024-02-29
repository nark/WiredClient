/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
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

#ifndef WI_SOCKET_H
#define WI_SOCKET_H 1

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <wired/wi-base.h>
#include <wired/wi-rsa.h>
#include <wired/wi-runtime.h>
#include <wired/wi-x509.h>

#define WI_SOCKET_BUFFER_SIZE			BUFSIZ


typedef struct _wi_socket_tls			wi_socket_tls_t;
typedef struct _wi_socket				wi_socket_t;


enum _wi_socket_type {
	WI_SOCKET_TCP						= SOCK_STREAM,
	WI_SOCKET_UDP						= SOCK_DGRAM
};
typedef enum _wi_socket_type			wi_socket_type_t;


enum _wi_socket_direction {
	WI_SOCKET_READ						= (1 << 0),
	WI_SOCKET_WRITE						= (1 << 1)
};
typedef enum _wi_socket_direction		wi_socket_direction_t;


enum _wi_socket_tls_type {
	WI_SOCKET_TLS_CLIENT,
	WI_SOCKET_TLS_SERVER,
};
typedef enum _wi_socket_tls_type		wi_socket_tls_type_t;


enum _wi_socket_state {
	WI_SOCKET_READY,
	WI_SOCKET_ERROR,
	WI_SOCKET_TIMEOUT
};
typedef enum _wi_socket_state			wi_socket_state_t;


WI_EXPORT wi_runtime_id_t				wi_socket_tls_runtime_id(void);

WI_EXPORT wi_socket_tls_t *				wi_socket_tls_alloc(void);
WI_EXPORT wi_socket_tls_t *				wi_socket_tls_init_with_type(wi_socket_tls_t *, wi_socket_tls_type_t);

WI_EXPORT wi_boolean_t					wi_socket_tls_set_certificate(wi_socket_tls_t *, wi_x509_t *);
WI_EXPORT wi_boolean_t					wi_socket_tls_set_private_key(wi_socket_tls_t *, wi_rsa_t *);
WI_EXPORT wi_boolean_t					wi_socket_tls_set_dh(wi_socket_tls_t *, const unsigned char *, size_t, const unsigned char *, size_t);
WI_EXPORT wi_boolean_t					wi_socket_tls_set_ciphers(wi_socket_tls_t *, wi_string_t *);


WI_EXPORT wi_runtime_id_t				wi_socket_runtime_id(void);

WI_EXPORT wi_socket_t *					wi_socket_with_address(wi_address_t *, wi_socket_type_t);

WI_EXPORT wi_socket_t *					wi_socket_alloc(void);
WI_EXPORT wi_socket_t *					wi_socket_init_with_address(wi_socket_t *, wi_address_t *, wi_socket_type_t);
WI_EXPORT wi_socket_t *					wi_socket_init_with_descriptor(wi_socket_t *, int);

WI_EXPORT wi_address_t *				wi_socket_address(wi_socket_t *);
WI_EXPORT int							wi_socket_descriptor(wi_socket_t *);
WI_EXPORT void *						wi_socket_ssl(wi_socket_t *);
WI_EXPORT wi_rsa_t *					wi_socket_ssl_public_key(wi_socket_t *);
WI_EXPORT wi_string_t *					wi_socket_cipher_version(wi_socket_t *);
WI_EXPORT wi_string_t *					wi_socket_cipher_name(wi_socket_t *);
WI_EXPORT wi_uinteger_t					wi_socket_cipher_bits(wi_socket_t *);
WI_EXPORT wi_string_t *					wi_socket_certificate_name(wi_socket_t *);
WI_EXPORT wi_uinteger_t					wi_socket_certificate_bits(wi_socket_t *);
WI_EXPORT wi_string_t *					wi_socket_certificate_hostname(wi_socket_t *);

WI_EXPORT void							wi_socket_set_port(wi_socket_t *, wi_uinteger_t);
WI_EXPORT wi_uinteger_t					wi_socket_port(wi_socket_t *);
WI_EXPORT void							wi_socket_set_direction(wi_socket_t *, wi_uinteger_t);
WI_EXPORT wi_uinteger_t					wi_socket_direction(wi_socket_t *);
WI_EXPORT void							wi_socket_set_data(wi_socket_t *, void *);
WI_EXPORT void *						wi_socket_data(wi_socket_t *);
WI_EXPORT wi_boolean_t					wi_socket_set_blocking(wi_socket_t *, wi_boolean_t);
WI_EXPORT wi_boolean_t					wi_socket_blocking(wi_socket_t *);
WI_EXPORT wi_boolean_t					wi_socket_set_timeout(wi_socket_t *, wi_time_interval_t);
WI_EXPORT wi_time_interval_t			wi_socket_timeout(wi_socket_t *);
WI_EXPORT void							wi_socket_set_interactive(wi_socket_t *, wi_boolean_t);
WI_EXPORT wi_boolean_t					wi_socket_interactive(wi_socket_t *);
WI_EXPORT int							wi_socket_error(wi_socket_t *);

WI_EXPORT wi_socket_t *					wi_socket_wait_multiple(wi_array_t *, wi_time_interval_t);
WI_EXPORT wi_socket_state_t				wi_socket_wait(wi_socket_t *, wi_time_interval_t);
WI_EXPORT wi_socket_state_t				wi_socket_wait_descriptor(int, wi_time_interval_t, wi_boolean_t, wi_boolean_t);

WI_EXPORT wi_boolean_t					wi_socket_listen(wi_socket_t *);
WI_EXPORT wi_boolean_t					wi_socket_connect(wi_socket_t *, wi_time_interval_t);
WI_EXPORT wi_boolean_t					wi_socket_connect_tls(wi_socket_t *, wi_socket_tls_t *, wi_time_interval_t);
WI_EXPORT wi_socket_t *					wi_socket_accept_multiple(wi_array_t *, wi_time_interval_t, wi_address_t **);
WI_EXPORT wi_socket_t *					wi_socket_accept(wi_socket_t *, wi_time_interval_t, wi_address_t **);
WI_EXPORT wi_boolean_t					wi_socket_accept_tls(wi_socket_t *, wi_socket_tls_t *, wi_time_interval_t);
WI_EXPORT void							wi_socket_close(wi_socket_t *);

WI_EXPORT wi_integer_t					wi_socket_sendto_format(wi_socket_t *, wi_string_t *, ...);
WI_EXPORT wi_integer_t					wi_socket_sendto_data(wi_socket_t *, wi_data_t *);
WI_EXPORT wi_integer_t					wi_socket_sendto_buffer(wi_socket_t *, const char *, size_t);
WI_EXPORT wi_integer_t					wi_socket_recvfrom_multiple(wi_array_t *, char *, size_t, wi_address_t **);
WI_EXPORT wi_integer_t					wi_socket_recvfrom(wi_socket_t *, char *, size_t, wi_address_t **);

WI_EXPORT wi_integer_t					wi_socket_write_format(wi_socket_t *, wi_time_interval_t, wi_string_t *, ...);
WI_EXPORT wi_integer_t					wi_socket_write_buffer(wi_socket_t *, wi_time_interval_t, const void *, size_t);
WI_EXPORT wi_string_t *					wi_socket_read_string(wi_socket_t *, wi_time_interval_t);
WI_EXPORT wi_string_t *					wi_socket_read_to_string(wi_socket_t *, wi_time_interval_t, wi_string_t *);
WI_EXPORT wi_integer_t					wi_socket_read_buffer(wi_socket_t *, wi_time_interval_t, void *, size_t);

#endif /* WI_SOCKET_H */
