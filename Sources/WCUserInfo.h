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

#import "WCInfoController.h"

@class WCErrorQueue, WCUser;

@interface WCUserInfo : WCInfoController {
	IBOutlet NSImageView			*_iconImageView;
	IBOutlet NSTextField			*_nickTextField;

	IBOutlet NSTextField			*_statusTextField;
	IBOutlet NSTextField			*_statusTitleTextField;
	IBOutlet NSTextField			*_loginTextField;
	IBOutlet NSTextField			*_loginTitleTextField;
	IBOutlet NSTextField			*_groupsTextField;
	IBOutlet NSTextField			*_groupsTitleTextField;
	IBOutlet NSTextField			*_addressTextField;
	IBOutlet NSTextField			*_addressTitleTextField;
	IBOutlet NSTextField			*_hostTextField;
	IBOutlet NSTextField			*_hostTitleTextField;
	IBOutlet NSTextField			*_versionTextField;
	IBOutlet NSTextField			*_versionTitleTextField;
	IBOutlet NSTextField			*_cipherTextField;
	IBOutlet NSTextField			*_cipherTitleTextField;
	IBOutlet NSTextField			*_loginTimeTextField;
	IBOutlet NSTextField			*_loginTimeTitleTextField;
	IBOutlet NSTextField			*_idleTimeTitleTextField;
	IBOutlet NSTextField			*_idleTimeTextField;
	
	WCErrorQueue					*_errorQueue;

	WCUser							*_user;
	WIDateFormatter					*_dateFormatter;
	WITimeIntervalFormatter			*_timeIntervalFormatter;
	NSRect							_fieldFrame;
	
	BOOL							_requestedAccount;
	BOOL							_waitingForAccount;
}

+ (id)userInfoWithConnection:(WCServerConnection *)connection user:(WCUser *)user;

- (IBAction)icon:(id)sender;

@end
