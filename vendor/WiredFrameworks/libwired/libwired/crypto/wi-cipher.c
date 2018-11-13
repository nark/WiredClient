/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
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

#if !defined(HAVE_OPENSSL_SHA_H) && !defined(HAVE_COMMONCRYPTO_COMMONCRYPTOR_H)

int wi_cipher_dummy = 1;

#else

#include <wired/wi-data.h>
#include <wired/wi-cipher.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#ifdef HAVE_COMMONCRYPTO_COMMONCRYPTOR_H
#define WI_CIPHER_COMMONCRYPTO			1
#else
#define WI_CIPHER_OPENSSL				1
#endif
// Force OpenSSL cipher
//#define WI_CIPHER_OPENSSL				1

#ifdef HAVE_OPENSSL_SHA_H
#include <openssl/evp.h>
#include <openssl/rand.h>
#endif

#ifdef HAVE_COMMONCRYPTO_COMMONCRYPTOR_H
#include <CommonCrypto/CommonCryptor.h>
#endif


struct _wi_cipher {
	wi_runtime_base_t					base;
	
	wi_cipher_type_t					type;
	wi_data_t							*key;
	wi_data_t							*iv;
	
#ifdef WI_CIPHER_OPENSSL
	const EVP_CIPHER					*cipher;
	EVP_CIPHER_CTX						encrypt_ctx;
	EVP_CIPHER_CTX						decrypt_ctx;
#endif
	
#ifdef WI_CIPHER_COMMONCRYPTO
	CCAlgorithm							algorithm;
	CCCryptorRef						encrypt_ref;
	CCCryptorRef						decrypt_ref;
#endif
};


static wi_cipher_t *					_wi_cipher_init_with_key(wi_cipher_t *, wi_data_t *, wi_data_t *);
static void								_wi_cipher_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_cipher_description(wi_runtime_instance_t *);

static wi_boolean_t						_wi_cipher_set_type(wi_cipher_t *, wi_cipher_type_t);

#ifdef WI_CIPHER_OPENSSL
static void								_wi_cipher_configure_cipher(wi_cipher_t *);
#endif


static wi_runtime_id_t					_wi_cipher_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_cipher_runtime_class = {
	"wi_cipher_t",
	_wi_cipher_dealloc,
	NULL,
	NULL,
	_wi_cipher_description,
	NULL
};



void wi_cipher_register(void) {
	_wi_cipher_runtime_id = wi_runtime_register_class(&_wi_cipher_runtime_class);
}



void wi_cipher_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_cipher_runtime_id(void) {
	return _wi_cipher_runtime_id;
}



#pragma mark -

wi_cipher_t * wi_cipher_alloc(void) {
	return wi_runtime_create_instance(_wi_cipher_runtime_id, sizeof(wi_cipher_t));
}



wi_cipher_t * wi_cipher_init_with_key(wi_cipher_t *cipher, wi_cipher_type_t type, wi_data_t *key, wi_data_t *iv) {
	if(!_wi_cipher_set_type(cipher, type)) {
		wi_error_set_libwired_error(WI_ERROR_CIPHER_CIPHERNOTSUPP);
		
		wi_release(cipher);
		
		return NULL;
	}
	
	return _wi_cipher_init_with_key(cipher, key, iv);
}



wi_cipher_t * wi_cipher_init_with_random_key(wi_cipher_t *cipher, wi_cipher_type_t type) {
	wi_data_t			*key, *iv;

	if(!_wi_cipher_set_type(cipher, type)) {
		wi_error_set_libwired_error(WI_ERROR_CIPHER_CIPHERNOTSUPP);
		
		wi_release(cipher);
		
		return NULL;
	}
	
	key = wi_data_with_random_bytes(wi_cipher_bits(cipher) / 8);
	iv = wi_data_with_random_bytes(wi_cipher_block_size(cipher));
	
	return _wi_cipher_init_with_key(cipher, key, iv);
}



static wi_cipher_t * _wi_cipher_init_with_key(wi_cipher_t *cipher, wi_data_t *key, wi_data_t *iv) {
#ifdef WI_CIPHER_COMMONCRYPTO
	CCCryptorStatus		status;
#endif
	unsigned char		*key_buffer, *iv_buffer;
	
	key_buffer			= (unsigned char *) wi_data_bytes(key);
	iv_buffer			= iv ? (unsigned char *) wi_data_bytes(iv) : NULL;

	cipher->key			= wi_retain(key);
	cipher->iv			= wi_retain(iv);
	
#ifdef WI_CIPHER_OPENSSL    
	if(EVP_EncryptInit(&cipher->encrypt_ctx, cipher->cipher, NULL, NULL) != 1) {
		wi_error_set_openssl_error();
		
		wi_release(cipher);
		
		return NULL;
	}
	
	if(EVP_DecryptInit(&cipher->decrypt_ctx, cipher->cipher, NULL, NULL) != 1) {
		wi_error_set_openssl_error();
		
		wi_release(cipher);
		
		return NULL;
	}
	
	_wi_cipher_configure_cipher(cipher);
	
	if(EVP_EncryptInit(&cipher->encrypt_ctx, cipher->cipher, key_buffer, iv_buffer) != 1) {
		wi_error_set_openssl_error();
		
		wi_release(cipher);
		
		return NULL;
	}
	
	if(EVP_DecryptInit(&cipher->decrypt_ctx, cipher->cipher, key_buffer, iv_buffer) != 1) {
		wi_error_set_openssl_error();
		
		wi_release(cipher);
		
		return NULL;
	}
#endif
	
#ifdef WI_CIPHER_COMMONCRYPTO
	status = CCCryptorCreate(kCCEncrypt,
							 cipher->algorithm,
							 kCCOptionPKCS7Padding,
							 key_buffer,
							 wi_data_length(cipher->key),
							 iv_buffer,
							 &cipher->encrypt_ref);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		wi_release(cipher);
		
		return NULL;
	}
	
	status = CCCryptorCreate(kCCDecrypt,
							 cipher->algorithm,
							 kCCOptionPKCS7Padding,
							 key_buffer,
							 wi_data_length(cipher->key),
							 iv_buffer,
							 &cipher->decrypt_ref);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		wi_release(cipher);
		
		return NULL;
	}
#endif

	return cipher;
}



static void _wi_cipher_dealloc(wi_runtime_instance_t *instance) {
	wi_cipher_t		*cipher = instance;

#ifdef WI_CIPHER_OPENSSL
	EVP_CIPHER_CTX_cleanup(&cipher->encrypt_ctx);
	EVP_CIPHER_CTX_cleanup(&cipher->decrypt_ctx);
#endif
	
#ifdef WI_CIPHER_COMMONCRYPTO
	CCCryptorRelease(cipher->encrypt_ref);
	CCCryptorRelease(cipher->decrypt_ref);
#endif
	
	wi_release(cipher->key);
	wi_release(cipher->iv);
}



static wi_string_t * _wi_cipher_description(wi_runtime_instance_t *instance) {
	wi_cipher_t		*cipher = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{name = %@, bits = %lu, iv = %@, key = %@}"),
        wi_runtime_class_name(cipher),
		cipher,
		wi_cipher_name(cipher),
		wi_cipher_bits(cipher),
		wi_cipher_iv(cipher),
		wi_cipher_key(cipher));
}



#pragma mark -

static wi_boolean_t _wi_cipher_set_type(wi_cipher_t *cipher, wi_cipher_type_t type) {
	cipher->type = type;
	
#ifdef WI_CIPHER_OPENSSL
	switch(cipher->type) {
		case WI_CIPHER_AES128:
			cipher->cipher = EVP_aes_128_cbc();
			return true;
			
		case WI_CIPHER_AES192:
			cipher->cipher = EVP_aes_192_cbc();
			return true;
			
		case WI_CIPHER_AES256:
			cipher->cipher = EVP_aes_256_cbc();
			return true;
			
		case WI_CIPHER_BF128:
			cipher->cipher = EVP_bf_cbc();
			return true;
			
		case WI_CIPHER_3DES192:
			cipher->cipher = EVP_des_ede3_cbc();
			return true;
			
		default:
			return false;
	}
#endif
			
#ifdef WI_CIPHER_COMMONCRYPTO
    printf("WI_CIPHER_COMMONCRYPTO : %d\n", cipher->type);
	switch(cipher->type) {
		case WI_CIPHER_AES128:
		case WI_CIPHER_AES192:
		case WI_CIPHER_AES256:
			cipher->algorithm = kCCAlgorithmAES128;
			return true;
		
		case WI_CIPHER_3DES192:
			cipher->algorithm = kCCAlgorithm3DES;
			return true;
		
		default:
			return false;
	}
#endif
}



#ifdef WI_CIPHER_OPENSSL

static void _wi_cipher_configure_cipher(wi_cipher_t *cipher) {
	if(cipher->type == WI_CIPHER_BF128) {
		EVP_CIPHER_CTX_set_key_length(&cipher->encrypt_ctx, 16);
		EVP_CIPHER_CTX_set_key_length(&cipher->decrypt_ctx, 16);
	}
}

#endif



#pragma mark -

wi_data_t * wi_cipher_key(wi_cipher_t *cipher) {
	return cipher->key;
}



wi_data_t * wi_cipher_iv(wi_cipher_t *cipher) {
	return cipher->iv;
}



wi_cipher_type_t wi_cipher_type(wi_cipher_t *cipher) {
	return cipher->type;
}



wi_string_t * wi_cipher_name(wi_cipher_t *cipher) {
	switch(cipher->type) {
		case WI_CIPHER_AES128:
		case WI_CIPHER_AES192:
		case WI_CIPHER_AES256:
			return WI_STR("AES");

		case WI_CIPHER_BF128:
			return WI_STR("Blowfish");
		
		case WI_CIPHER_3DES192:
			return WI_STR("Triple DES");
	}
	
	return NULL;
}



wi_uinteger_t wi_cipher_bits(wi_cipher_t *cipher) {
#ifdef WI_CIPHER_OPENSSL
	return EVP_CIPHER_key_length(cipher->cipher) * 8;
#endif

#ifdef WI_CIPHER_COMMONCRYPTO
	switch(cipher->type) {
		case WI_CIPHER_AES128:
			return kCCKeySizeAES128 * 8;
			
		case WI_CIPHER_AES192:
			return kCCKeySizeAES192 * 8;
			
		case WI_CIPHER_AES256:
			return kCCKeySizeAES256 * 8;
	
		case WI_CIPHER_3DES192:
			return kCCKeySize3DES * 8;

		default:
			return 0;
	}
#endif
}



wi_uinteger_t wi_cipher_block_size(wi_cipher_t *cipher) {
#ifdef WI_CIPHER_OPENSSL
	return EVP_CIPHER_block_size(cipher->cipher);
#endif
	
#ifdef WI_CIPHER_COMMONCRYPTO
	switch(cipher->type) {
		case WI_CIPHER_AES128:
		case WI_CIPHER_AES192:
		case WI_CIPHER_AES256:
			return kCCBlockSizeAES128;
		
		case WI_CIPHER_3DES192:
			return kCCBlockSize3DES;
		
		default:
			return 0;
	}
#endif
}



#pragma mark -

wi_data_t * wi_cipher_encrypt(wi_cipher_t *cipher, wi_data_t *decrypted_data) {
	const void		*decrypted_buffer;
	void			*encrypted_buffer;
	wi_uinteger_t	decrypted_length;
	wi_integer_t	encrypted_length;
	
	decrypted_buffer = wi_data_bytes(decrypted_data);
	decrypted_length = wi_data_length(decrypted_data);
	encrypted_buffer = wi_malloc(wi_cipher_block_size(cipher) + decrypted_length);
	encrypted_length = wi_cipher_encrypt_bytes(cipher, decrypted_buffer, decrypted_length, encrypted_buffer);
	
	if(encrypted_length < 0)
		return NULL;
	
	return wi_data_with_bytes_no_copy(encrypted_buffer, encrypted_length, true);
}



wi_integer_t wi_cipher_encrypt_bytes(wi_cipher_t *cipher, const void *decrypted_buffer, wi_uinteger_t decrypted_length, void *encrypted_buffer) {
#ifdef WI_CIPHER_OPENSSL
	int			encrypted_length, padded_length;
	
	if(EVP_EncryptUpdate(&cipher->encrypt_ctx, encrypted_buffer, &encrypted_length, decrypted_buffer, decrypted_length) != 1) {
		wi_error_set_openssl_error();
		
		return -1;
	}
	
	if(EVP_EncryptFinal_ex(&cipher->encrypt_ctx, encrypted_buffer + encrypted_length, &padded_length) != 1) {
		wi_error_set_openssl_error();
		
		return -1;
	}
	
	if(EVP_EncryptInit_ex(&cipher->encrypt_ctx, NULL, NULL, NULL, NULL) != 1) {
		wi_error_set_openssl_error();
		
		return -1;
	}
	
	return encrypted_length + padded_length;
#endif

#ifdef WI_CIPHER_COMMONCRYPTO
	CCCryptorStatus		status;
	size_t				available_length, encrypted_length, padded_length;
	
	available_length = wi_cipher_block_size(cipher) + decrypted_length;
	
	status = CCCryptorUpdate(cipher->encrypt_ref,
							 decrypted_buffer,
							 decrypted_length,
							 encrypted_buffer,
							 available_length,
							 &encrypted_length);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		return -1;
	}

	status = CCCryptorFinal(cipher->encrypt_ref,
							encrypted_buffer + encrypted_length,
							available_length - encrypted_length,
							&padded_length);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		return -1;
	}
	status = CCCryptorReset(cipher->encrypt_ref, cipher->iv ? wi_data_bytes(cipher->iv) : NULL);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		return -1;
	}

	return encrypted_length + padded_length;
#endif
}



wi_data_t * wi_cipher_decrypt(wi_cipher_t *cipher, wi_data_t *encrypted_data) {
	const void		*encrypted_buffer;
	void			*decrypted_buffer;
	wi_uinteger_t	encrypted_length;
	wi_integer_t	decrypted_length;
	
	encrypted_buffer = wi_data_bytes(encrypted_data);
	encrypted_length = wi_data_length(encrypted_data);
	decrypted_buffer = wi_malloc(wi_cipher_block_size(cipher) + encrypted_length);
	decrypted_length = wi_cipher_decrypt_bytes(cipher, encrypted_buffer, encrypted_length, decrypted_buffer);
	
	if(decrypted_length < 0)
		return NULL;
	
	return wi_data_with_bytes_no_copy(decrypted_buffer, decrypted_length, true);
}



wi_integer_t wi_cipher_decrypt_bytes(wi_cipher_t *cipher, const void *encrypted_buffer, wi_uinteger_t encrypted_length, void *decrypted_buffer) {
#ifdef WI_CIPHER_OPENSSL
	int			decrypted_length, padded_length;
	
	if(EVP_DecryptUpdate(&cipher->decrypt_ctx, decrypted_buffer, &decrypted_length, encrypted_buffer, encrypted_length) != 1) {
		wi_error_set_openssl_error();
		
		return -1;
	}
	
	if(EVP_DecryptFinal_ex(&cipher->decrypt_ctx, decrypted_buffer + decrypted_length, &padded_length) != 1) {
		wi_error_set_openssl_error();
		
		return -1;
	}
	
	if(EVP_DecryptInit_ex(&cipher->decrypt_ctx, NULL, NULL, NULL, NULL) != 1) {
		wi_error_set_openssl_error();
		
		return -1;
	}
	
	return decrypted_length + padded_length;
#endif

#ifdef WI_CIPHER_COMMONCRYPTO
	CCCryptorStatus		status;
	size_t				available_length, decrypted_length, padded_length;
	
	available_length = wi_cipher_block_size(cipher) + encrypted_length;
	
	status = CCCryptorUpdate(cipher->decrypt_ref,
							 encrypted_buffer,
							 encrypted_length,
							 decrypted_buffer,
							 available_length,
							 &decrypted_length);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		return -1;
	}

	status = CCCryptorFinal(cipher->decrypt_ref,
							decrypted_buffer + decrypted_length,
							available_length - decrypted_length,
							&padded_length);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		return -1;
	}
	
	status = CCCryptorReset(cipher->decrypt_ref, cipher->iv ? wi_data_bytes(cipher->iv) : NULL);
	
	if(status != kCCSuccess) {
		wi_error_set_commoncrypto_error(status);
		
		return -1;
	}
	
	return decrypted_length + padded_length;
#endif
}

#endif
