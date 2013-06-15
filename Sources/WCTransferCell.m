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

#import "WCTransfer.h"
#import "WCTransferCell.h"

NSString * const WCTransferCellNameKey			= @"WCTransferCellNameKey";
NSString * const WCTransferCellStatusKey		= @"WCTransferCellStatusKey";
NSString * const WCTransferCellProgressKey		= @"WCTransferCellProgressKey";


@interface WCTransferCell(Private)

- (void)_initTransferCell;

@end


@implementation WCTransferCell(Private)

- (void)_initTransferCell {
	NSMutableParagraphStyle		*style;

	_nameCell = [[NSCell alloc] init];
	[_nameCell setFont:[NSFont systemFontOfSize:12.0]];
	
	_statusCell = [[NSCell alloc] init];
	[_statusCell setFont:[NSFont systemFontOfSize:10.0]];
	
	style = [[NSMutableParagraphStyle alloc] init];
	[style setLineBreakMode:NSLineBreakByTruncatingMiddle];

	_nameAttributes = [[NSMutableDictionary alloc] init];
	[_nameAttributes setObject:[_nameCell font] forKey:NSFontAttributeName];
	[_nameAttributes setObject:style forKey:NSParagraphStyleAttributeName];
	
	_statusAttributes = [[NSMutableDictionary alloc] init];
	[_statusAttributes setObject:[_statusCell font] forKey:NSFontAttributeName];
	[_statusAttributes setObject:style forKey:NSParagraphStyleAttributeName];

	[style release];
}

@end



@implementation WCTransferCell

- (id)init {
	self = [super init];
	
	[self _initTransferCell];

	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	[self _initTransferCell];

	return self;
}



- (void)dealloc {
	[_nameCell release];
	[_statusCell release];

	[_nameAttributes release];
	[_statusAttributes release];

	[super dealloc];
}



#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
	WCTransferCell	*cell;
	
	cell = [super copyWithZone:zone];

	cell->_nameCell				= [_nameCell retain];
	cell->_statusCell			= [_statusCell retain];
	cell->_nameAttributes		= [_nameAttributes retain];
	cell->_statusAttributes		= [_statusAttributes retain];
	
	return cell;
}



#pragma mark -

- (void)setDrawsProgressIndicator:(BOOL)value {
	_drawsProgressIndicator = value;
}



- (BOOL)drawsProgressIndicator {
	return _drawsProgressIndicator;
}



#pragma mark -

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
	NSProgressIndicator			*progressIndicator;
	NSMutableAttributedString	*string;
	NSString					*name, *status;
	NSRect						rect;
	CGFloat						offset;
	
	name				= [(NSDictionary *) [self objectValue] objectForKey:WCTransferCellNameKey];
	status				= [(NSDictionary *) [self objectValue] objectForKey:WCTransferCellStatusKey];
	progressIndicator	= [(NSDictionary *) [self objectValue] objectForKey:WCTransferCellProgressKey];
	
	rect				= NSMakeRect(frame.origin.x - 2.0, frame.origin.y, frame.size.width, 16.0);
	string				= [NSMutableAttributedString attributedStringWithString:name attributes:_nameAttributes];
	
	if([_nameCell highlightColorWithFrame:rect inView:view] == [NSColor alternateSelectedControlColor]) {
		if([self isHighlighted]) {
			[string addAttribute:NSForegroundColorAttributeName
						   value:[NSColor whiteColor]
						   range:NSMakeRange(0, [string length])];
		}
	}
	
	[_nameCell setAttributedStringValue:string];
	[_nameCell drawWithFrame:rect inView:view];

	if([self drawsProgressIndicator]) {
		if(![progressIndicator superview])
			[view addSubview:progressIndicator];

		rect = NSMakeRect(frame.origin.x - 1.0, frame.origin.y + 19.0, frame.size.width - 5.0, 10.0);
		[progressIndicator setFrame:rect];
	} else {
		if([progressIndicator superview])
			[progressIndicator removeFromSuperview];
	}

	offset = [self drawsProgressIndicator] ? 32.0 : 19.0;
	rect = NSMakeRect(frame.origin.x - 2.0, frame.origin.y + offset, frame.size.width, 14.0);
	string = [NSMutableAttributedString attributedStringWithString:status attributes:_statusAttributes];
	
	if([_statusCell highlightColorWithFrame:rect inView:view] == [NSColor alternateSelectedControlColor]) {
		if([self isHighlighted]) {
			[string addAttribute:NSForegroundColorAttributeName
						   value:[NSColor whiteColor]
						   range:NSMakeRange(0, [string length])];
		}
	}
	
	[_statusCell setAttributedStringValue:string];
	[_statusCell drawWithFrame:rect inView:view];
}

@end
