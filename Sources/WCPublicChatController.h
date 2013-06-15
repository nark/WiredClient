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

#import "WCChatController.h"

@interface WCPublicChatController : WCChatController {
	IBOutlet NSView						*_publicChatView;
	
	IBOutlet NSButton					*_privateChatButton;
	IBOutlet NSButton					*_banButton;

	IBOutlet NSPanel					*_banMessagePanel;
	IBOutlet NSTextField				*_banMessageTextField;
	IBOutlet NSPopUpButton				*_banMessagePopUpButton;
	
	IBOutlet NSPanel					*_changePasswordPanel;
	IBOutlet NSSecureTextField			*_newPasswordTextField;
	IBOutlet NSSecureTextField			*_verifyPasswordTextField;
	IBOutlet NSTextField				*_passwordMismatchTextField;
}

+ (id)publicChatControllerWithConnection:(WCServerConnection *)connection;

- (IBAction)startPrivateChat:(id)sender;
- (IBAction)ban:(id)sender;

- (IBAction)changePassword:(id)sender;
- (IBAction)submitPasswordSheet:(id)sender;

@end
