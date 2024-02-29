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

#import "WCServerConnectionObject.h"

enum _WCFileType {
	WCFileFile,
	WCFileDirectory,
	WCFileUploads,
	WCFileDropBox
};
typedef enum _WCFileType			WCFileType;

enum _WCFilePermissions {
	WCFileOwnerWrite				= (2 << 6),
	WCFileOwnerRead					= (4 << 6),
	WCFileGroupWrite				= (2 << 3),
	WCFileGroupRead					= (4 << 3),
	WCFileEveryoneWrite				= (2 << 0),
	WCFileEveryoneRead				= (4 << 0)
};
typedef enum _WCFilePermissions		WCFilePermissions;

enum _WCFileLabel {
	WCFileLabelNone					= 0,
	WCFileLabelRed,
	WCFileLabelOrange,
	WCFileLabelYellow,
	WCFileLabelGreen,
	WCFileLabelBlue,
	WCFileLabelPurple,
	WCFileLabelGray
};
typedef enum _WCFileLabel			WCFileLabel;


@interface WCFile : WCServerConnectionObject <NSCoding, NSCopying> {
	WCFileType						_type;
	WIFileOffset					_dataSize;
	WIFileOffset					_rsrcSize;
	NSUInteger						_directoryCount;
	WIFileOffset					_free;
	NSString						*_path;
	NSDate							*_creationDate;
	NSDate							*_modificationDate;
	NSString						*_comment;
	BOOL							_link;
	BOOL							_executable;
	BOOL							_readable;
	BOOL							_writable;
	NSString						*_owner;
	NSString						*_group;
	NSUInteger						_permissions;
	WCFileLabel						_label;
	NSUInteger						_volume;

	NSString						*_name;
	NSString						*_extension;
	NSString						*_kind;
	NSMutableDictionary				*_icons;

	NSString						*_transferLocalPath;
	
	WIFileOffset					_uploadDataSize;
	WIFileOffset					_uploadRsrcSize;
	
	NSURL							*_previewItemURL;

@public
	WIFileOffset					_dataTransferred;
	WIFileOffset					_rsrcTransferred;
}

+ (NSImage *)iconForFolderType:(WCFileType)type width:(CGFloat)width open:(BOOL)opened;
+ (NSString *)kindForFolderType:(WCFileType)type;
+ (WCFileType)folderTypeForString:(NSString *)string;

+ (id)fileWithRootDirectoryForConnection:(WCServerConnection *)connection;
+ (id)fileWithDirectory:(NSString *)path connection:(WCServerConnection *)connection;
+ (id)fileWithFile:(NSString *)path connection:(WCServerConnection *)connection;
+ (id)fileWithPath:(NSString *)path type:(WCFileType)type connection:(WCServerConnection *)connection;
+ (id)fileWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;

- (WCFileType)type;
- (NSString *)path;
- (NSDate *)creationDate;
- (NSDate *)modificationDate;
- (NSString *)comment;
- (NSString *)name;
- (NSString *)extension;
- (NSString *)kind;
- (BOOL)isFolder;
- (BOOL)isUploadsFolder;
- (BOOL)isLink;
- (BOOL)isExecutable;
- (NSString *)owner;
- (NSString *)group;
- (NSUInteger)permissions;
- (WCFileLabel)label;
- (NSColor *)labelColor;
- (NSUInteger)volume;
- (NSString *)internalURLString;
- (NSString *)externalURLString;
- (NSImage *)iconWithWidth:(CGFloat)width open:(BOOL)open;


- (void)setDataSize:(WIFileOffset)size;
- (WIFileOffset)dataSize;
- (void)setRsrcSize:(WIFileOffset)size;
- (WIFileOffset)rsrcSize;
- (WIFileOffset)totalSize;
- (void)setDirectoryCount:(NSUInteger)directoryCount;
- (NSUInteger)directoryCount;
- (NSString *)humanReadableDirectoryCount;
- (void)setFreeSpace:(WIFileOffset)free;
- (WIFileOffset)freeSpace;
- (void)setReadable:(BOOL)readable;
- (BOOL)isReadable;
- (void)setWritable:(BOOL)writable;
- (BOOL)isWritable;

- (void)setTransferLocalPath:(NSString *)localPath;
- (NSString *)transferLocalPath;
- (void)setUploadDataSize:(WIFileOffset)size;
- (WIFileOffset)uploadDataSize;
- (void)setUploadRsrcSize:(WIFileOffset)size;
- (WIFileOffset)uploadRsrcSize;
- (void)setDataTransferred:(WIFileOffset)transferred;
- (WIFileOffset)dataTransferred;
- (void)setRsrcTransferred:(WIFileOffset)transferred;
- (WIFileOffset)rsrcTransferred;

- (void)setPreviewItemURL:(NSURL *)url;
- (NSURL *)previewItemURL;

- (NSComparisonResult)compareName:(WCFile *)file;
- (NSComparisonResult)compareKind:(WCFile *)file;
- (NSComparisonResult)compareCreationDate:(WCFile *)file;
- (NSComparisonResult)compareModificationDate:(WCFile *)file;
- (NSComparisonResult)compareSize:(WCFile *)file;

@end
