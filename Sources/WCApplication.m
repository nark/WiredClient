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
#import "WCApplication.h"

@implementation WCApplication

- (id)init {
    self = [super init];
    if (self) {
        [[NSImage imageNamed:@"Smileys"] setTemplate:YES];
        
        [[NSImage imageNamed:@"Kick"] setTemplate:YES];
        [[NSImage imageNamed:@"UserInfo"] setTemplate:YES];
        [[NSImage imageNamed:@"PrivateChat"] setTemplate:YES];
        [[NSImage imageNamed:@"PrivateMessage"] setTemplate:YES];
        [[NSImage imageNamed:@"RightViewNavigator"] setTemplate:YES];
        [[NSImage imageNamed:@"LeftViewNavigator"] setTemplate:YES];
        
        [[NSImage imageNamed:@"NewThread"] setTemplate:YES];
        [[NSImage imageNamed:@"DeleteThread"] setTemplate:YES];
        [[NSImage imageNamed:@"ReplyThread"] setTemplate:YES];
        [[NSImage imageNamed:@"MarkAsRead"] setTemplate:YES];
        [[NSImage imageNamed:@"MarkAllAsRead"] setTemplate:YES];
        
        [[NSImage imageNamed:@"Disconnect"] setTemplate:YES];
        [[NSImage imageNamed:@"DeleteFile"] setTemplate:YES];
        [[NSImage imageNamed:@"DeleteBookmark"] setTemplate:YES];
        [[NSImage imageNamed:@"DeleteAccount"] setTemplate:YES];
    }
    return self;
}

- (void)sendEvent:(NSEvent *)event {
	BOOL	handled = NO;

	if([event type] == NSKeyDown) {
        if([event character] == NSF12FunctionKey && [event controlKeyModifier]) {
			handled = [self sendAction:@selector(stats:) to:NULL from:self];
        }
	}

	if(!handled)
		[super sendEvent:event];
}

@end
