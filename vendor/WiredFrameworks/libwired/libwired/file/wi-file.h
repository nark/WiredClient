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

#ifndef WI_FILE_H
#define WI_FILE_H 1

#include <sys/types.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <stdio.h>
#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

#define WI_PATH_SIZE				MAXPATHLEN
#define WI_FILE_BUFFER_SIZE			BUFSIZ


typedef uint64_t					wi_file_offset_t;

struct _wi_file_stat {
	uint32_t						dev;
	uint64_t						ino;
	uint32_t						mode;
	uint32_t						nlink;
	uint32_t						uid;
	uint32_t						gid;
	uint32_t						rdev;
	uint32_t						atime;
	uint32_t						mtime;
	uint32_t						ctime;
	uint32_t						birthtime;
	uint64_t						size;
	uint64_t						blocks;
	uint32_t						blksize;
};
typedef struct _wi_file_stat		wi_file_stat_t;

struct _wi_file_statfs {
	uint32_t						bsize;
	uint32_t						frsize;
	uint64_t						blocks;
	uint64_t						bfree;
	uint64_t						bavail;
	uint64_t						files;
	uint64_t						ffree;
	uint64_t						favail;
	uint32_t						fsid;
	uint64_t						flag;
	uint64_t						namemax;
};
typedef struct _wi_file_statfs		wi_file_statfs_t;


enum _wi_file_mode {
	WI_FILE_READING					= (1 << 0),
	WI_FILE_WRITING					= (1 << 1),
	WI_FILE_UPDATING				= (1 << 2)
};
typedef enum _wi_file_mode			wi_file_mode_t;


typedef struct _wi_file				wi_file_t;


WI_EXPORT wi_boolean_t				wi_file_delete(wi_string_t *);
WI_EXPORT wi_boolean_t				wi_file_clear(wi_string_t *);
WI_EXPORT wi_boolean_t				wi_file_rename(wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_file_symlink(wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_file_copy(wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_file_stat(wi_string_t *, wi_file_stat_t *);
WI_EXPORT wi_boolean_t				wi_file_lstat(wi_string_t *, wi_file_stat_t *);
WI_EXPORT wi_boolean_t				wi_file_statfs(wi_string_t *, wi_file_statfs_t *);
WI_EXPORT wi_boolean_t				wi_file_exists(wi_string_t *, wi_boolean_t *);
WI_EXPORT wi_boolean_t				wi_file_create_directory(wi_string_t *, uint32_t);
WI_EXPORT wi_boolean_t				wi_file_set_mode(wi_string_t *, uint32_t);
WI_EXPORT wi_boolean_t				wi_file_is_alias(wi_string_t *);
WI_EXPORT wi_boolean_t				wi_file_is_alias_cpath(const char *);
WI_EXPORT wi_boolean_t				wi_file_is_invisible(wi_string_t *);
WI_EXPORT wi_boolean_t				wi_file_is_invisible_cpath(const char *);
WI_EXPORT wi_boolean_t				wi_file_set_finder_comment(wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *				wi_file_finder_comment(wi_string_t *);

WI_EXPORT wi_array_t *				wi_file_directory_contents_at_path(wi_string_t *);
WI_EXPORT wi_string_t *				wi_file_sha1(wi_string_t *, wi_file_offset_t);

WI_EXPORT wi_runtime_id_t			wi_file_runtime_id(void);

WI_EXPORT wi_file_t *				wi_file_for_reading(wi_string_t *);
WI_EXPORT wi_file_t *				wi_file_for_writing(wi_string_t *);
WI_EXPORT wi_file_t *				wi_file_for_updating(wi_string_t *);
WI_EXPORT wi_file_t *				wi_file_temporary_file(void);

WI_EXPORT wi_file_t *				wi_file_alloc(void);
WI_EXPORT wi_file_t *				wi_file_init_with_path(wi_file_t *, wi_string_t *, wi_file_mode_t);
WI_EXPORT wi_file_t *				wi_file_init_with_file_descriptor(wi_file_t *, int);
WI_EXPORT wi_file_t *				wi_file_init_temporary_file(wi_file_t *);

WI_EXPORT int						wi_file_descriptor(wi_file_t *);

WI_EXPORT wi_string_t *				wi_file_read(wi_file_t *, wi_uinteger_t);
WI_EXPORT wi_string_t *				wi_file_read_to_end_of_file(wi_file_t *);
WI_EXPORT wi_string_t *				wi_file_read_line(wi_file_t *);
WI_EXPORT wi_string_t *				wi_file_read_config_line(wi_file_t *);
WI_EXPORT wi_string_t *				wi_file_read_to_string(wi_file_t *, wi_string_t *);
WI_EXPORT wi_integer_t				wi_file_read_buffer(wi_file_t *, void *, wi_uinteger_t);
WI_EXPORT wi_integer_t				wi_file_write_format(wi_file_t *, wi_string_t *, ...);
WI_EXPORT wi_integer_t				wi_file_write_buffer(wi_file_t *, const void *, wi_uinteger_t);

WI_EXPORT void						wi_file_seek(wi_file_t *, wi_file_offset_t);
WI_EXPORT wi_file_offset_t			wi_file_seek_to_end_of_file(wi_file_t *);
WI_EXPORT wi_file_offset_t			wi_file_offset(wi_file_t *);

WI_EXPORT wi_boolean_t				wi_file_truncate(wi_file_t *, wi_file_offset_t);
WI_EXPORT void						wi_file_close(wi_file_t *);

WI_EXPORT wi_boolean_t				wi_file_compress_at_path(wi_file_t *, wi_string_t *, wi_integer_t);
WI_EXPORT wi_boolean_t				wi_file_decompress_at_path(wi_file_t *, wi_string_t *);

#endif /* WI_FILE_H */
