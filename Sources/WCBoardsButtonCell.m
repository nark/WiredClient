//
//  WCBoardsButtonCell.m
//  WiredClient
//
//  Created by Axel Andersson on 2009-10-13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WCBoardsButtonCell.h"

NSString * const WCBoardsButtonCellValueKey			= @"WCBoardsButtonCellValueKey";
NSString * const WCBoardsButtonCellButtonKey		= @"WCBoardsButtonCellButtonKey";


@interface WCBoardsButtonCell(Private)

- (void)_initBoardsButtonCell;

@end


@implementation WCBoardsButtonCell(Private)

- (void)_initBoardsButtonCell {
}

@end



@implementation WCBoardsButtonCell

- (id)init {
	self = [super init];
	
	[self _initBoardsButtonCell];

	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	[self _initBoardsButtonCell];

	return self;
}



#pragma mark -

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
	NSButton		*button;
	NSString		*value;
	
	value		= [(NSDictionary *) [self objectValue] objectForKey:WCBoardsButtonCellValueKey];
	button		= [(NSDictionary *) [self objectValue] objectForKey:WCBoardsButtonCellButtonKey];
	
	if(value && button) {
		if(![button superview])
			[view addSubview:button];
		
		[button setFrame:NSMakeRect(frame.origin.x, frame.origin.y - 1.0, 16.0, 16.0)];

		[self setStringValue:value];
	}
	
	[super drawWithFrame:NSMakeRect(frame.origin.x + 16.0, frame.origin.y, frame.size.width - 16.0, frame.size.height) inView:view];
}

@end
