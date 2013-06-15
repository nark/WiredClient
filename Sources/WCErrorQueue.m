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

#import "WCErrorQueue.h"

@interface WCErrorQueue(Private)

- (void)_validate;
- (void)_updateForError:(NSError *)error;

@end

	
@implementation WCErrorQueue(Private)

- (void)_validate {
	[_historyControl setEnabled:(_shownError > 0) forSegment:0];
	[_historyControl setEnabled:(_shownError < [_errors count] - 1) forSegment:1];
	[_historyControl setHidden:([_errors count] == 1)];
}



- (void)_updateForError:(NSError *)error {
	NSRect			frame, previousFrame;
	CGFloat			difference = 0.0;
	
	[_titleTextField setStringValue:[error localizedDescription]];
	[_descriptionTextField setStringValue:[error localizedFailureReason]];
	
	previousFrame		= [_titleTextField frame];
	frame.size.width	= previousFrame.size.width;
	frame.size.height	= [[_titleTextField cell] cellSizeForBounds:NSMakeRect(0.0, 0.0, previousFrame.size.width, 10000.0)].height;
	frame.origin		= previousFrame.origin;
	frame.origin.y		= previousFrame.origin.y + (previousFrame.size.height - frame.size.height);
	difference			+= frame.size.height - previousFrame.size.height;
	
	[_titleTextField setFrame:frame];

	previousFrame		= [_descriptionTextField frame];
	frame.size.width	= previousFrame.size.width;
	frame.size.height	= [[_descriptionTextField cell] cellSizeForBounds:NSMakeRect(0.0, 0.0, previousFrame.size.width, 10000.0)].height;

	if(frame.size.height < 28.0)
		frame.size.height = 28.0;
	
	frame.origin		= previousFrame.origin;
	frame.origin.y		= previousFrame.origin.y + (previousFrame.size.height - frame.size.height) - difference;
	
	difference			+= frame.size.height - previousFrame.size.height;
	
	[_descriptionTextField setFrame:frame];
	
	frame				= [_dismissButton frame];
	frame.origin.y		-= difference;
	
	[_dismissButton setFrame:frame];
	
	frame				= [_historyControl frame];
	frame.origin.y		-= difference;
	
	[_historyControl setFrame:frame];
	
	previousFrame		= [_errorPanel frame];
	frame.size.width	= previousFrame.size.width;
	frame.size.height	= previousFrame.size.height + difference;
	frame.origin.y		= previousFrame.origin.y + (previousFrame.size.height - frame.size.height);
	frame.origin.x		= previousFrame.origin.x;
	
	[_errorPanel setFrame:frame display:YES animate:YES];
}

@end



@implementation WCErrorQueue

- (id)initWithWindow:(NSWindow *)window {
	self = [self init];
	
	_window			= [window retain];
	_errors			= [[NSMutableArray alloc] init];
	_identifiers	= [[NSMutableArray alloc] init];
	
	return self;
}



- (void)dealloc {
	[_window release];
	[_errors release];
	[_identifiers release];
	
	[super dealloc];
}



#pragma mark -

- (void)showError:(NSError *)error {
	[self showError:error withIdentifier:NULL];
}



- (void)showError:(NSError *)error withIdentifier:(NSString *)identifier {
	if(!_errorPanel)
		[NSBundle loadNibNamed:@"Error" owner:self];
	
	[_errors addObject:error];
	[_identifiers addObject:identifier ? identifier : @""];

	if(_showingPanel) {
		_shownError++;
		
		[self _validate];
		[self _updateForError:error];
	} else {
		_shownError = 0;
	
		[self _validate];
		[self _updateForError:error];
		
		if(![_window isOnScreen])
			[_window makeKeyAndOrderFront:self];
	
		[NSApp beginSheet:_errorPanel
		   modalForWindow:_window
			modalDelegate:self
		   didEndSelector:@selector(errorPanelDidEnd:returnCode:contextInfo:)
			  contextInfo:NULL];
		
		_showingPanel = YES;
	}
}



- (void)errorPanelDidEnd:(NSWindow *)window returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[_errors removeAllObjects];
	[_identifiers removeAllObjects];
	
	[_errorPanel close];
	
	_showingPanel = NO;
}



- (void)dismissErrorWithIdentifier:(NSString *)identifier {
	WCError			*error;
	NSUInteger		index;
	
	index = [_identifiers indexOfObject:identifier];
	
	if(index != NSNotFound) {
		[_errors removeObjectAtIndex:index];
		[_identifiers removeObjectAtIndex:index];
		
		if([_errors count] == 0) {
			[NSApp endSheet:_errorPanel];
		} else {
			if(_shownError >= index)
				_shownError--;
			
			error = [_errors objectAtIndex:_shownError];
			
			[self _validate];
			[self _updateForError:error];
		}
	}
}



#pragma mark -

- (IBAction)history:(id)sender {
	NSError			*error;

	if([_historyControl selectedSegment] == 0)
		_shownError--;
	else
		_shownError++;

	error = [_errors objectAtIndex:_shownError];
	
	[self _validate];
	[self _updateForError:error];
}

@end
