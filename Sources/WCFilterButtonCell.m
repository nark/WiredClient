/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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

#import "WCFilterButtonCell.h"

@interface WCFilterButtonCell(Private)

- (void)_drawWithFrame:(NSRect)frame inButton:(NSButton *)button;

@end


@implementation WCFilterButtonCell(Private)

- (void)_drawWithFrame:(NSRect)frame inButton:(NSButton *)button {
    NSAttributedString *string;
    NSShadow *shadow;
    NSDictionary *attributes;

    if (!_leftImage) {
        _leftImage = [NSImage imageNamed:@"FilterButtonLeft"];
        _middleImage = [NSImage imageNamed:@"FilterButtonMiddle"];
        _rightImage = [NSImage imageNamed:@"FilterButtonRight"];
    }

    NSRect leftImageRect = NSMakeRect(frame.origin.x, frame.origin.y, _leftImage.size.width, _leftImage.size.height);
    [_leftImage drawInRect:leftImageRect];

    NSRect middleImageRect = NSMakeRect(frame.origin.x + _leftImage.size.width, frame.origin.y, frame.size.width - _leftImage.size.width - _rightImage.size.width, _middleImage.size.height);
    [_middleImage drawInRect:middleImageRect];

    NSRect rightImageRect = NSMakeRect(frame.origin.x + frame.size.width - _rightImage.size.width, frame.origin.y, _rightImage.size.width, _rightImage.size.height);
    [_rightImage drawInRect:rightImageRect];

    shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor darkGrayColor]];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];

    attributes = @{NSForegroundColorAttributeName: [NSColor whiteColor],
                   NSFontAttributeName: [self font],
                   NSShadowAttributeName: shadow};

    string = [[NSAttributedString alloc] initWithString:[self title] attributes:attributes];

    NSSize stringSize = [string size];
    NSRect stringRect = NSMakeRect(frame.origin.x + (_middleImage.size.width - stringSize.width) / 2.0, frame.origin.y + (_middleImage.size.height - stringSize.height) / 2.0, stringSize.width, stringSize.height);
    [string drawInRect:stringRect];

    [shadow release];
    [string release];
}

@end



@implementation WCFilterButtonCell

- (void)dealloc {
	[_leftImage release];
	[_middleImage release];
	[_rightImage release];
	
	[super dealloc];
}



#pragma mark -

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
	NSButton		*button = (NSButton *) view;
	
	if([button state] == NSOnState)
		[self _drawWithFrame:frame inButton:button];
	else
		[super drawWithFrame:frame inView:view];
}

@end
