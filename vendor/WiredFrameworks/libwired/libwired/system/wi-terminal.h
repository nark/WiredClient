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

#ifndef WI_TERMINAL_H
#define WI_TERMINAL_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_terminal				wi_terminal_t;

typedef struct _wi_terminal_buffer		wi_terminal_buffer_t;


WI_EXPORT wi_runtime_id_t				wi_terminal_runtime_id(void);

WI_EXPORT wi_terminal_t *				wi_terminal_alloc(void);
WI_EXPORT wi_terminal_t *				wi_terminal_init(wi_terminal_t *);
WI_EXPORT wi_terminal_t *				wi_terminal_init_with_type(wi_terminal_t *, wi_string_t *);

WI_EXPORT void							wi_terminal_add_buffer(wi_terminal_t *, wi_terminal_buffer_t *);
WI_EXPORT void							wi_terminal_remove_buffer(wi_terminal_t *, wi_terminal_buffer_t *);
WI_EXPORT void							wi_terminal_set_active_buffer(wi_terminal_t *, wi_terminal_buffer_t *);
WI_EXPORT wi_terminal_buffer_t *		wi_terminal_active_buffer(wi_terminal_t *);

WI_EXPORT void							wi_terminal_set_size(wi_terminal_t *, wi_size_t);
WI_EXPORT wi_size_t						wi_terminal_lookup_size(wi_terminal_t *);
WI_EXPORT wi_size_t						wi_terminal_size(wi_terminal_t *);
WI_EXPORT void							wi_terminal_set_scroll(wi_terminal_t *, wi_range_t);
WI_EXPORT wi_range_t					wi_terminal_scroll(wi_terminal_t *);
WI_EXPORT void							wi_terminal_move(wi_terminal_t *, wi_point_t);
WI_EXPORT void							wi_terminal_printf(wi_terminal_t *, wi_string_t *, ...);
WI_EXPORT void							wi_terminal_move_printf(wi_terminal_t *, wi_point_t, wi_string_t *, ...);
WI_EXPORT wi_point_t					wi_terminal_location(wi_terminal_t *);
WI_EXPORT void							wi_terminal_clear_screen(wi_terminal_t *);
WI_EXPORT void							wi_terminal_clear_line(wi_terminal_t *);
WI_EXPORT void							wi_terminal_close(wi_terminal_t *);

WI_EXPORT wi_uinteger_t					wi_terminal_index_of_string_for_width(wi_terminal_t *, wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_uinteger_t					wi_terminal_width_of_string(wi_terminal_t *, wi_string_t *);
WI_EXPORT void							wi_terminal_adjust_string_to_fit_width(wi_terminal_t *, wi_mutable_string_t *);
WI_EXPORT wi_string_t *					wi_terminal_string_by_adjusting_to_fit_width(wi_terminal_t *, wi_string_t *);


WI_EXPORT wi_runtime_id_t				wi_terminal_buffer_runtime_id(void);

WI_EXPORT wi_terminal_buffer_t *		wi_terminal_buffer_alloc(void);
WI_EXPORT wi_terminal_buffer_t *		wi_terminal_buffer_init_with_terminal(wi_terminal_buffer_t *, wi_terminal_t *);

WI_EXPORT wi_uinteger_t					wi_terminal_buffer_lines(wi_terminal_buffer_t *);
WI_EXPORT wi_uinteger_t					wi_terminal_buffer_current_line(wi_terminal_buffer_t *);
WI_EXPORT wi_string_t *					wi_terminal_buffer_string(wi_terminal_buffer_t *);

WI_EXPORT wi_boolean_t					wi_terminal_buffer_printf(wi_terminal_buffer_t *, wi_string_t *, ...);
WI_EXPORT void							wi_terminal_buffer_clear(wi_terminal_buffer_t *);

WI_EXPORT void							wi_terminal_buffer_redraw(wi_terminal_buffer_t *);
WI_EXPORT void							wi_terminal_buffer_pageup(wi_terminal_buffer_t *);
WI_EXPORT void							wi_terminal_buffer_pagedown(wi_terminal_buffer_t *);
WI_EXPORT void							wi_terminal_buffer_home(wi_terminal_buffer_t *);
WI_EXPORT void							wi_terminal_buffer_end(wi_terminal_buffer_t *);

#endif /* WI_TERMINAL_H */
