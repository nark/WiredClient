/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
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

#import <WiredAppKit/NSEvent-WIAppKit.h>
#import <WiredAppKit/NSFont-WIAppKit.h>
#import <WiredAppKit/WIWindow.h>

@implementation WIWindow

- (void)setDelegate:(id)delegate {
	[super setDelegate:delegate];
	
	_delegateWindowTitleBarMenu = [[self delegate] respondsToSelector:@selector(windowTitleBarMenu:)];
}



//- (void)sendEvent:(NSEvent *)event {
//	BOOL	handled = NO;
//	
//	if(_delegateWindowTitleBarMenu && [event type] == NSLeftMouseDown && [event commandKeyModifier]) {
//		NSPoint		point;
//		NSRect		frame;
//		NSSize		size;
//		
//		point = [event locationInWindow];
//		frame = [self frame];
//		size = [[NSFont titleBarFont] sizeOfString:[self title]];
//		
//		if(frame.size.height - point.y <= size.height + 5.0 &&
//		   point.x > (frame.size.width / 2.0) - (size.width / 2.0) &&
//		   point.x < (frame.size.width / 2.0) + (size.width / 2.0)) {
//			NSMenu		*menu;
//			NSEvent		*menuEvent;
//			NSPoint		menuPoint;
//			
//			menu = [[self delegate] windowTitleBarMenu:self];
//			
//			if(menu) {
//				menuPoint = NSMakePoint((frame.size.width / 2.0) - (size.width / 2.0),
//										frame.size.height - 2.0);
//				
//				menuEvent = [NSEvent mouseEventWithType:[event type]
//											   location:menuPoint
//										  modifierFlags:[event modifierFlags]
//											  timestamp:[event timestamp]
//										   windowNumber:[event windowNumber]
//												context:[event context]
//											eventNumber:[event eventNumber]
//											 clickCount:[event clickCount]
//											   pressure:[event pressure]];
//				
//				[NSMenu popUpContextMenu:menu withEvent:menuEvent forView:NULL];
//				
//				handled = YES;
//			}
//		}
//	}
//	
//	if(!handled)
//		[super sendEvent:event];
//}

@end
