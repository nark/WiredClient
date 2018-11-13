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

#ifdef HAVE_CARBON_CARBON_H
#include <Carbon/Carbon.h>
#endif

#include <sys/param.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <dirent.h>

#include <wired/wi-array.h>
#include <wired/wi-assert.h>
#include <wired/wi-byteorder.h>
#include <wired/wi-compat.h>
#include <wired/wi-digest.h>
#include <wired/wi-file.h>
#include <wired/wi-fts.h>
#include <wired/wi-lock.h>
#include <wired/wi-pool.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

#include <zlib.h>

 #define CHUNK 16384

#define _WI_FILE_ASSERT_OPEN(file) \
	WI_ASSERT((file)->fd >= 0, "%@ is not open", (file))


struct _wi_file {
	wi_runtime_base_t					base;

	int									fd;
	wi_file_offset_t					offset;
};


static void								_wi_file_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_file_description(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_file_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_file_runtime_class = {
	"wi_file_t",
	_wi_file_dealloc,
	NULL,
	NULL,
	_wi_file_description,
	NULL
};



void wi_file_register(void) {
	_wi_file_runtime_id = wi_runtime_register_class(&_wi_file_runtime_class);
}



void wi_file_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_file_runtime_id(void) {
	return _wi_file_runtime_id;
}



#pragma mark -

wi_file_t * wi_file_for_reading(wi_string_t *path) {
	return wi_autorelease(wi_file_init_with_path(wi_file_alloc(), path, WI_FILE_READING));
}



wi_file_t * wi_file_for_writing(wi_string_t *path) {
	return wi_autorelease(wi_file_init_with_path(wi_file_alloc(), path, WI_FILE_WRITING));
}



wi_file_t * wi_file_for_updating(wi_string_t *path) {
	return wi_autorelease(wi_file_init_with_path(wi_file_alloc(), path, WI_FILE_READING | WI_FILE_WRITING | WI_FILE_UPDATING));
}



wi_file_t * wi_file_temporary_file(void) {
	return wi_autorelease(wi_file_init_temporary_file(wi_file_alloc()));
}



#pragma mark -

wi_file_t * wi_file_alloc(void) {
	return wi_runtime_create_instance(_wi_file_runtime_id, sizeof(wi_file_t));
}



wi_file_t * wi_file_init_with_path(wi_file_t *file, wi_string_t *path, wi_file_mode_t mode) {
	int		flags;

	if(mode & WI_FILE_WRITING)	
		flags = O_CREAT;
	else
		flags = 0;
	
	if((mode & WI_FILE_READING) && (mode & WI_FILE_WRITING))
		flags |= O_RDWR;
	else if(mode & WI_FILE_READING)
		flags |= O_RDONLY;
	else if(mode & WI_FILE_WRITING)
		flags |= O_WRONLY;
	
	if(mode & WI_FILE_WRITING) {
		if(mode & WI_FILE_UPDATING)
			flags |= O_APPEND;
		else
			flags |= O_TRUNC;
	}
		
	file->fd = open(wi_string_cstring(path), flags, 0666);
	
	if(file->fd < 0) {
		wi_error_set_errno(errno);

		wi_release(file);
		
		return NULL;
	}
	
	return file;
}



wi_file_t * wi_file_init_with_file_descriptor(wi_file_t *file, int fd) {
	file->fd = fd;
	
	return file;
}



wi_file_t * wi_file_init_temporary_file(wi_file_t *file) {
	FILE		*fp;
	
	fp = wi_tmpfile();
	
	if(!fp) {
		wi_error_set_errno(errno);

		wi_release(file);
		
		return NULL;
	}

	return wi_file_init_with_file_descriptor(file, fileno(fp));
}




static void _wi_file_dealloc(wi_runtime_instance_t *instance) {
	wi_file_t		*file = instance;
	
	wi_file_close(file);
}



static wi_string_t * _wi_file_description(wi_runtime_instance_t *instance) {
	wi_file_t		*file = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{descriptor = %d}"),
	  wi_runtime_class_name(file),
	  file,
	  file->fd);
}



#pragma mark -

int wi_file_descriptor(wi_file_t *file) {
	return file->fd;
}



#pragma mark -

wi_string_t * wi_file_read(wi_file_t *file, wi_uinteger_t length) {
	wi_mutable_string_t		*string;
	char					buffer[WI_FILE_BUFFER_SIZE];
	wi_integer_t			bytes = -1;
	
	_WI_FILE_ASSERT_OPEN(file);
	
	string = wi_string_init_with_capacity(wi_mutable_string_alloc(), length);
	
	while(length > sizeof(buffer)) {
		bytes = wi_file_read_buffer(file, buffer, sizeof(buffer));
		
		if(bytes <= 0)
			goto end;
		
		wi_mutable_string_append_bytes(string, buffer, bytes);
		
		length -= bytes;
	}
	
	if(length > 0) {
		bytes = wi_file_read_buffer(file, buffer, sizeof(buffer));
		
		if(bytes <= 0)
			goto end;
		
		wi_mutable_string_append_bytes(string, buffer, bytes);
	}
	
end:
	if(bytes <= 0) {
		wi_release(string);
		
		string = NULL;
	}
	
	wi_runtime_make_immutable(string);

	return wi_autorelease(string);
}



wi_string_t * wi_file_read_to_end_of_file(wi_file_t *file) {
	wi_mutable_string_t		*string;
	char					buffer[WI_FILE_BUFFER_SIZE];
	wi_integer_t			bytes;
	
	string = wi_string_init(wi_mutable_string_alloc());
	
	while((bytes = wi_file_read_buffer(file, buffer, sizeof(buffer))))
		wi_mutable_string_append_bytes(string, buffer, bytes);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_file_read_line(wi_file_t *file) {
	return wi_file_read_to_string(file, WI_STR("\n"));
}



wi_string_t * wi_file_read_config_line(wi_file_t *file) {
	wi_string_t		*string;
	
	while((string = wi_file_read_line(file))) {
		if(wi_string_length(string) == 0 || wi_string_has_prefix(string, WI_STR("#")))
			continue;

		return string;
	}
	
	return NULL;
}



wi_string_t * wi_file_read_to_string(wi_file_t *file, wi_string_t *separator) {
	wi_mutable_string_t		*totalstring = NULL;
	wi_string_t				*string;
	wi_uinteger_t			index, length;
	
	_WI_FILE_ASSERT_OPEN(file);
	
	while((string = wi_file_read(file, WI_FILE_BUFFER_SIZE))) {
		if(!totalstring)
			totalstring = wi_string_init(wi_mutable_string_alloc());
		
		index = wi_string_index_of_string(string, separator, 0);
		
		if(index == WI_NOT_FOUND) {
			wi_mutable_string_append_string(totalstring, string);
		} else {
			length = wi_string_length(string);
			
			wi_mutable_string_append_string(totalstring, wi_string_substring_to_index(string, index));

			wi_file_seek(file, wi_file_offset(file) - length + index + 1);
			
			break;
		}
	}
	
	wi_runtime_make_immutable(string);

	return wi_autorelease(totalstring);
}



wi_integer_t wi_file_read_buffer(wi_file_t *file, void *buffer, wi_uinteger_t length) {
	wi_integer_t	bytes;
	
	bytes = read(file->fd, buffer, length);
	
	if(bytes >= 0)
		file->offset += bytes;
	else
		wi_error_set_errno(errno);
	
	return bytes;
}



wi_integer_t wi_file_write_format(wi_file_t *file, wi_string_t *fmt, ...) {
	wi_string_t		*string;
	wi_integer_t	bytes;
	va_list			ap;
	
	_WI_FILE_ASSERT_OPEN(file);
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap);
	va_end(ap);
	
	bytes = wi_file_write_buffer(file, wi_string_cstring(string), wi_string_length(string));
	
	wi_release(string);
	
	return bytes;
}



wi_integer_t wi_file_write_buffer(wi_file_t *file, const void *buffer, wi_uinteger_t length) {
	wi_integer_t	bytes;
	
	bytes = write(file->fd, buffer, length);
	
	if(bytes >= 0)
		file->offset += bytes;
	else
		wi_error_set_errno(errno);
	
	return bytes;
}



#pragma mark -

void wi_file_seek(wi_file_t *file, wi_file_offset_t offset) {
	off_t		r;
	
	_WI_FILE_ASSERT_OPEN(file);
	
	r = lseek(file->fd, (off_t) offset, SEEK_SET);
	
	if(r >= 0)
		file->offset = r;
}



wi_file_offset_t wi_file_seek_to_end_of_file(wi_file_t *file) {
	off_t		r;
	
	_WI_FILE_ASSERT_OPEN(file);
	
	r = lseek(file->fd, 0, SEEK_END);
	
	if(r >= 0)
		file->offset = r;

	return file->offset;
}



wi_file_offset_t wi_file_offset(wi_file_t *file) {
	return file->offset;
}



#pragma mark -

wi_boolean_t wi_file_truncate(wi_file_t *file, wi_file_offset_t offset) {
	_WI_FILE_ASSERT_OPEN(file);
	
	if(ftruncate(file->fd, offset) < 0) {
		wi_error_set_errno(errno);
		
		return false;
	}
	
	return true;
}



void wi_file_close(wi_file_t *file) {
	if(file->fd >= 0) {
		(void) close(file->fd);
		
		file->fd = -1;
	}
}




#pragma mark -

wi_boolean_t wi_file_compress_at_path(wi_file_t *file, wi_string_t *path, wi_integer_t level) {
	FILE 	*source;
	FILE 	*dest;

	int ret, flush;
    unsigned have;
    z_stream strm;
    unsigned char in[CHUNK];
    unsigned char out[CHUNK];

    /* Check input and output files */
    if (NULL == (source = fdopen(file->fd, "r")))
    	return false;

    if (NULL == (dest = fopen(wi_string_cstring(path), "rw")))
    	return false;

    /* allocate deflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    ret = deflateInit(&strm, level);
    if (ret != Z_OK)
        return false;

    /* compress until end of file */
    do {
        strm.avail_in = fread(in, 1, CHUNK, source);
        if (ferror(source)) {
            (void)deflateEnd(&strm);
            return false;
        }
        flush = feof(source) ? Z_FINISH : Z_NO_FLUSH;
        strm.next_in = in;

        /* run deflate() on input until output buffer not full, finish
           compression if all of source has been read in */
        do {
            strm.avail_out = CHUNK;
            strm.next_out = out;
            ret = deflate(&strm, flush);    /* no bad return value */
            //assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            have = CHUNK - strm.avail_out;
            if (fwrite(out, 1, have, dest) != have || ferror(dest)) {
                (void)deflateEnd(&strm);
                return false;
            }
        } while (strm.avail_out == 0);
        //assert(strm.avail_in == 0);     /* all input will be used */

        /* done when last data in file processed */
    } while (flush != Z_FINISH);
    //assert(ret == Z_STREAM_END);        /* stream will be complete */

    /* clean up and return */
    (void)deflateEnd(&strm);

    /* Close file pointers */
	fclose(source);
	fclose(dest);

    return true;
}



wi_boolean_t wi_file_decompress_at_path(wi_file_t *file, wi_string_t *path) {
	FILE 	*source;
	FILE 	*dest;

	int ret;
    unsigned have;
    z_stream strm;
    unsigned char in[CHUNK];
    unsigned char out[CHUNK];

    /* Check input and output files */
    if (NULL == (source = fdopen(file->fd, "r")))
    	return false;

    if (NULL == (dest = fopen(wi_string_cstring(path), "rw")))
    	return false;

    /* allocate inflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    ret = inflateInit(&strm);
    if (ret != Z_OK)
        return ret;

    /* decompress until deflate stream ends or end of file */
    do {
        strm.avail_in = fread(in, 1, CHUNK, source);
        if (ferror(source)) {
            (void)inflateEnd(&strm);
            return Z_ERRNO;
        }
        if (strm.avail_in == 0)
            break;
        strm.next_in = in;

        /* run inflate() on input until output buffer not full */
        do {
            strm.avail_out = CHUNK;
            strm.next_out = out;
            ret = inflate(&strm, Z_NO_FLUSH);
            
            if(ret == Z_STREAM_ERROR)  /* state not clobbered */
            	continue;

            switch (ret) {
            case Z_NEED_DICT:
                ret = Z_DATA_ERROR;     /* and fall through */
            case Z_DATA_ERROR:
            case Z_MEM_ERROR:
                (void)inflateEnd(&strm);
                return ret;
            }
            have = CHUNK - strm.avail_out;
            if (fwrite(out, 1, have, dest) != have || ferror(dest)) {
                (void)inflateEnd(&strm);
                return Z_ERRNO;
            }
        } while (strm.avail_out == 0);

        /* done when inflate() says it's done */
    } while (ret != Z_STREAM_END);

    /* clean up and return */
    (void)inflateEnd(&strm);

    /* Close file pointers */
	fclose(source);
	fclose(dest);

    return (ret == Z_STREAM_END) ? true : false;
}


