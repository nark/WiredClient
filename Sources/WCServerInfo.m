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

#import "WCServer.h"
#import "WCServerConnection.h"
#import "WCServerInfo.h"

@interface WCServerInfo(Private)

- (id)_initServerInfoWithConnection:(WCServerConnection *)connection;

- (void)_reloadServerInfo;
- (void)_updateServerInfo;

@end


@implementation WCServerInfo(Private)

- (id)_initServerInfoWithConnection:(WCServerConnection *)connection {
	return [super initWithWindowNibName:@"ServerInfo" connection:connection singleton:YES];
}



#pragma mark -

- (void)_reloadServerInfo {
	if([[self window] isVisible])
		[self _updateServerInfo];
}



- (void)_updateServerInfo {
	WIP7Socket		*socket;
	WIURL			*url;
	WCServer		*server;
	NSRect			rect;
	CGFloat			offset;
	
	socket		= [[self connection] socket];
	server		= [[self connection] server];
	url			= [[[[self connection] URL] copy] autorelease];
	
	if(![socket remoteProtocolName])
		return;
	
	[url setUser:NULL];
	[url setPassword:NULL];

	[_bannerImageView setImage:[server banner]];
	[_nameTextField setStringValue:[server name]];
	[_descriptionTextField setStringValue:[server serverDescription]];
	[_uptimeTextField setStringValue:[NSSWF:
		NSLS(@"%@,\nsince %@", @"Time stamp (time counter, time string)"),
		[_timeIntervalFormatter stringFromTimeIntervalSinceDate:[server startupDate]],
		[_dateFormatter stringFromDate:[server startupDate]]]];
	[_urlTextField setStringValue:[url humanReadableString]];
	[_filesTextField setIntValue:[server files]];
	[_sizeTextField setStringValue:[_sizeFormatter stringFromSize:[server size]]];
	[_versionTextField setStringValue:[server serverVersion]];
	[_protocolTextField setStringValue:[NSSWF:@"%@ %@",
		[socket remoteProtocolName],
		[socket remoteProtocolVersion]]];
	
	if([socket usesEncryption]) {
		[_cipherTextField setStringValue:[NSSWF:NSLS(@"%@/%lu bits", @"Cipher description (name, bits)"),
			[socket cipherName],
			[socket cipherBits]]];
	} else {
		[_cipherTextField setStringValue:NSLS(@"None", @"Encryption disabled")];
	}
	
	if([socket usesCompression]) {
		[_compressionTextField setStringValue:[NSSWF:NSLS(@"Yes, compression ratio %.2f", @"Compression enabled (ratio)"),
			[socket compressionRatio]]];
	} else {
		[_compressionTextField setStringValue:NSLS(@"No", @"Compression disabled")];
	}
	
	[self setYOffset:18.0];
	
	[self resizeTitleTextField:_compressionTitleTextField withTextField:_compressionTextField];
	[self resizeTitleTextField:_serializationTitleTextField withTextField:_serializationTextField];
	[self resizeTitleTextField:_cipherTitleTextField withTextField:_cipherTextField];
	[self resizeTitleTextField:_protocolTitleTextField withTextField:_protocolTextField];
	[self resizeTitleTextField:_versionTitleTextField withTextField:_versionTextField];
	[self resizeTitleTextField:_sizeTitleTextField withTextField:_sizeTextField];
	[self resizeTitleTextField:_filesTitleTextField withTextField:_filesTextField];
	[self resizeTitleTextField:_urlTitleTextField withTextField:_urlTextField];
	[self resizeTitleTextField:_uptimeTitleTextField withTextField:_uptimeTextField];
	[self resizeTitleTextField:_descriptionTitleTextField withTextField:_descriptionTextField];

	offset = [self yOffset];
	
	if([_bannerImageView image]) {
		rect = [_bannerImageView frame];
		rect.origin.y = offset + 14.0;
		offset += rect.size.height + 14.0;
		[_bannerImageView setFrame:rect];
	}

	rect = [_nameTextField frame];
	rect.origin.y = offset + 14.0;
	offset += rect.size.height + 14.0;
	[_nameTextField setFrame:rect];

	rect = [[self window] frame];
	rect.size.height = offset + 14.0;
	[[self window] setContentSize:rect.size];
	
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_reloadServerInfo)];
	[self performSelector:@selector(_reloadServerInfo) afterDelay:1.0];
}

@end


@implementation WCServerInfo

+ (id)serverInfoWithConnection:(WCServerConnection *)connection {
	return [[[self alloc] _initServerInfoWithConnection:connection] autorelease];
}



- (void)dealloc {
	[_dateFormatter release];
	[_timeIntervalFormatter release];
	[_sizeFormatter release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	[self setShouldCascadeWindows:NO];
	[self setShouldSaveWindowFrameOriginOnly:YES];
	[self setWindowFrameAutosaveName:@"ServerInfo"];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterNormalNaturalLanguageStyle];

	_timeIntervalFormatter = [[WITimeIntervalFormatter alloc] init];
	
	_sizeFormatter = [[WISizeFormatter alloc] init];
	
	[self setDefaultFrame:[_descriptionTextField frame]];

	[super windowDidLoad];
}



- (void)windowDidBecomeKey:(NSNotification *)notification {
	[self _updateServerInfo];
}



- (void)windowWillClose:(NSNotification *)notification {
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_reloadServerInfo)];
}



- (void)serverConnectionServerInfoDidChange:(NSNotification *)notification {
	[[self window] setTitle:[NSSWF:
		NSLS(@"%@ Info", @"Server info window title (server)"), [[self connection] name]]];

	[self _updateServerInfo];
	
	[super serverConnectionServerInfoDidChange:notification];
}



- (void)serverConnectionBannerDidChange:(NSNotification *)notification {
	[_bannerImageView setImage:[[[self connection] server] banner]];

	[self _updateServerInfo];
}

@end
