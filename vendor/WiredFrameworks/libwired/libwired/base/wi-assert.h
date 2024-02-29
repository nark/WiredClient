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
 * @file wi-assert.h 
 * @brief Providing support for Wired assertion coding
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 *
 */

#ifndef WI_ASSERT_H
#define WI_ASSERT_H 1

#include <wired/wi-base.h>
#include <wired/wi-macros.h>
#include <wired/wi-log.h>

#define WI_ASSERT(exp, fmt, ...)								\
	WI_STMT_START												\
		if(!(exp)) {											\
			(*wi_assert_handler)(__FILE__, __LINE__,			\
				WI_STR(fmt), ## __VA_ARGS__);					\
		}														\
	WI_STMT_END


typedef void							wi_assert_handler_func_t(const char *, unsigned int, wi_string_t *, ...);


WI_EXPORT wi_assert_handler_func_t		*wi_assert_handler;

#endif /* WI_ASSERT_H */
