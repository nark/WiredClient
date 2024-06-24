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

#import "WCCache.h"
#import "WCFile.h"

@interface WCFile(Private)

- (id)_initWithPath:(NSString *)path type:(WCFileType)type connection:(WCServerConnection *)connection;
- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;

@end


@implementation WCFile(Private)

- (id)_initWithPath:(NSString *)path type:(WCFileType)type connection:(WCServerConnection *)connection {
	self = [super initWithConnection:connection];
	
	_path = [path retain];
	_type = type;
	
	return self;
}



- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	WIP7UInt32		volume, directoryCount;
	WIP7UInt64		dataSize, rsrcSize;
	WIP7Enum		type, label;
	WIP7Bool		link, executable, value;
	
	self = [super initWithConnection:connection];
	
	[message getEnum:&type forName:@"wired.file.type"];
	[message getBool:&link forName:@"wired.file.link"];
	[message getBool:&executable forName:@"wired.file.executable"];
	[message getEnum:&label forName:@"wired.file.label"];
	[message getUInt32:&volume forName:@"wired.file.volume"];

	if(![message getUInt64:&dataSize forName:@"wired.file.data_size"])
		dataSize = 0;
	
	if(![message getUInt64:&rsrcSize forName:@"wired.file.rsrc_size"])
		rsrcSize = 0;
	
	if(![message getUInt32:&directoryCount forName:@"wired.file.directory_count"])
		directoryCount = 0;
	
	_type				= type;
	_rsrcSize			= rsrcSize;
	_dataSize			= dataSize;
	_directoryCount		= directoryCount;
	_creationDate		= [[message dateForName:@"wired.file.creation_time"] retain];
	_modificationDate	= [[message dateForName:@"wired.file.modification_time"] retain];
	_comment			= [[message stringForName:@"wired.file.comment"] retain];
	_path				= [[message stringForName:@"wired.file.path"] retain];
	_link				= link;
	_executable			= executable;
	_label				= label;
	_volume				= volume;
	
	_owner = [[message stringForName:@"wired.file.owner"] retain];
	
	if(!_owner)
		_owner = @"";
	
	_group = [[message stringForName:@"wired.file.group"] retain];
	
	if(!_group)
		_group = @"";
	
	if([message getBool:&value forName:@"wired.file.owner.read"] && value)
		_permissions |= WCFileOwnerRead;
	
	if([message getBool:&value forName:@"wired.file.owner.write"] && value)
		_permissions |= WCFileOwnerWrite;
	
	if([message getBool:&value forName:@"wired.file.group.read"] && value)
		_permissions |= WCFileGroupRead;
	
	if([message getBool:&value forName:@"wired.file.group.write"] && value)
		_permissions |= WCFileGroupWrite;
	
	if([message getBool:&value forName:@"wired.file.everyone.read"] && value)
		_permissions |= WCFileEveryoneRead;
	
	if([message getBool:&value forName:@"wired.file.everyone.write"] && value)
		_permissions |= WCFileEveryoneWrite;
	
	if([message getBool:&value forName:@"wired.file.readable"])
		_readable = value;
	
	if([message getBool:&value forName:@"wired.file.writable"])
		_writable = value;

	return self;
}

@end


@implementation WCFile

+ (NSInteger)version {
	return 1;
}



#pragma mark -

+ (NSImage *)iconForFolderType:(WCFileType)type width:(CGFloat)width open:(BOOL)open {
	static NSImage		*folderImage, *openFolderImage;
	static NSImage		*folderImage32[2], *folderImage16[2], *folderImage12[2];
	static NSImage		*uploadsImage32[2], *uploadsImage16[2], *uploadsImage12[2];
	static NSImage		*dropBoxImage32[2], *dropBoxImage16[2], *dropBoxImage12[2];
	NSImage				*image = NULL, *badgeImage, *selectedFolderImage;
	NSUInteger			index;
	
	if(!folderImage)
		folderImage = [[NSImage imageNamed:@"Folder"] retain];

	if(!openFolderImage)
		openFolderImage = [[NSImage imageNamed:@"OpenFolder"] retain];
	
	index				= open ? 1 : 0;
	selectedFolderImage	= open ? openFolderImage : folderImage;
	
	switch(type) {
		case WCFileDirectory:
			if(width == 32.0)
				image = folderImage32[index];
			else if(width == 16.0)
				image = folderImage16[index];
			else if(width == 12.0)
				image = folderImage12[index];
			
			if(!image) {
				[selectedFolderImage setSize:NSMakeSize(width, width)];

				image = [[selectedFolderImage imageBySuperimposingImage:NULL] retain];
				
				if(width == 32.0)
					folderImage32[index] = image;
				else if(width == 16.0)
					folderImage16[index] = image;
				else if(width == 12.0)
					folderImage12[index] = image;
				else
					[image autorelease];
			}
			break;
		
		case WCFileUploads:
			if(width == 32.0)
				image = uploadsImage32[index];
			else if(width == 16.0)
				image = uploadsImage16[index];
			else if(width == 12.0)
				image = uploadsImage12[index];
			
			if(!image) {
				[selectedFolderImage setSize:NSMakeSize(width, width)];
				
				badgeImage = [[[NSImage imageNamed:@"UploadsBadge"] copy] autorelease];
				[badgeImage setSize:[selectedFolderImage size]];
				
				image = [[selectedFolderImage imageBySuperimposingImage:badgeImage] retain];
				
				if(width == 32.0)
					uploadsImage32[index] = image;
				else if(width == 16.0)
					uploadsImage16[index] = image;
				else if(width == 12.0)
					uploadsImage12[index] = image;
				else
					[image autorelease];
			}
			break;

		case WCFileDropBox:
			if(width == 32.0)
				image = dropBoxImage32[index];
			else if(width == 16.0)
				image = dropBoxImage16[index];
			else if(width == 12.0)
				image = dropBoxImage12[index];
			
			if(!image) {
				[selectedFolderImage setSize:NSMakeSize(width, width)];
				
				badgeImage = [[[NSImage imageNamed:@"DropBoxBadge"] copy] autorelease];
				[badgeImage setSize:[selectedFolderImage size]];
				
				image = [[selectedFolderImage imageBySuperimposingImage:badgeImage] retain];
				
				if(width == 32.0)
					dropBoxImage32[index] = image;
				else if(width == 16.0)
					dropBoxImage16[index] = image;
				else if(width == 12.0)
					dropBoxImage12[index] = image;
				else
					[image autorelease];
			}
			break;

		case WCFileFile:
			break;
	}
	
	return image;
}



+ (NSString *)kindForFolderType:(WCFileType)type {
    static NSString *folder = nil;
    static NSString *uploads = nil;
    static NSString *dropbox = nil;

    switch(type) {
        case WCFileDirectory:
            if (!folder)
                folder = (NSString *)UTTypeCopyDescription(CFSTR("public.folder"));
            return folder;
            break;
        
        case WCFileUploads:
            if (!uploads)
                uploads = NSLocalizedString(@"Uploads Folder", @"Uploads folder kind");
            return uploads;
            break;
        
        case WCFileDropBox:
            if (!dropbox)
                dropbox = NSLocalizedString(@"Drop Box Folder", @"Drop box folder kind");
            return dropbox;
            break;
        
        case WCFileFile:
        default:
            return nil;
            break;
    }
    return nil;
}




+ (WCFileType)folderTypeForString:(NSString *)string {
	static NSString		*uploads, *dropbox;
	NSRange				range;
	
	if(!uploads) {
		uploads = [NSLS(@"upload", @"Short uploads folder kind") retain];
		dropbox = [NSLS(@"drop box", @"Short drop box folder kind") retain];
	}
	
	range = [string rangeOfString:uploads options:NSCaseInsensitiveSearch];

	if(range.location != NSNotFound)
		return WCFileUploads;

	range = [string rangeOfString:dropbox options:NSCaseInsensitiveSearch];

	if(range.location != NSNotFound)
		return WCFileDropBox;
		
	return WCFileDirectory;
}



#pragma mark -

+ (id)fileWithRootDirectoryForConnection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithPath:@"/" type:WCFileDirectory connection:connection] autorelease];
}



+ (id)fileWithDirectory:(NSString *)path connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithPath:path type:WCFileDirectory connection:connection] autorelease];
}



+ (id)fileWithFile:(NSString *)path connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithPath:path type:WCFileFile connection:connection] autorelease];
}



+ (id)fileWithPath:(NSString *)path type:(WCFileType)type connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithPath:path type:type connection:connection] autorelease];
}



+ (id)fileWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithMessage:message connection:connection] autorelease];
}



#pragma mark -

- (id)init {
	self = [super init];
	
	_icons = [[NSMutableDictionary alloc] init];
	
	return self;
}



- (void)dealloc {
	[_path release];
	[_modificationDate release];
    [_creationDate release];
	[_comment release];

	[_name release];
	[_extension release];
	[_kind release];
	[_icons release];
	
	[_previewItemURL release];
	
	[super dealloc];
}



#pragma mark -

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	
	if(!self)
		return NULL;
	
    if([coder decodeIntForKey:@"WCFileVersion"] != [[self class] version]) {
        [self release];
		
        return NULL;
    }
	
	_type					= [coder decodeIntForKey:@"WCFileType"];
	_dataSize				= [coder decodeInt64ForKey:@"WCFileDataSize"];
	_rsrcSize				= [coder decodeInt64ForKey:@"WCFileRsrcSize"];
	_directoryCount			= [coder decodeInt32ForKey:@"WCFileDirectoryCount"];
	_free					= [coder decodeInt64ForKey:@"WCFileFree"];
	_path					= [[coder decodeObjectForKey:@"WCFilePath"] retain];
	_creationDate			= [[coder decodeObjectForKey:@"WCFileCreationDate"] retain];
	_modificationDate		= [[coder decodeObjectForKey:@"WCFileModificationDate"] retain];
	_comment				= [[coder decodeObjectForKey:@"WCFileComment"] retain];
	_link					= [coder decodeBoolForKey:@"WCFileLink"];
	_executable				= [coder decodeBoolForKey:@"WCFileExecutable"];
	_readable				= [coder decodeBoolForKey:@"WCFileReadable"];
	_writable				= [coder decodeBoolForKey:@"WCFileWritable"];
	_owner					= [[coder decodeObjectForKey:@"WCFileOwner"] retain];
	_group					= [[coder decodeObjectForKey:@"WCFileGroup"] retain];
	_permissions			= [coder decodeIntForKey:@"WCFilePermissions"];
	_label					= [coder decodeIntForKey:@"WCFileLabel"];
	_volume					= [coder decodeIntForKey:@"WCFileVolume"];
	
	_transferLocalPath		= [[coder decodeObjectForKey:@"WCFileLocalPath"] retain];
	_uploadDataSize			= [coder decodeInt64ForKey:@"WCFileUploadDataSize"];
	_uploadRsrcSize			= [coder decodeInt64ForKey:@"WCFileUploadRsrcSize"];
	_dataTransferred		= [coder decodeInt64ForKey:@"WCFileDataTransferred"];
	_rsrcTransferred		= [coder decodeInt64ForKey:@"WCFileRsrcTransferred"];

	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:[[self class] version] forKey:@"WCFileVersion"];
	
	[coder encodeInt:_type forKey:@"WCFileType"];
	[coder encodeInt64:_dataSize forKey:@"WCFileDataSize"];
	[coder encodeInt64:_rsrcSize forKey:@"WCFileRsrcSize"];
	[coder encodeInt32:_directoryCount forKey:@"WCFileDirectoryCount"];
	[coder encodeInt64:_free forKey:@"WCFileFree"];
	[coder encodeObject:_path forKey:@"WCFilePath"];
	[coder encodeObject:_creationDate forKey:@"WCFileCreationDate"];
	[coder encodeObject:_modificationDate forKey:@"WCFileModificationDate"];
	[coder encodeObject:_comment forKey:@"WCFileComment"];
	[coder encodeBool:_link forKey:@"WCFileLink"];
	[coder encodeBool:_executable forKey:@"WCFileExecutable"];
	[coder encodeBool:_readable forKey:@"WCFileReadable"];
	[coder encodeBool:_writable forKey:@"WCFileWritable"];
	[coder encodeObject:_owner forKey:@"WCFileOwner"];
	[coder encodeObject:_group forKey:@"WCFileGroup"];
	[coder encodeInt:_permissions forKey:@"WCFilePermissions"];
	[coder encodeInt:_label forKey:@"WCFileLabel"];
	[coder encodeInt:_volume forKey:@"WCFileVolume"];

	[coder encodeObject:_transferLocalPath forKey:@"WCFileLocalPath"];
	[coder encodeInt64:_uploadDataSize forKey:@"WCFileUploadDataSize"];
	[coder encodeInt64:_uploadRsrcSize forKey:@"WCFileUploadRsrcSize"];
	[coder encodeInt64:_dataTransferred forKey:@"WCFileDataTransferred"];
	[coder encodeInt64:_rsrcTransferred forKey:@"WCFileRsrcTransferred"];

	[super encodeWithCoder:coder];
}



#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
	WCFile		*file;
	
	file = [[[self class] allocWithZone:zone] init];

	return file;
}



- (BOOL)isEqual:(id)object {
	if(![object isKindOfClass:[self class]])
		return NO;
	
	if(_connection == [(WCFile *) object connection])
		return [_path isEqualToString:[object path]];
	
	return NO;
}



- (NSUInteger)hash {
	return [_path hash] + [_connection hash];
}



- (NSString *)description {
	return [NSSWF:@"<%@ %p>{path = %@, type = %d}",
		[self className],
		self,
		[self path],
		[self type]];
}



#pragma mark -

- (WCFileType)type {
	return _type;
}



- (NSString *)path {
	return _path;
}


- (NSDate *)creationDate {
	return _creationDate;
}



- (NSDate *)modificationDate {
	return _modificationDate;
}



- (NSString *)comment {
	return _comment;
}



- (NSString *)name {
	if(!_name)
		_name = [[[self path] lastPathComponent] retain];
	
	return _name;
}



- (NSString *)extension {
	if(!_extension)
		_extension = [[[self path] pathExtension] retain];
	
	return _extension;
}



- (NSString *)kind {
    if (!_kind) {
        if ([self isLink]) {
            _kind = [NSLocalizedString(@"Alias", @"Alias kind") retain];
        } else if ([self isExecutable]) {
            _kind = [NSLocalizedString(@"Executable File", @"Executable kind") retain];
        } else if ([self isFolder]) {
            _kind = [[[self class] kindForFolderType:[self type]] retain];
        } else {
            CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[self extension], NULL);
            if (uti) {
                _kind = ( NSString *)UTTypeCopyDescription(uti);
                CFRelease(uti);
            }
        }
    }
    return _kind;
}




- (BOOL)isFolder {
	return ([self type] != WCFileFile);
}



- (BOOL)isUploadsFolder {
	return ([self type] == WCFileUploads || [self type] == WCFileDropBox);
}



- (BOOL)isLink {
	return _link;
}



- (BOOL)isExecutable {
	return (_executable && [[self extension] length] == 0);
}



- (NSString *)owner {
	return _owner;
}



- (NSString *)group {
	return _group;
}



- (WCFileLabel)label {
	return _label;
}



- (NSColor *)labelColor {	
	switch(_label) {
		case WCFileLabelRed:
			return [NSColor colorWithCalibratedRed:249.0 / 255.0 green:92.0 / 255.0 blue:91.0 / 255.0 alpha:1.0];
			break;
		
		case WCFileLabelOrange:
			return [NSColor colorWithCalibratedRed:245.0 / 255.0 green:168.0 / 255.0 blue:69.0 / 255.0 alpha:1.0];
			break;
		
		case WCFileLabelYellow:
			return [NSColor colorWithCalibratedRed:237.0 / 255.0 green:219.0 / 255.0 blue:73.0 / 255.0 alpha:1.0];
			break;
		
		case WCFileLabelGreen:
			return [NSColor colorWithCalibratedRed:178.0 / 255.0 green:217.0 / 255.0 blue:72.0 / 255.0 alpha:1.0];
			break;
		
		case WCFileLabelBlue:
			return [NSColor colorWithCalibratedRed:90.0 / 255.0 green:161.0 / 255.0 blue:254.0 / 255.0 alpha:1.0];
			break;
		
		case WCFileLabelPurple:
			return [NSColor colorWithCalibratedRed:191.0 / 255.0 green:137.0 / 255.0 blue:215.0 / 255.0 alpha:1.0];
			break;
		
		case WCFileLabelGray:
			return [NSColor colorWithCalibratedRed:168.0 / 255.0 green:92.0 / 168.0 blue:91.0 / 168.0 alpha:1.0];
			break;
		
		default:
			return NULL;
			break;
	}
	
	return NULL;
}



- (NSUInteger)volume {
	return _volume;
}



- (NSUInteger)permissions {
	return _permissions;
}



- (NSImage *)iconWithWidth:(CGFloat)width open:(BOOL)open {
	NSImage		*icon, *badgeImage;
	NSString	*key, *extension;
	
	key		= [NSSWF:@"%.0f %u", width, open ? 1 : 0];
	icon	= [_icons objectForKey:key];
	
	if(!icon) {
		if([self isFolder]) {
			icon = [[self class] iconForFolderType:[self type] width:width open:open];
		}
		else if([self isExecutable]) {
			icon = [[[NSImage imageNamed:@"Executable"] copy] autorelease];
			[icon setSize:NSMakeSize(width, width)];
		}
		else {
			extension = [self extension];
			icon = [[WCCache cache] fileIconForExtension:extension];
			
			if(!icon) {
				icon = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
				[[WCCache cache] setFileIcon:icon forExtension:extension];
			}
			
			icon = [[icon copy] autorelease];
			[icon setSize:NSMakeSize(width, width)];
		}

		if([self isLink]) {
			badgeImage = [[[NSImage imageNamed:@"AliasBadge"] copy] autorelease];
			icon = [icon imageBySuperimposingImage:badgeImage];
		}
		
		[_icons setObject:icon forKey:key];
	}
	
	return icon;
}


- (NSString *)internalURLString {
    NSString *urlString = nil;
    
    NSString *encodedPath = [self path];
    NSString *encodedURLString = [NSString stringWithFormat:@"wiredp7://%@", encodedPath];
    NSCharacterSet *allowedCharacterSet = [NSCharacterSet URLPathAllowedCharacterSet];
    urlString = [encodedURLString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    if ([self isFolder] && ![encodedPath hasSuffix:@"/"]) {
        urlString = [urlString stringByAppendingString:@"/"];
    }
    
    return urlString;
}



- (NSString *)externalURLString {
    NSString    *urlString, *address;
    
    address     = ([[[self connection] URL] port] != 4871) ?
                    [[[self connection] URL] hostpair] :
                    [[[self connection] URL] host];
    
    urlString   = [NSSWF:@"wiredp7://%@@%@%@",
                   [[[self connection] URL] user],
                   address,
                   [self path]];
    
    return [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}





#pragma mark -

- (void)setDataSize:(WIFileOffset)size {
	_dataSize = size;
}



- (WIFileOffset)dataSize {
	return _dataSize;
}



- (void)setRsrcSize:(WIFileOffset)size {
	_rsrcSize = size;
}



- (WIFileOffset)rsrcSize {
	return _rsrcSize;
}



- (WIFileOffset)totalSize {
	return _dataSize + _rsrcSize;
}



- (void)setDirectoryCount:(NSUInteger)directoryCount {
	_directoryCount = directoryCount;
}



- (NSUInteger)directoryCount {
	return _directoryCount;
}



- (NSString *)humanReadableDirectoryCount {
	return [NSSWF:NSLS(@"%u %@", @"Files folder size (count, 'item(s)'"),
		[self directoryCount],
		[self directoryCount] == 1
			? NSLS(@"item", @"Item singular")
			: NSLS(@"items", @"Item plural")];
}



- (void)setFreeSpace:(WIFileOffset)free {
	_free = free;
}



- (WIFileOffset)freeSpace {
	return _free;
}



- (void)setReadable:(BOOL)readable {
	_readable = readable;
}



- (BOOL)isReadable {
	return _readable;
}



- (void)setWritable:(BOOL)writable {
	_writable = writable;
}



- (BOOL)isWritable {
	return _writable;
}



#pragma mark -

- (void)setTransferLocalPath:(NSString *)path {
	[path retain];
	[_transferLocalPath release];

	_transferLocalPath = path;
}



- (NSString *)transferLocalPath {
	return _transferLocalPath;
}



- (void)setUploadDataSize:(WIFileOffset)size {
	_uploadDataSize = size;
}



- (WIFileOffset)uploadDataSize {
	return _uploadDataSize;
}



- (void)setUploadRsrcSize:(WIFileOffset)size {
	_uploadRsrcSize = size;
}



- (WIFileOffset)uploadRsrcSize {
	return _uploadRsrcSize;
}



- (void)setDataTransferred:(WIFileOffset)transferred {
	_dataTransferred = transferred;
}



- (WIFileOffset)dataTransferred {
	return _dataTransferred;
}



- (void)setRsrcTransferred:(WIFileOffset)transferred {
	_rsrcTransferred = transferred;
}



- (WIFileOffset)rsrcTransferred {
	return _rsrcTransferred;
}



#pragma mark -

- (void)setPreviewItemURL:(NSURL *)previewItemURL {
	[previewItemURL retain];
	[_previewItemURL release];
	
	_previewItemURL = previewItemURL;
}



- (NSURL *)previewItemURL {
	return _previewItemURL;
}



#pragma mark -

- (NSComparisonResult)compareName:(WCFile *)file {
	return [[self name] finderCompare:[file name]];
}



- (NSComparisonResult)compareKind:(WCFile *)file {
	NSComparisonResult		result;

	result = [[self kind] compare:[file kind] options:NSCaseInsensitiveSearch];

	if(result == NSOrderedSame)
		result = [self compareName:file];

	return result;
}



- (NSComparisonResult)compareCreationDate:(WCFile *)file {
	NSComparisonResult		result;

	result = [[self creationDate] compare:[file creationDate]];

	if(result == NSOrderedSame)
		result = [self compareName:file];

	return result;
}



- (NSComparisonResult)compareModificationDate:(WCFile *)file {
	NSComparisonResult		result;

	result = [[self modificationDate] compare:[file modificationDate]];

	if(result == NSOrderedSame)
		result = [self compareName:file];

	return result;
}



- (NSComparisonResult)compareSize:(WCFile *)file {
	if([self type] == WCFileFile && [file type] != WCFileFile)
		return NSOrderedAscending;
	else if([self type] != WCFileFile && [file type] == WCFileFile)
		return NSOrderedDescending;

	if([self totalSize] > [file totalSize])
		return NSOrderedAscending;
	else if([self totalSize] < [file totalSize])
		return NSOrderedDescending;

	return [self compareName:file];
}

@end
