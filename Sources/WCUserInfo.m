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

#import "WCAccount.h"
#import "WCErrorQueue.h"
#import "WCServerConnection.h"
#import "WCUser.h"
#import "WCUserInfo.h"

@interface WCUserInfo(Private)

- (id)_initUserInfoWithConnection:(WCServerConnection *)connection user:(WCUser *)user;

- (void)_reloadUserInfo;
- (void)_showUserInfo;

- (void)_moveView:(NSView *)view byYOffset:(CGFloat)offset;

@end


@implementation WCUserInfo(Private)

- (id)_initUserInfoWithConnection:(WCServerConnection *)connection user:(WCUser *)user {
	self = [super initWithWindowNibName:@"UserInfo" connection:connection singleton:NO];

	_user = [user retain];

	[self _reloadUserInfo];
		
	[self window];

	return self;
}



#pragma mark -

- (void)_reloadUserInfo {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.user.get_info" spec:WCP7Spec];
	[message setUInt32:[_user userID] forName:@"wired.user.id"];
	[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredUserGetInfoReply:)];
}



- (void)_showUserInfo {
	NSMutableArray		*groups;
	NSRect				rect;
	CGFloat				height;

	[_iconImageView setImage:[_user iconWithIdleTint:NO]];
	[_nickTextField setStringValue:[_user nick]];
	[_statusTextField setStringValue:[_user status]];
	[_loginTextField setStringValue:[_user login]];
	
	if([_user account]) {
		groups = [[[[_user account] groups] mutableCopy] autorelease];
		
		if([[[_user account] group] length] > 0) {
			if([groups count] > 0)
				[groups insertObject:[[_user account] group] atIndex:0];
			else
				[groups addObject:[[_user account] group]];
		}
		
		[_groupsTextField setStringValue:[groups componentsJoinedByString:@", "]];
	}

	[_addressTextField setStringValue:[_user address]];
	[_hostTextField setStringValue:[_user host]];
	[_versionTextField setStringValue:[_user version]];
	
	if([_user cipherBits] > 0) {
		[_cipherTextField setStringValue:[NSSWF:@"%@/%u %@",
			[_user cipherName],
			[_user cipherBits],
			NSLS(@"bits", "Cipher string")]];
	}
	
	[_loginTimeTextField setStringValue:[NSSWF:
		NSLS(@"%@,\nsince %@", @"Time stamp (time counter, time string)"),
		[_timeIntervalFormatter stringFromTimeIntervalSinceDate:[_user joinDate]],
		[_dateFormatter stringFromDate:[_user joinDate]]]];
	
	[_idleTimeTextField setStringValue:[NSSWF:
		NSLS(@"%@,\nsince %@", @"Time stamp (time counter, time string)"),
		[_timeIntervalFormatter stringFromTimeIntervalSinceDate:[_user idleDate]],
		[_dateFormatter stringFromDate:[_user idleDate]]]];
	
	[self setYOffset:18.0];
	[self resizeTitleTextField:_idleTimeTitleTextField withTextField:_idleTimeTextField];
	[self resizeTitleTextField:_loginTimeTitleTextField withTextField:_loginTimeTextField];
	[self resizeTitleTextField:_cipherTitleTextField withTextField:_cipherTextField];
	[self resizeTitleTextField:_versionTitleTextField withTextField:_versionTextField];
	[self resizeTitleTextField:_hostTitleTextField withTextField:_hostTextField];
	[self resizeTitleTextField:_addressTitleTextField withTextField:_addressTextField];
	[self resizeTitleTextField:_groupsTitleTextField withTextField:_groupsTextField];
	
	[self resizeTitleTextField:_loginTitleTextField withTextField:_loginTextField];
	[self resizeTitleTextField:_statusTitleTextField withTextField:_statusTextField];
	
	[self _moveView:_nickTextField byYOffset:[self yOffset] + 23.0];
	[self _moveView:_iconImageView byYOffset:[self yOffset] + 12.0];
	
	rect = [[self window] frame];
	height = rect.size.height;
	rect.size.height = [self yOffset] + 84.0;
	rect.origin.y -= rect.size.height - height;
	[[self window] setFrame:rect display:YES animate:YES];
	
	if(![[self window] isOnScreen])
		[self showWindow:self];
}



#pragma mark -

- (void)_moveView:(NSView *)view byYOffset:(CGFloat)offset {
	NSRect		rect;
	
	rect = [view frame];
	rect.origin.y = offset;
	[view setFrame:rect];
}

@end


@implementation WCUserInfo

+ (id)userInfoWithConnection:(WCServerConnection *)connection user:(WCUser *)user {
	return [[[self alloc] _initUserInfoWithConnection:connection user:user] autorelease];
}



- (void)dealloc {
	[_errorQueue release];
	[_user release];
	[_dateFormatter release];
	[_timeIntervalFormatter release];

	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	_errorQueue = [[WCErrorQueue alloc] initWithWindow:[self window]];
	
	[[self window] setTitle:[NSSWF:
		NSLS(@"%@ Info", @"User info window title (nick)"), [_user nick]]];
	
	[self setShouldCascadeWindows:YES];
	[self setShouldSaveWindowFrameOriginOnly:YES];
	[self setWindowFrameAutosaveName:@"UserInfo"];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterNormalNaturalLanguageStyle];

	_timeIntervalFormatter = [[WITimeIntervalFormatter alloc] init];
	
	_fieldFrame	= [_statusTextField frame];
	[self setDefaultFrame:[_statusTextField frame]];
	
	[super windowDidLoad];
}



- (void)windowWillClose:(NSNotification *)notification {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}



- (void)wiredUserGetInfoReply:(WIP7Message *)message {
	WCUserAccount		*account;
	WIP7Message			*reply;
	
	if([[message name] isEqualToString:@"wired.user.info"]) {
		account = [[_user account] retain];
		[_user release];
		_user = [[WCUser userWithMessage:message connection:[self connection]] retain];
		[_user setAccount:account];
		[account release];
		
		_waitingForAccount = NO;

		if([[[self connection] account] accountReadAccounts]) {
			if(![_user account] && !_requestedAccount) {
				reply = [WIP7Message messageWithName:@"wired.account.read_user" spec:WCP7Spec];
				[reply setString:[_user login] forName:@"wired.account.name"];
				[[self connection] sendMessage:reply fromObserver:self selector:@selector(wiredAccountReadAccountReply:)];
				
				_waitingForAccount = YES;
				_requestedAccount = YES;
			}
		}

		if(!_waitingForAccount) {
			[self _showUserInfo];
			[self performSelector:@selector(_reloadUserInfo) withObject:NULL afterDelay:1.0];
		}
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
	}
}



- (void)wiredAccountReadAccountReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.account.user"]) {
		[_user setAccount:[WCUserAccount accountWithMessage:message]];
		
		[self _showUserInfo];
		[self performSelector:@selector(_reloadUserInfo) withObject:NULL afterDelay:1.0];
	}
	else if([[message name] isEqualToString:@"wired.error"])
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
}



#pragma mark -

- (IBAction)icon:(id)sender { 
	[_iconImageView setImage:[_user iconWithIdleTint:NO]]; 
} 

@end
