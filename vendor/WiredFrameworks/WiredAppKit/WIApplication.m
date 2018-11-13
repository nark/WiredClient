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

#import <WiredFoundation/NSObject-WIFoundation.h>
#import <WiredAppKit/NSApplication-WIAppKit.h>
#import <WiredAppKit/NSTextView-WIAppKit.h>
#import <WiredAppKit/WIApplication.h>

NSString * const WIApplicationDidChangeActiveNotification	= @"WIApplicationDidChangeActiveNotification";
NSString * const WIApplicationDidChangeFlagsNotification	= @"WIApplicationDidChangeFlagsNotification";



@interface WIApplication(Private)

- (NSString *)_terminationDelayStringValue;

@end


@implementation WIApplication(Private)

- (void)_terminationDelayTimer:(NSTimer *)timer {
	_terminationDelay--;
	
	if(_terminationDelay > 0.0) {
		[[[[[NSApp keyWindow] contentView] subviews] objectAtIndex:2] setStringValue:
			[self _terminationDelayStringValue]];
	} else {
		[NSApp stopModalWithCode:NSAlertDefaultReturn];
		[timer invalidate];
	}
}



- (NSString *)_terminationDelayStringValue {
	NSString		*string;
	
	string = [NSSWF:WILS(@"If you do nothing, %@ will quit automatically in %.0f seconds.",
						 @"WIApplication: termination delay panel (application, timeout)"),
		[self name],
		_terminationDelay];
	
	if(!_terminationMessage)
		return string;
	
	return [NSSWF:@"%@ %@", _terminationMessage, string];
}

@end



@implementation WIApplication

- (void)finishLaunching {
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(_WI_applicationDidBecomeActive:)
			   name:NSApplicationDidBecomeActiveNotification
			 object:NULL];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(_WI_applicationDidResignActive:)
			   name:NSApplicationDidResignActiveNotification
			 object:NULL];
	
	if([[self delegate] respondsToSelector:@selector(applicationDidChangeActiveStatus:)]) {
		[[NSNotificationCenter defaultCenter]
			addObserver:[self delegate]
			   selector:@selector(applicationDidChangeActiveStatus:)
				   name:WIApplicationDidChangeActiveNotification
				 object:NULL];
	}
	
	[super finishLaunching];
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
				  name:NSApplicationDidBecomeActiveNotification
				object:NULL];

	[[NSNotificationCenter defaultCenter]
		removeObserver:self
				  name:NSApplicationDidResignActiveNotification
				object:NULL];

	[[NSNotificationCenter defaultCenter]
		removeObserver:[self delegate]
				  name:WIApplicationDidChangeActiveNotification
				object:NULL];
	
	[_releaseNotesWindow release];
	
	[super dealloc];
}



#pragma mark -

- (void)_WI_applicationDidBecomeActive:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter]
		postNotificationName:WIApplicationDidChangeActiveNotification
		object:self];
}

- (void)_WI_applicationDidResignActive:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter]
		postNotificationName:WIApplicationDidChangeActiveNotification
		object:self];
}

- (void)applicationDidChangeActiveStatus:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:WIApplicationDidChangeActiveNotification
     object:self];
}

#pragma mark -

- (void)sendEvent:(NSEvent *)event {
	switch([event type]) {
		case NSFlagsChanged:
			[super sendEvent:event];
			
			[[NSNotificationCenter defaultCenter]
				postNotificationName:WIApplicationDidChangeFlagsNotification
				object:event];
			break;
			
		default:
			[super sendEvent:event];
			break;
	}
}
 


#pragma mark -

- (NSApplicationTerminateReply)runTerminationDelayPanelWithTimeInterval:(NSTimeInterval)delay {
	return [self runTerminationDelayPanelWithTimeInterval:delay message:NULL];
}



- (NSApplicationTerminateReply)runTerminationDelayPanelWithTimeInterval:(NSTimeInterval)delay message:(NSString *)message {
	NSTimer		*timer;
	NSInteger	result;
	
	_terminationDelay   = delay;
	_terminationMessage = [message retain];

	timer = [NSTimer timerWithTimeInterval:1.0
									target:self
								  selector:@selector(_terminationDelayTimer:)
								  userInfo:NULL
								   repeats:YES];
    
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
    
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:WILS(@"Are you sure you want to quit?", @"WIApplication: termination delay panel")];
    [alert addButtonWithTitle:WILS(@"Quit",   @"WIApplication: termination delay panel")];
    [alert addButtonWithTitle:WILS(@"Cancel", @"WIApplication: termination delay panel")];
    [alert setInformativeText:[self _terminationDelayStringValue]];
    
    result = [alert runModal];
    
	[_terminationMessage release];
	[timer invalidate];
    	
	if(result == NSAlertFirstButtonReturn)
		return NSTerminateNow;
	
    else if (result == NSAlertSecondButtonReturn)
        return NSTerminateCancel;
    
    return 1;
}

@end
