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

#import <WiredFoundation/NSError-WIFoundation.h>
#import <WiredFoundation/NSFileManager-WIFoundation.h>

@implementation NSFileManager(WIFoundation)

+ (NSString *)temporaryPathWithPrefix:(NSString *)prefix {
	return [self temporaryPathWithPrefix:prefix suffix:NULL];
}



+ (NSString *)temporaryPathWithPrefix:(NSString *)prefix suffix:(NSString *)suffix {
	NSString	*string;
	char		*path;
	
	path = tempnam([NSTemporaryDirectory() UTF8String], [[NSSWF:@"%@_", prefix] UTF8String]);
    
    //path = mkstemp([NSTemporaryDirectory() UTF8String], [[NSSWF:@"%@_", prefix] UTF8String]);
    
	string = [NSString stringWithUTF8String:path];
	free(path);
	
	return suffix ? [NSSWF:@"%@.%@", string, suffix] : string;
}



+ (NSString *)temporaryPathWithFilename:(NSString *)filename {
	return [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
}



#pragma mark -

+ (NSString *)resourceForkPathForPath:(NSString *)path {
	return [[path stringByAppendingPathComponent:@"..namedfork"] stringByAppendingPathComponent:@"rsrc"];
}



#pragma mark -

- (BOOL)createDirectoryAtPath:(NSString *)path {
    NSError *error = nil;
    return [self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
}



- (BOOL)createFileAtPath:(NSString *)path {
	return [self createFileAtPath:path contents:NULL attributes:NULL];
}



- (BOOL)directoryExistsAtPath:(NSString *)path {
	BOOL	isDirectory;

	return ([self fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory);
}



- (WIFileOffset)fileSizeAtPath:(NSString *)path {
	NSDictionary	*attributes;
    NSError *error = nil;
    
    attributes = [self attributesOfItemAtPath:path error:&error];
    if(error)
        return 0;
	
	return [attributes fileSize];
}



- (NSString *)ownerAtPath:(NSString *)path {
    NSError *error = nil;
    NSString *ret = nil;
    
    ret = [[self attributesOfItemAtPath:path error:&error] fileOwnerAccountName];
    if(error)
        return nil;
    
	return ret;
}



- (NSArray *)directoryContentsWithFileAtPath:(NSString *)path {
	if(![self directoryExistsAtPath:path])
		return [NSArray arrayWithObject:[path lastPathComponent]];
	
	return [self directoryContentsWithFileAtPath:path];
}



- (id)enumeratorWithFileAtPath:(NSString *)path {
	if(![self directoryExistsAtPath:path])
		return [[NSArray arrayWithObject:[path lastPathComponent]] objectEnumerator];

	return [self enumeratorAtPath:path];
}



- (NSArray *)libraryResourcesForTypes:(NSArray *)types inDirectory:(NSString *)directory {
	NSDirectoryEnumerator	*directoryEnumerator;
	NSEnumerator			*enumerator;
	NSMutableArray			*resources;
	NSArray					*paths;
	NSString				*path;
	
	resources = [NSMutableArray array];
	paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
	enumerator = [paths objectEnumerator];
	
	while((path = [enumerator nextObject])) {
		path = [path stringByAppendingPathComponent:directory];
		directoryEnumerator = [self enumeratorAtPath:path];
		
		while((path = [directoryEnumerator nextObject])) {
			if([types containsObject:[path pathExtension]])
				[resources addObject:path];
		}
	}

	return resources;
}



#pragma mark -

- (BOOL)setExtendedAttribute:(NSData *)data forName:(NSString *)name atPath:(NSString *)path error:(NSError **)error {
	if(setxattr([path fileSystemRepresentation], [name UTF8String], [data bytes], [data length], 0, 0) < 0) {
		if(error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno];
		
		return NO;
	}
	
	return YES;
}



- (NSData *)extendedAttributeForName:(NSString *)name atPath:(NSString *)path error:(NSError **)error {
	void		*value;
	ssize_t		size;
	
	if((size = getxattr([path fileSystemRepresentation], [name UTF8String], NULL, 0, 0, 0)) < 0) {
		if(error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno];
		
		return NULL;
	}
	
	value = malloc(size);
	
	if(getxattr([path fileSystemRepresentation], [name UTF8String], value, size, 0, 0) < 0) {
		if(error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno];
		
		free(value);
		
		return NULL;
	}
	
	return [NSData dataWithBytesNoCopy:value length:size freeWhenDone:YES];
}



- (BOOL)removeExtendedAttributeForName:(NSString *)name atPath:(NSString *)path error:(NSError **)error {
	if(removexattr([path fileSystemRepresentation], [name UTF8String], 0) < 0) {
		if(error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno];
		
		return NO;
	}
	
	return YES;
}

@end
