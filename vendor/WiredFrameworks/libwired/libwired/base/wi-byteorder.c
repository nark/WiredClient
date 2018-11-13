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

#include <wired/wi-byteorder.h>

#include <math.h>

/* Copyright (C) 1989-1991 Apple Computer, Inc.
 *
 * All rights reserved.
 *
 * Warranty Information
 *  Even though Apple has reviewed this software, Apple makes no warranty
 *  or representation, either express or implied, with respect to this
 *  software, its quality, accuracy, merchantability, or fitness for a
 *  particular purpose.  As a result, this software is provided "as is,"
 *  and you, its user, are assuming the entire risk as to its quality
 *  and accuracy.
 *
 * This code may be used and freely distributed as long as it includes
 * this copyright notice and the above warranty information.
 *
 * Machine-independent I/O routines for IEEE floating-point numbers.
 *
 * NaN's and infinities are converted to HUGE_VAL or HUGE, which
 * happens to be infinity on IEEE machines.  Unfortunately, it is
 * impossible to preserve NaN's in a machine-independent way.
 * Infinities are, however, preserved on IEEE machines.
 *
 * These routines have been tested on the following machines:
 *	Apple Macintosh, MPW 3.1 C compiler
 *	Apple Macintosh, THINK C compiler
 *	Silicon Graphics IRIS, MIPS compiler
 *	Cray X/MP and Y/MP
 *	Digital Equipment VAX
 *	Sequent Balance (Multiprocesor 386)
 *	NeXT
 *
 *
 * Implemented by Malcolm Slaney and Ken Turkowski.
 *
 * Malcolm Slaney contributions during 1988-1990 include big- and little-
 * endian file I/O, conversion to and from Motorola's extended 80-bit
 * floating-point format, and conversions to and from IEEE single-
 * precision floating-point format.
 *
 * In 1991, Ken Turkowski implemented the conversions to and from
 * IEEE double-precision format, added more precision to the extended
 * conversions, and accommodated conversions involving +/- infinity,
 * NaN's, and denormalized numbers.
 */

#define _WI_BYTEORDER_IEEE754_EXP_MAX			2047
#define _WI_BYTEORDER_IEEE754_EXP_OFFSET		1023
#define _WI_BYTEORDER_IEEE754_EXP_SIZE			11
#define _WI_BYTEORDER_IEEE754_EXP_POSITION		(32 - _WI_BYTEORDER_IEEE754_EXP_SIZE - 1)


double wi_read_double_from_ieee754(void *base, uintptr_t offset) {
	unsigned char	*bytes;
	double			value;
	int32_t			mantissa, exp;
	uint32_t		first, second;
	
	bytes	= base + offset;
	first	= (((uint32_t) (bytes[0] & 0xFF) << 24) |
			   ((uint32_t) (bytes[1] & 0xFF) << 16) |
			   ((uint32_t) (bytes[2] & 0xFF) <<  8) |
			    (uint32_t) (bytes[3] & 0xFF));
	second	= (((uint32_t) (bytes[4] & 0xFF) << 24) |
			   ((uint32_t) (bytes[5] & 0xFF) << 16) |
			   ((uint32_t) (bytes[6] & 0xFF) <<  8) |
			    (uint32_t) (bytes[7] & 0xFF));
	
	if(first == 0 && second == 0) {
		value = 0.0;
	} else {
		exp = (first & 0x7FF00000) >> _WI_BYTEORDER_IEEE754_EXP_POSITION;
		
		if(exp == _WI_BYTEORDER_IEEE754_EXP_MAX) {	/* Infinity or NaN */
			value = HUGE_VAL;	/* Map NaN's to infinity */
		} else {
			if(exp == 0) {	/* Denormalized number */
				mantissa	= (first & 0x000FFFFF);
				value		= ldexp((double) mantissa, exp - _WI_BYTEORDER_IEEE754_EXP_OFFSET - _WI_BYTEORDER_IEEE754_EXP_POSITION + 1);
				value		+= ldexp((double) second,  exp - _WI_BYTEORDER_IEEE754_EXP_OFFSET - _WI_BYTEORDER_IEEE754_EXP_POSITION + 1 - 32);
			} else {	/* Normalized number */
				mantissa	= (first & 0x000FFFFF) + 0x00100000;	/* Insert hidden bit */
				value		= ldexp((double) mantissa, exp - _WI_BYTEORDER_IEEE754_EXP_OFFSET - _WI_BYTEORDER_IEEE754_EXP_POSITION);
				value		+= ldexp((double) second,  exp - _WI_BYTEORDER_IEEE754_EXP_OFFSET - _WI_BYTEORDER_IEEE754_EXP_POSITION - 32);
			}
		}
	}
	
	if(first & 0x80000000)
		return -value;
	else
		return value;
}



void wi_write_double_to_ieee754(void *base, uintptr_t offset, double value) {
	unsigned char	*bytes;
	double			fmantissa, fsmantissa;
	int32_t			sign, exp, mantissa, shift;
	uint32_t		first, second;
	
	bytes = base + offset;
	
	if(value < 0.0) {	/* Can't distinguish a negative zero */
		sign	= 0x80000000;
		value	*= -1;
	} else {
		sign	= 0;
	}
	
	if(value == 0.0) {
		first	= 0;
		second	= 0;
	} else {
		fmantissa = frexp(value, &exp);
		
		if((exp > _WI_BYTEORDER_IEEE754_EXP_MAX - _WI_BYTEORDER_IEEE754_EXP_OFFSET + 1) || !(fmantissa < 1.0)) {
			/* NaN's and infinities fail second test */
			first = sign | 0x7FF00000;	/* +/- infinity */
			second = 0;
		} else {
			if (exp < -(_WI_BYTEORDER_IEEE754_EXP_OFFSET - 2)) {	/* Smaller than normalized */
				shift = (_WI_BYTEORDER_IEEE754_EXP_POSITION + 1) + (_WI_BYTEORDER_IEEE754_EXP_OFFSET - 2) + exp;
				
				if(shift < 0) {	/* Too small for something in the MS word */
					first = sign;
					shift += 32;
					
					if(shift < 0)	/* Way too small: flush to zero */
						second = 0;
					else			/* Pretty small demorn */
						second = (uint32_t) floor(ldexp(fmantissa, shift));
				} else {			/* Nonzero denormalized number */
					fsmantissa	= ldexp(fmantissa, shift);
					mantissa	= (int32_t) floor(fsmantissa);
					first		= sign | mantissa;
					second		= (uint32_t) floor(ldexp(fsmantissa - mantissa, 32));
				}
			} else {	/* Normalized number */
				fsmantissa	= ldexp(fmantissa, _WI_BYTEORDER_IEEE754_EXP_POSITION + 1);
				mantissa	= (int32_t) floor(fsmantissa);
				mantissa	-= (1L << _WI_BYTEORDER_IEEE754_EXP_POSITION);	/* Hide MSB */
				fsmantissa	-= (1L << _WI_BYTEORDER_IEEE754_EXP_POSITION);
				first		= sign | ((int32_t) ((exp + _WI_BYTEORDER_IEEE754_EXP_OFFSET - 1)) << _WI_BYTEORDER_IEEE754_EXP_POSITION) | mantissa;
				second		= (uint32_t) floor(ldexp(fsmantissa - mantissa, 32));
			}
		}
	}
	
	bytes[0] = first >> 24;
	bytes[1] = first >> 16;
	bytes[2] = first >>  8;
	bytes[3] = first;
	bytes[4] = second >> 24;
	bytes[5] = second >> 16;
	bytes[6] = second >>  8;
	bytes[7] = second;
}
