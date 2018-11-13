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

#ifndef WI_TERMCAP

int wi_terminal_dummy = 0;

#else

#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#ifdef HAVE_CURSES_H
#include <curses.h>
#endif

#if defined(HAVE_TERM_H)
#include <term.h>
#elif defined(HAVE_TERMCAP_H)
#include <termcap.h>
#endif

#ifdef HAVE_TERMIOS_H
#include <termios.h>
#endif

#include <wired/wi-array.h>
#include <wired/wi-base.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>
#include <wired/wi-terminal.h>

#define _WI_TERMINAL_FLUSH_BUFFER_SIZE			32
#define _WI_TERMINAL_TEXTBUFFER_CAPACITY		10240
#define _WI_TERMINAL_LINEBUFFER_CAPACITY		10000


struct _wi_terminal {
	wi_runtime_base_t							base;
	
	wi_uinteger_t								co;
	wi_uinteger_t								li;
	
	wi_point_t									location;
	wi_range_t									scroll;
	
	char										*ce;
	char										*cl;
	char										*cm;
	char										*cs;
	
	wi_terminal_buffer_t						*active_buffer;
	
	wi_mutable_array_t							*buffers;
};

struct _wi_terminal_buffer {
	wi_runtime_base_t							base;
	
	wi_terminal_t								*terminal;
	
	wi_uinteger_t								line;
	
	wi_mutable_string_t							*textbuffer;
	wi_mutable_array_t							*linebuffer;
};


static void										_wi_terminal_puts(wi_terminal_t *, wi_string_t *);
static int										_wi_terminal_putc(int);
static void										_wi_terminal_flush(void);

static wi_uinteger_t							_wi_terminal_get_string_width(wi_string_t *, wi_uinteger_t);

static void										_wi_terminal_dealloc(wi_runtime_instance_t *);

static void										_wi_terminal_buffer_dealloc(wi_runtime_instance_t *);

static void										_wi_terminal_buffer_draw_line(wi_terminal_buffer_t *, wi_uinteger_t);
static wi_mutable_array_t *						_wi_terminal_buffer_lines_for_string(wi_terminal_buffer_t *, wi_string_t *);
static void										_wi_terminal_buffer_reload(wi_terminal_buffer_t *);


static char										_wi_terminal_flush_buffer[_WI_TERMINAL_FLUSH_BUFFER_SIZE];
static wi_uinteger_t							_wi_terminal_flush_offset;

static wi_runtime_id_t							_wi_terminal_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t						_wi_terminal_runtime_class = {
	"wi_terminal_t",
	_wi_terminal_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};

static wi_runtime_id_t							_wi_terminal_buffer_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t						_wi_terminal_buffer_runtime_class = {
	"wi_terminal_buffer_t",
	_wi_terminal_buffer_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};



void wi_terminal_register(void) {
	_wi_terminal_runtime_id = wi_runtime_register_class(&_wi_terminal_runtime_class);
	_wi_terminal_buffer_runtime_id = wi_runtime_register_class(&_wi_terminal_buffer_runtime_class);
}



void wi_terminal_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_terminal_runtime_id(void) {
	return _wi_terminal_runtime_id;
}



#pragma mark -

wi_terminal_t * wi_terminal_alloc(void) {
	return wi_runtime_create_instance(_wi_terminal_runtime_id, sizeof(wi_terminal_t));
}



wi_terminal_t * wi_terminal_init(wi_terminal_t *terminal) {
	wi_string_t		*type;
	const char		*term;
	
	term = getenv("TERM");
		
	if(!term)
		term = "vt100";
	
	type = wi_string_init_with_cstring(wi_string_alloc(), term);
	terminal = wi_terminal_init_with_type(terminal, type);
	wi_release(type);
	
	return terminal;
}



wi_terminal_t * wi_terminal_init_with_type(wi_terminal_t *terminal, wi_string_t *type) {
	char		*env;
	int			err, co, li;
	
	err = tgetent(NULL, wi_string_cstring(type));
	
	if(err <= 0) {
		if(err == 0)
			wi_error_set_libwired_error(WI_ERROR_TERMCAP_NOSUCHENTRY);
		else
			wi_error_set_libwired_error(WI_ERROR_TERMCAP_TERMINFONOTFOUND);

		wi_release(terminal);
		
		return NULL;
	}

	env = getenv("COLUMNS");
	co = env ? strtol(env, NULL, 10) : tgetnum("co");
	terminal->co = (co <= 0) ? 80 : co;

	env = getenv("LINES");
	li = env ? strtol(env, NULL, 10) : tgetnum("li");
	terminal->li = (li <= 0) ? 24 : li;

	terminal->ce = (char *) tgetstr("ce", NULL);
	terminal->cl = (char *) tgetstr("cl", NULL);
	terminal->cm = (char *) tgetstr("cm", NULL);
	terminal->cs = (char *) tgetstr("cs", NULL);
	
	terminal->scroll	= wi_make_range(0, terminal->li);
	terminal->buffers	= wi_array_init_with_capacity(wi_mutable_array_alloc(), 10);
	
	return terminal;
}





static void _wi_terminal_dealloc(wi_runtime_instance_t *instance) {
	wi_terminal_t		*terminal = instance;

	wi_terminal_close(terminal);
}



#pragma mark -

static void _wi_terminal_puts(wi_terminal_t *terminal, wi_string_t *string) {
	write(STDOUT_FILENO, wi_string_cstring(string), wi_string_length(string));
}



static int _wi_terminal_putc(int ch) {
	if(_wi_terminal_flush_offset == _WI_TERMINAL_FLUSH_BUFFER_SIZE)
		_wi_terminal_flush();

	_wi_terminal_flush_buffer[_wi_terminal_flush_offset] = (char) ch;
	_wi_terminal_flush_offset++;

	return ch;
}



static void _wi_terminal_flush(void) {
	write(STDOUT_FILENO, _wi_terminal_flush_buffer, _wi_terminal_flush_offset);

	_wi_terminal_flush_offset = 0;
}



#pragma mark -

wi_uinteger_t wi_terminal_index_of_string_for_width(wi_terminal_t *terminal, wi_string_t *string, wi_uinteger_t width) {
	return _wi_terminal_get_string_width(string, width);
}



wi_uinteger_t wi_terminal_width_of_string(wi_terminal_t *terminal, wi_string_t *string) {
	return _wi_terminal_get_string_width(string, 0);
}



void wi_terminal_adjust_string_to_fit_width(wi_terminal_t *terminal, wi_mutable_string_t *string) {
	wi_uinteger_t	index;
	
	if(wi_terminal_width_of_string(terminal, string) > terminal->co) {
		index = wi_terminal_index_of_string_for_width(terminal, string, terminal->co);
		
		wi_mutable_string_delete_characters_from_index(string, index);
	} else {
		while(wi_terminal_width_of_string(terminal, string) < terminal->co)
			wi_mutable_string_append_string(string, WI_STR(" "));
	}
}



wi_string_t * wi_terminal_string_by_adjusting_to_fit_width(wi_terminal_t *terminal, wi_string_t *string) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_terminal_adjust_string_to_fit_width(terminal, newstring);
	
	wi_runtime_make_immutable(newstring);
	
	return newstring;
}



static wi_uinteger_t _wi_terminal_get_string_width(wi_string_t *string, wi_uinteger_t indexwidth) {
	const char			*cstring, *ocstring;
	wi_uinteger_t		width;
	unsigned char		ch;

	ocstring = cstring = wi_string_cstring(string);
	width = 0;
	
	while((ch = *cstring)) {
		if(ch == 27) {
			while(*cstring && *cstring++ != 'm')
				;
		} else {
			width++;
			cstring++;
		}
		
		if(indexwidth > 0 && indexwidth == width)
			return cstring - ocstring;
	}

	return width;
}



#pragma mark -

void wi_terminal_add_buffer(wi_terminal_t *terminal, wi_terminal_buffer_t *buffer) {
	wi_mutable_array_add_data(terminal->buffers, buffer);
}



void wi_terminal_remove_buffer(wi_terminal_t *terminal, wi_terminal_buffer_t *buffer) {
	wi_uinteger_t	index;
	
	index = wi_array_index_of_data(terminal->buffers, buffer);
	
	if(index != WI_NOT_FOUND)
		wi_mutable_array_remove_data_at_index(terminal->buffers, index);
}



void wi_terminal_set_active_buffer(wi_terminal_t *terminal, wi_terminal_buffer_t *buffer) {
	terminal->active_buffer = buffer;
}



wi_terminal_buffer_t * wi_terminal_active_buffer(wi_terminal_t *terminal) {
	return terminal->active_buffer;
}



#pragma mark -

void wi_terminal_set_size(wi_terminal_t *terminal, wi_size_t size) {
	wi_enumerator_t			*enumerator;
	wi_terminal_buffer_t	*buffer;
	
	terminal->co = size.width;
	terminal->li = size.height;
	
	enumerator = wi_array_data_enumerator(terminal->buffers);
	
	while((buffer = wi_enumerator_next_data(enumerator)))
		_wi_terminal_buffer_reload(buffer);
}



wi_size_t wi_terminal_lookup_size(wi_terminal_t *terminal) {
	wi_string_t			*width, *height;
	struct winsize		win;
	
	if(ioctl(STDOUT_FILENO, TIOCGWINSZ, &win) >= 0)
		return wi_make_size(win.ws_col, win.ws_row);

	width	= wi_getenv(WI_STR("COLUMNS"));
	height	= wi_getenv(WI_STR("LINES"));
	
	if(width && height)
		return wi_make_size(wi_string_integer(width), wi_string_integer(height));
	
	return wi_make_size(0, 0);
}



wi_size_t wi_terminal_size(wi_terminal_t *terminal) {
	return wi_make_size(terminal->co, terminal->li);
}



void wi_terminal_set_scroll(wi_terminal_t *terminal, wi_range_t range) {
	terminal->scroll = range;

	tputs(tgoto(terminal->cs, range.length, range.location), 0, _wi_terminal_putc);
	
	_wi_terminal_flush();
}



wi_range_t wi_terminal_scroll(wi_terminal_t *terminal) {
	return terminal->scroll;
}



void wi_terminal_move(wi_terminal_t *terminal, wi_point_t point) {
	terminal->location = point;
	
	tputs(tgoto(terminal->cm, point.x, point.y), 0, _wi_terminal_putc);
	
	_wi_terminal_flush();
}



void wi_terminal_printf(wi_terminal_t *terminal, wi_string_t *fmt, ...) {
	wi_string_t		*string;
	va_list			ap;
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap);
	va_end(ap);
	
	_wi_terminal_puts(terminal, string);
	
	wi_release(string);
}



void wi_terminal_move_printf(wi_terminal_t *terminal, wi_point_t point, wi_string_t *fmt, ...) {
	wi_string_t		*string;
	va_list			ap;
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap);
	va_end(ap);

	wi_terminal_move(terminal, point);
	
	_wi_terminal_puts(terminal, string);
	
	wi_release(string);
}



wi_point_t wi_terminal_location(wi_terminal_t *terminal) {
	return terminal->location;
}



void wi_terminal_clear_screen(wi_terminal_t *terminal) {
	tputs(terminal->cl, 0, _wi_terminal_putc);
	
	_wi_terminal_flush();
}



void wi_terminal_clear_line(wi_terminal_t *terminal) {
	tputs(terminal->ce, 0, _wi_terminal_putc);
	
	_wi_terminal_flush();
}



void wi_terminal_close(wi_terminal_t *terminal) {
	wi_terminal_set_scroll(terminal, wi_make_range(0, terminal->li));
	wi_terminal_move(terminal, wi_make_point(0, terminal->li - 1));
}



#pragma mark -

wi_runtime_id_t wi_terminal_buffer_runtime_id(void) {
	return _wi_terminal_buffer_runtime_id;
}



#pragma mark -

wi_terminal_buffer_t * wi_terminal_buffer_alloc(void) {
	return wi_runtime_create_instance(_wi_terminal_buffer_runtime_id, sizeof(wi_terminal_buffer_t));
}



wi_terminal_buffer_t * wi_terminal_buffer_init_with_terminal(wi_terminal_buffer_t *buffer, wi_terminal_t *terminal) {
	buffer->terminal		= terminal;
	buffer->textbuffer		= wi_string_init_with_capacity(wi_mutable_string_alloc(), _WI_TERMINAL_TEXTBUFFER_CAPACITY);
	buffer->linebuffer		= wi_array_init_with_capacity(wi_mutable_array_alloc(), _WI_TERMINAL_LINEBUFFER_CAPACITY);
	
	return buffer;
}



static void _wi_terminal_buffer_dealloc(wi_runtime_instance_t *instance) {
	wi_terminal_buffer_t		*buffer = instance;
	
	wi_release(buffer->textbuffer);
	wi_release(buffer->linebuffer);
}



#pragma mark -

wi_uinteger_t wi_terminal_buffer_lines(wi_terminal_buffer_t *buffer) {
	return wi_array_count(buffer->linebuffer);
}



wi_uinteger_t wi_terminal_buffer_current_line(wi_terminal_buffer_t *buffer) {
	return buffer->line;
}



wi_string_t * wi_terminal_buffer_string(wi_terminal_buffer_t *buffer) {
	return buffer->textbuffer;
}



#pragma mark -

static void _wi_terminal_buffer_draw_line(wi_terminal_buffer_t *buffer, wi_uinteger_t line) {
	wi_point_t		location;
	wi_range_t		scroll;
	wi_uinteger_t	i, count;
	
	location	= wi_terminal_location(buffer->terminal);
	scroll		= wi_terminal_scroll(buffer->terminal);
	count		= wi_array_count(buffer->linebuffer);
	
	if(line < scroll.length)
		wi_terminal_move(buffer->terminal, wi_make_point(0, scroll.length - line));
	else
		wi_terminal_move(buffer->terminal, wi_make_point(0, scroll.location));
	
	buffer->line = line;

	for(i = line; i < count && i < line + scroll.length; i++) {
		_wi_terminal_puts(buffer->terminal, WI_STR("\n"));
		_wi_terminal_puts(buffer->terminal, WI_ARRAY(buffer->linebuffer, i));

		buffer->line++;
	}
	
	wi_terminal_move(buffer->terminal, location);
}



static wi_mutable_array_t * _wi_terminal_buffer_lines_for_string(wi_terminal_buffer_t *buffer, wi_string_t *string) {
	wi_enumerator_t			*enumerator;
	wi_mutable_array_t		*array;
	wi_mutable_string_t		*newstring;
 	wi_string_t				*line, *subline;
	wi_size_t				size;
	wi_uinteger_t			index;
	
	array		= wi_array_init(wi_mutable_array_alloc());
	size		= wi_terminal_size(buffer->terminal);
	enumerator	= wi_array_data_enumerator(wi_string_components_separated_by_string(string, WI_STR("\n")));
	
	while((line = wi_enumerator_next_data(enumerator))) {
		if(wi_terminal_width_of_string(buffer->terminal, line) < size.width) {
			wi_mutable_array_add_data(array, line);
		} else {
			newstring = wi_mutable_copy(line);
			
			do {
				index		= wi_terminal_index_of_string_for_width(buffer->terminal, newstring, size.width);
				subline		= wi_string_substring_to_index(newstring, index);

				wi_mutable_array_add_data(array, subline);
				wi_mutable_string_delete_characters_to_index(newstring, wi_string_length(subline));
			} while(wi_terminal_width_of_string(buffer->terminal, newstring) >= size.width);
			
			wi_mutable_array_add_data(array, newstring);
			wi_release(newstring);
		}
	}
	
	return wi_autorelease(array);
}



static void _wi_terminal_buffer_reload(wi_terminal_buffer_t *buffer) {
	wi_mutable_array_t		*array;

	array = _wi_terminal_buffer_lines_for_string(buffer, buffer->textbuffer);
	wi_release(buffer->linebuffer);
	
	buffer->linebuffer = wi_retain(array);
}



#pragma mark -

wi_boolean_t wi_terminal_buffer_printf(wi_terminal_buffer_t *buffer, wi_string_t *fmt, ...) {
	wi_enumerator_t	*enumerator;
	wi_array_t		*array;
	wi_string_t		*string, *line;
	wi_point_t		location;
	va_list			ap;
	wi_boolean_t	result = false;
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap);
	va_end(ap);
	
	array = _wi_terminal_buffer_lines_for_string(buffer, string);

	if(buffer->terminal->active_buffer == buffer) {
		if(buffer->line == wi_array_count(buffer->linebuffer)) {
			location = wi_terminal_location(buffer->terminal);
			wi_terminal_move(buffer->terminal, wi_make_point(0, wi_terminal_scroll(buffer->terminal).length));
			
			enumerator = wi_array_data_enumerator(array);
			
			while((line = wi_enumerator_next_data(enumerator))) {
				_wi_terminal_puts(buffer->terminal, WI_STR("\n"));
				_wi_terminal_puts(buffer->terminal, line);
				
				buffer->line++;
			}
			
			wi_terminal_move(buffer->terminal, location);
			
			result = true;
		}
	}
	
	if(wi_string_length(buffer->textbuffer) > 0)
		wi_mutable_string_append_string(buffer->textbuffer, WI_STR("\n"));

	wi_mutable_string_append_string(buffer->textbuffer, string);
	
	wi_mutable_array_add_data_from_array(buffer->linebuffer, array);
	
	wi_release(string);
	
	return result;
}



void wi_terminal_buffer_clear(wi_terminal_buffer_t *buffer) {
	buffer->line = 0;

	wi_mutable_string_set_string(buffer->textbuffer, WI_STR(""));
	wi_mutable_array_remove_all_data(buffer->linebuffer);
}



#pragma mark -

void wi_terminal_buffer_redraw(wi_terminal_buffer_t *buffer) {
	wi_range_t		scroll;
	wi_uinteger_t	line;
	
	scroll		= wi_terminal_scroll(buffer->terminal);
	line		= buffer->line < scroll.length ? 0 : buffer->line - scroll.length;

	_wi_terminal_buffer_draw_line(buffer, line);
}



void wi_terminal_buffer_pageup(wi_terminal_buffer_t *buffer) {
	wi_range_t		scroll;
	wi_uinteger_t	line, step;
	
	scroll		= wi_terminal_scroll(buffer->terminal);
	step		= scroll.length * 2;
	line		= buffer->line < step ? 0 : buffer->line - step;

	_wi_terminal_buffer_draw_line(buffer, line);
}



void wi_terminal_buffer_pagedown(wi_terminal_buffer_t *buffer) {
	wi_range_t		scroll;
	wi_uinteger_t	line, end;
	
	scroll		= wi_terminal_scroll(buffer->terminal);
	end			= wi_array_count(buffer->linebuffer);
	
	if(end < scroll.length)
		line = 0;
	else
		line = buffer->line < end - scroll.length ? buffer->line : end - scroll.length;
	
	_wi_terminal_buffer_draw_line(buffer, line);
}



void wi_terminal_buffer_home(wi_terminal_buffer_t *buffer) {
	_wi_terminal_buffer_draw_line(buffer, 0);
}



void wi_terminal_buffer_end(wi_terminal_buffer_t *buffer) {
	wi_range_t		scroll;
	wi_uinteger_t	line, end;
	
	scroll		= wi_terminal_scroll(buffer->terminal);
	end			= wi_array_count(buffer->linebuffer);
	line		= end < scroll.length ? 0 : end - scroll.length;
	
	_wi_terminal_buffer_draw_line(buffer, line);
}

#endif
