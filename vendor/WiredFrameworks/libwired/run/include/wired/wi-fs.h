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

#ifndef WI_FS_H
#define WI_FS_H 1

#include <sys/param.h>
#include <wired/wi-base.h>
#include <wired/wi-file.h>
#include <wired/wi-fsenumerator.h>
#include <wired/wi-runtime.h>

#define WI_PATH_SIZE					MAXPATHLEN


enum _wi_fs_finder_label {
	WI_FS_FINDER_LABEL_NONE				= 0,
	WI_FS_FINDER_LABEL_RED,
	WI_FS_FINDER_LABEL_ORANGE,
	WI_FS_FINDER_LABEL_YELLOW,
	WI_FS_FINDER_LABEL_GREEN,
	WI_FS_FINDER_LABEL_BLUE,
	WI_FS_FINDER_LABEL_PURPLE,
	WI_FS_FINDER_LABEL_GRAY,
};
typedef enum _wi_fs_finder_label		wi_fs_finder_label_t;

struct _wi_fs_stat {
	uint32_t							dev;
	uint64_t							ino;
	uint32_t							mode;
	uint32_t							nlink;
	uint32_t							uid;
	uint32_t							gid;
	uint32_t							rdev;
	uint32_t							atime;
	uint32_t							mtime;
	uint32_t							ctime;
	uint32_t							birthtime;
	uint64_t							size;
	uint64_t							blocks;
	uint32_t							blksize;
};
typedef struct _wi_fs_stat				wi_fs_stat_t;

struct _wi_fs_statfs {
	uint32_t							bsize;
	uint32_t							frsize;
	uint64_t							blocks;
	uint64_t							bfree;
	uint64_t							bavail;
	uint64_t							files;
	uint64_t							ffree;
	uint64_t							favail;
	uint32_t							fsid;
	uint64_t							flag;
	uint64_t							namemax;
};
typedef struct _wi_fs_statfs			wi_fs_statfs_t;

typedef void							wi_fs_delete_path_callback_t(wi_string_t *);
typedef void							wi_fs_copy_path_callback_t(wi_string_t *, wi_string_t *);


WI_EXPORT wi_string_t *					wi_fs_temporary_path_with_template(wi_string_t *);

WI_EXPORT wi_boolean_t					wi_fs_create_directory(wi_string_t *, uint32_t);
WI_EXPORT wi_boolean_t					wi_fs_change_directory(wi_string_t *);

WI_EXPORT wi_boolean_t					wi_fs_delete_path(wi_string_t *);
WI_EXPORT wi_boolean_t					wi_fs_delete_path_with_callback(wi_string_t *, wi_fs_delete_path_callback_t *);
WI_EXPORT wi_boolean_t					wi_fs_clear_path(wi_string_t *);
WI_EXPORT wi_boolean_t					wi_fs_rename_path(wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t					wi_fs_symlink_path(wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t					wi_fs_copy_path(wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t					wi_fs_copy_path_with_callback(wi_string_t *, wi_string_t *, wi_fs_copy_path_callback_t);
WI_EXPORT wi_boolean_t					wi_fs_set_mode_for_path(wi_string_t *, uint32_t);

WI_EXPORT wi_boolean_t					wi_fs_stat_path(wi_string_t *, wi_fs_stat_t *);
WI_EXPORT wi_boolean_t					wi_fs_lstat_path(wi_string_t *, wi_fs_stat_t *);
WI_EXPORT wi_boolean_t					wi_fs_statfs_path(wi_string_t *, wi_fs_statfs_t *);
WI_EXPORT wi_boolean_t					wi_fs_path_exists(wi_string_t *, wi_boolean_t *);
WI_EXPORT wi_string_t *					wi_fs_real_path_for_path(wi_string_t *);

WI_EXPORT wi_array_t *					wi_fs_directory_contents_at_path(wi_string_t *);
WI_EXPORT wi_fsenumerator_t *			wi_fs_enumerator_at_path(wi_string_t *);

WI_EXPORT wi_string_t *					wi_fs_sha1_for_path(wi_string_t *, wi_file_offset_t);

WI_EXPORT wi_string_t *					wi_fs_resource_fork_path_for_path(wi_string_t *);
WI_EXPORT wi_file_offset_t				wi_fs_resource_fork_size_for_path(wi_string_t *);

WI_EXPORT wi_boolean_t					wi_fs_path_is_alias(wi_string_t *);
WI_EXPORT wi_boolean_t					wi_fs_cpath_is_alias(const char *);

WI_EXPORT wi_boolean_t					wi_fs_path_is_invisible(wi_string_t *);
WI_EXPORT wi_boolean_t					wi_fs_cpath_is_invisible(const char *);

WI_EXPORT wi_boolean_t					wi_fs_set_finder_comment_for_path(wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *					wi_fs_finder_comment_for_path(wi_string_t *);

WI_EXPORT wi_boolean_t					wi_fs_set_finder_label_for_path(wi_fs_finder_label_t, wi_string_t *);
WI_EXPORT wi_fs_finder_label_t			wi_fs_finder_label_for_path(wi_string_t *);

WI_EXPORT wi_boolean_t					wi_fs_set_finder_info_for_path(wi_data_t *, wi_string_t *);
WI_EXPORT wi_data_t *					wi_fs_finder_info_for_path(wi_string_t *);

#endif /* WI_FS_H */
