/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#import "WCApplicationController.h"
#import "WCConnect.h"
#import "WCErrorQueue.h"
#import "WCServerConnection.h"
#import "WCTransfers.h"
#import "WCKeychain.h"

@interface WCConnect(Private)

- (id)_initConnectWithURL:(WIURL *)url bookmark:(NSDictionary *)bookmark;

@end


@implementation WCConnect(Private)

- (id)_initConnectWithURL:(WIURL *)url bookmark:(NSDictionary *)bookmark {
	NSDictionary		*theme;
	
	self = [super initWithWindowNibName:@"Connect"];
	
	_url = [url retain];
    
    // check that bookmark password was loaded from keychain
    if (_url.password == nil) {
        [_url setPassword:[[WCKeychain keychain] passwordForBookmark:bookmark]];
    }
    
	_connection = [[WCServerConnection connection] retain];
	[_connection setURL:url];
	[_connection setBookmark:bookmark];
	
	theme = [[WCSettings settings] themeWithIdentifier:[bookmark objectForKey:WCBookmarksTheme]];
	
	if(!theme)
		theme = [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	
	[_connection setTheme:theme];
	
	[_connection addObserver:self
					selector:@selector(linkConnectionDidClose:)
						name:WCLinkConnectionDidCloseNotification];
	
	[_connection addObserver:self
					selector:@selector(linkConnectionDidTerminate:)
						name:WCLinkConnectionDidTerminateNotification];
	
	[_connection addObserver:self
					selector:@selector(linkConnectionLoggedIn:)
						name:WCLinkConnectionLoggedInNotification];
	
	[_connection addObserver:self
					selector:@selector(serverConnectionReceivedLoginError:)
						name:WCServerConnectionReceivedLoginErrorNotification];
	
	[self window];
	
	return self;
}

@end




@implementation WCConnect

+ (id)connect {
	return [[[self alloc] _initConnectWithURL:NULL bookmark:NULL] autorelease];
}



+ (id)connectWithURL:(WIURL *)url bookmark:(NSDictionary *)bookmark {
	return [[[self alloc] _initConnectWithURL:url bookmark:bookmark] autorelease];
}



- (void)dealloc {
	[_errorQueue release];
	
	[_url release];

	[_connection removeObserver:self];
	[_connection release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	_errorQueue = [[WCErrorQueue alloc] initWithWindow:[self window]];

    [self setShouldCascadeWindows:YES];
    [self setWindowFrameAutosaveName:@"Connect"];
	
	if([_url hostpair])
		[_addressTextField setStringValue:[_url hostpair]];
	
	if([_url user])
		[_loginTextField setStringValue:[_url user]];
	
	if([_url password])
		[_passwordTextField setStringValue:[_url password]];
	
	[self retain];
}



- (void)windowWillClose:(NSNotification *)notification {
	if(!_dismissingWindow) {
		[_connection removeObserver:self name:WCLinkConnectionDidTerminateNotification];
		[_connection terminate];
	}

	[self autorelease];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	NSMutableDictionary		*userInfo;
	NSString				*reason;
	NSAlert					*alert;
	WCError					*error;
	BOOL					checkForUpdate = NO;
	
	if([notification object] != _connection)
		return;
	
	error = [_connection error];
	
	if(error) {
		if([[error domain] isEqualToString:WIWiredNetworkingErrorDomain] &&
		   [error code] == WISocketConnectFailed &&
		   [[[error userInfo] objectForKey:WILibWiredErrorKey] code] == WI_ERROR_P7_INCOMPATIBLESPEC) {
			userInfo = [[[error userInfo] mutableCopy] autorelease];
			
			reason = [NSSWF:@"%@\n\n%@",
				[error localizedFailureReason],
				NSLS(@"You may need to download a newer version of Wired Client to connect to this server.", @"Connect error")];
			
			[userInfo setObject:reason forKey:NSLocalizedFailureReasonErrorKey];
			
			error				= [WCError errorWithDomain:WIWiredNetworkingErrorDomain code:[error code] userInfo:userInfo];
			checkForUpdate		= YES;
		}
		
		[self showWindow:self];
		
		alert = [error alert];
		
		if(checkForUpdate)
			[alert addButtonWithTitle:NSLS(@"Check for Update", @"Check for update button")];
		
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:self
						 didEndSelector:@selector(connectAlertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
	}
	
	[_progressIndicator stopAnimation:self];
	[_connectButton setEnabled:YES];
}



- (void)linkConnectionDidTerminate:(NSNotification *)notification {
	if([notification object] != _connection)
		return;

	[self close];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	if([notification object] != _connection)
		return;

	_dismissingWindow = YES;
    
    if([[_url pathExtension] length] > 0)
        [WCTransfers downloadFileAtPath:[_url path] forConnection:_connection];
	
	[self close];
}



- (void)serverConnectionReceivedLoginError:(NSNotification *)notification {
	WCServerConnection		*connection;
	
	connection = [notification object];
	
	[_errorQueue showError:[connection error]];
	
	[connection disconnect];
	
	[_progressIndicator stopAnimation:self];
	[_connectButton setEnabled:YES];
}



#pragma mark -

- (IBAction)connect:(id)sender {
	WIURL		*url;
	
	url = [WIURL URLWithScheme:@"wiredp7" hostpair:[_addressTextField stringValue]];
	[url setUser:[_loginTextField stringValue]];
	[url setPassword:[_passwordTextField stringValue]];
	
	[_connectButton setEnabled:NO];
	[_progressIndicator startAnimation:self];
	
	[_connection setURL:url];
	[_connection connect];
}



- (void)connectAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if(returnCode == NSAlertSecondButtonReturn)
		[[WCApplicationController sharedController] checkForUpdate];
}

@end
