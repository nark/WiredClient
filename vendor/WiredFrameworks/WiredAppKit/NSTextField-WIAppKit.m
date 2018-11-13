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

#import <WiredAppKit/NSTextField-WIAppKit.h>

#define WI_APPKIT_MESSAGE_VIEW_DEFAULT_HEIGHT 64

@implementation NSTextField(WIAppKit)

- (void)sizeToFitFromContent {
	NSRect		frame;
	NSSize		size;
	
	frame = [self frame];
	size = [[self cell] cellSizeForBounds:NSMakeRect(0, 0, frame.size.width, 10000.0)];
	
	[self setFrameSize:size];
}


- (void)adjustHeightForTopView:(NSView *)topView bottomView:(NSView *)bottomView {
    NSText              *fieldEditor;
    NSTextView          *textView;
    NSRect              usedRect;
    NSInteger           height, offset;
    
    fieldEditor = [[self window] fieldEditor:NO forObject:self];
    
    if([fieldEditor isKindOfClass:[NSTextView class]]) {
        textView      = (NSTextView *)fieldEditor;
        usedRect      = [textView.textContainer.layoutManager usedRectForTextContainer:textView.textContainer];
        height        = usedRect.size.height;
        offset        = usedRect.size.height - self.frame.size.height;
        
        if(usedRect.size.height > self.frame.size.height) {
            [bottomView setFrame:NSMakeRect(bottomView.frame.origin.x,
                                            bottomView.frame.origin.y,
                                            bottomView.frame.size.width,
                                            bottomView.frame.size.height + height)];
            
            [topView setFrame:NSMakeRect(topView.frame.origin.x,
                                         topView.frame.origin.y + height,
                                         topView.frame.size.width,
                                         topView.frame.size.height - height)];
            
        } else {
            if([[self stringValue] length] == 0) {
                height = bottomView.frame.size.height - WI_APPKIT_MESSAGE_VIEW_DEFAULT_HEIGHT;
                
                [bottomView setFrame:NSMakeRect(bottomView.frame.origin.x,
                                                bottomView.frame.origin.y,
                                                bottomView.frame.size.width,
                                                WI_APPKIT_MESSAGE_VIEW_DEFAULT_HEIGHT)];
                
                [topView setFrame:NSMakeRect(topView.frame.origin.x,
                                             topView.frame.origin.y - height,
                                             topView.frame.size.width,
                                             topView.frame.size.height + height)];
            }
        }
    }
}



#pragma mark -

- (void)setPlaceholderString:(NSString *)string {
	[[self cell] setPlaceholderString:string];
}



- (NSString *)placeholderString {
	return [[self cell] placeholderString];
}

@end
