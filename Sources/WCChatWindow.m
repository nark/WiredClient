/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
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

#import "WCChatWindow.h"
#import "WCPublicChat.h"

@implementation WCChatWindow

- (void)sendEvent:(NSEvent *)event {
	static NSMutableCharacterSet	*characterSet;
	NSTextField						*textField;
    NSString                        *string;
	BOOL							handled = NO;
	
	if([event type] == NSKeyDown) {
		if(!characterSet) {
			characterSet = [[NSMutableCharacterSet alphanumericCharacterSet] retain];
			[characterSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
			[characterSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
			[characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
			[characterSet removeCharactersInString:@"\t"];
		}
		
		textField = [(WCPublicChat *)[self delegate] insertionTextField];
        NSText* fieldEditor = [self fieldEditor:YES forObject:textField];
        
		if(fieldEditor && [self firstResponder] != textField) {
			if([[event characters] isComposedOfCharactersFromSet:characterSet]) {
                // make the field first responder without losing selection
                NSRange oldRange = fieldEditor.selectedRange;
                    
                [fieldEditor setSelectable:NO];
                [self makeFirstResponder:textField];
                [fieldEditor setSelectable:YES];
                
                if(oldRange.location != NSNotFound)
                    [fieldEditor setSelectedRange:oldRange];
                
                if(fieldEditor.selectedRange.location != NSNotFound) {
                    [textField setStringValue:[[textField stringValue] stringByReplacingCharactersInRange:fieldEditor.selectedRange withString:@""]];
                    [fieldEditor setSelectedRange:NSMakeRange(fieldEditor.selectedRange.location,0)];
                } else {
                    [fieldEditor setSelectedRange:NSMakeRange([[fieldEditor string] length],0)];
                }
                [fieldEditor setNeedsDisplay:YES];
            }
		}
	}
	
	if(!handled && event)
		[super sendEvent:event];
}



- (void)paste:(id)sender {
	NSTextField		*textField;

	textField = [(WCPublicChat *)[self delegate] insertionTextField];
	
	if(textField) {
        NSText* fieldEditor = [self fieldEditor:YES forObject:textField];
        
		[self makeFirstResponder:textField];
		[fieldEditor paste:sender];
	}
}

@end
