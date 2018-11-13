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

#ifndef WI_DIGEST_H
#define WI_DIGEST_H 1

#include <wired/wi-base.h>
#include <wired/wi-data.h>
#include <wired/wi-runtime.h>

#define WI_MD5_DIGEST_LENGTH			16
#define WI_SHA1_DIGEST_LENGTH			20
#define WI_SHA256_DIGEST_LENGTH			32


typedef struct _wi_md5					wi_md5_t;
typedef struct _wi_sha1					wi_sha1_t;
typedef struct _wi_sha256				wi_sha256_t;


#pragma mark -

WI_EXPORT void							wi_md5_digest(const void *, wi_uinteger_t, unsigned char *);
WI_EXPORT wi_string_t *					wi_md5_digest_string(wi_data_t *);

WI_EXPORT wi_md5_t *					wi_md5(void);

WI_EXPORT wi_md5_t *					wi_md5_alloc(void);
WI_EXPORT wi_md5_t *					wi_md5_init(wi_md5_t *);

WI_EXPORT void							wi_md5_update(wi_md5_t *, const void *, wi_uinteger_t);
WI_EXPORT void							wi_md5_close(wi_md5_t *);

WI_EXPORT void							wi_md5_get_data(wi_md5_t *, unsigned char *);
WI_EXPORT wi_data_t *					wi_md5_data(wi_md5_t *);
WI_EXPORT wi_string_t *					wi_md5_string(wi_md5_t *);

#pragma mark -

WI_EXPORT void							wi_sha1_digest(const void *, wi_uinteger_t, unsigned char *);
WI_EXPORT wi_string_t *					wi_sha1_digest_string(wi_data_t *);

WI_EXPORT wi_sha1_t *					wi_sha1(void);

WI_EXPORT wi_sha1_t *					wi_sha1_alloc(void);
WI_EXPORT wi_sha1_t *					wi_sha1_init(wi_sha1_t *);

WI_EXPORT void							wi_sha1_update(wi_sha1_t *, const void *, wi_uinteger_t);
WI_EXPORT void							wi_sha1_close(wi_sha1_t *);

WI_EXPORT void							wi_sha1_get_data(wi_sha1_t *, unsigned char *);
WI_EXPORT wi_data_t *					wi_sha1_data(wi_sha1_t *);
WI_EXPORT wi_string_t *					wi_sha1_string(wi_sha1_t *);

#pragma mark -

WI_EXPORT void							wi_sha256_digest(const void *, wi_uinteger_t, unsigned char *);
WI_EXPORT wi_string_t *					wi_sha256_digest_string(wi_data_t *);

WI_EXPORT wi_sha256_t *					wi_sha256(void);

WI_EXPORT wi_sha256_t *					wi_sha256_alloc(void);
WI_EXPORT wi_sha256_t *					wi_sha256_init(wi_sha256_t *);

WI_EXPORT void							wi_sha256_update(wi_sha256_t *, const void *, wi_uinteger_t);
WI_EXPORT void							wi_sha256_close(wi_sha256_t *);

WI_EXPORT void							wi_sha256_get_data(wi_sha256_t *, unsigned char *);
WI_EXPORT wi_data_t *					wi_sha256_data(wi_sha256_t *);
WI_EXPORT wi_string_t *					wi_sha256_string(wi_sha256_t *);


#pragma mark -

WI_EXPORT wi_string_t *					wi_base64_string_from_data(wi_data_t *);
WI_EXPORT wi_data_t *					wi_data_from_base64_string(wi_string_t *);

#endif /* WI_DIGEST_H */
