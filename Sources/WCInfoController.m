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

#import "WCInfoController.h"

@implementation WCInfoController

- (void)setDefaultFrame:(NSRect)frame {
	_defaultFrame = frame;
}



- (void)setYOffset:(CGFloat)offset {
	_offset = offset;
}



- (CGFloat)yOffset {
	return _offset;
}



#pragma mark -

- (void)removeView:(NSView **)view {
	[*view removeFromSuperviewWithoutNeedingDisplay];
	*view = NULL;
}



- (void)resizeTitleTextField:(NSTextField *)titleTextField withTextField:(NSTextField *)textField {
	NSRect		frame;
	
	if(textField) {
		if([[textField stringValue] length] == 0) {
			[textField setFrameOrigin:NSMakePoint([textField frame].origin.x, -100.0)];
			[titleTextField setFrameOrigin:NSMakePoint([titleTextField frame].origin.x, -100.0)];
		} else {
			frame.size = [[textField cell] cellSizeForBounds:NSMakeRect(0.0, 0.0, _defaultFrame.size.width, 10000.0)];
			frame.origin = NSMakePoint(_defaultFrame.origin.x, _offset);
			
			[textField setFrame:frame];
			
			[titleTextField setFrameSize:NSMakeSize([titleTextField frame].size.width, frame.size.height)];
			[titleTextField setFrameOrigin:NSMakePoint([titleTextField frame].origin.x, _offset)];
			
			_offset += frame.size.height + 2.0;
		}
	}
	else if(titleTextField) {
		frame = [titleTextField frame];
		frame.origin.y = _offset;
		[titleTextField setFrame:frame];
		
		_offset += frame.size.height + 2.0;
	}
}



- (void)resizeTitleTextField:(NSTextField *)textField withPopUpButton:(NSPopUpButton *)popUpButton {
	NSRect		frame;
	
	_offset += 3.0;

	[self resizeTitleTextField:textField withTextField:NULL];
	
	frame = [popUpButton frame];
	
	if(textField) {
		frame.origin.y = [textField frame].origin.y - 5.0;
	} else {
		frame.origin.y = _offset;
		_offset += frame.size.height;
	}
	
	[popUpButton setFrame:frame];
	
	_offset += 3.0;
}
	
@end
