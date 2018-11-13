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

#import <WiredAppKit/NSFileManager-WIAppKit.h>

struct _WIFileManagerFinderInfo {
    UInt32									length;
	UInt32									data[8];
};
typedef struct _WIFileManagerFinderInfo		_WIFileManagerFinderInfo;



@implementation NSFileManager(WIAppKit)

- (BOOL)fileExistsAtPath:(NSString *)path hasResourceFork:(BOOL *)hasResourceFork {
	return [self fileExistsAtPath:path isDirectory:NULL hasResourceFork:hasResourceFork];
}



- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory hasResourceFork:(BOOL *)hasResourceFork {
	if([self fileExistsAtPath:path isDirectory:isDirectory]) {
		if(hasResourceFork)
			*hasResourceFork = ([self resourceForkSizeAtPath:path] > 0);
		
		return YES;
	}
	
	return NO;
}



#pragma mark -

- (WIFileOffset)resourceForkSizeAtPath:(NSString *)path {
	FSRef			fsRef;
	FSCatalogInfo   fsInfo;
	
	if(FSPathMakeRef((unsigned char *) [path fileSystemRepresentation], &fsRef, NULL) == noErr) {
		if(FSGetCatalogInfo(&fsRef, kFSCatInfoRsrcSizes, &fsInfo, NULL, NULL, NULL) == noErr)
			return fsInfo.rsrcLogicalSize;
	}
	
	return 0;
}



#pragma mark -

- (BOOL)setFinderInfo:(NSData *)info atPath:(NSString *)path {
	struct attrlist				attrs;
	_WIFileManagerFinderInfo	finderinfo;
	
	[info getBytes:finderinfo.data length:sizeof(finderinfo.data)];
	
	attrs.bitmapcount		= ATTR_BIT_MAP_COUNT;
	attrs.reserved			= 0;
	attrs.commonattr		= ATTR_CMN_FNDRINFO;
	attrs.volattr			= 0;
	attrs.dirattr			= 0;
	attrs.fileattr			= 0;
	attrs.forkattr			= 0;
	
	if(setattrlist([path fileSystemRepresentation], &attrs, finderinfo.data, sizeof(finderinfo.data), FSOPT_NOFOLLOW) < 0)
		return NO;
	
	return YES;
}



- (NSData *)finderInfoAtPath:(NSString *)path {
	struct attrlist				attrs;
	_WIFileManagerFinderInfo	finderinfo;
	
	attrs.bitmapcount		= ATTR_BIT_MAP_COUNT;
	attrs.reserved			= 0;
	attrs.commonattr		= ATTR_CMN_FNDRINFO;
	attrs.volattr			= 0;
	attrs.dirattr			= 0;
	attrs.fileattr			= 0;
	attrs.forkattr			= 0;
	
	if(getattrlist([path fileSystemRepresentation], &attrs, &finderinfo, sizeof(finderinfo), FSOPT_NOFOLLOW) < 0)
		return NULL;
	
	return [NSData dataWithBytes:finderinfo.data length:sizeof(finderinfo.data)];
}

@end
