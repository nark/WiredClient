//
//  WCChatInputTextView.m
//  WiredClient
//
//  Created by Rafaël Warnault on 17/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCChatInputTextView.h"

@implementation WCChatInputTextView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib {
	[super setTextContainerInset:NSMakeSize(3.0f, 3.0f)];
}


- (void)drawRect:(NSRect)dirtyRect {
	// Drawing code here
	NSRect rect = [self bounds];
	
	[NSGraphicsContext saveGraphicsState];
	
	NSRect newRect = NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	newRect = NSInsetRect(newRect, 1.0, 1.0);
	NSBezierPath *textViewSurround = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:3 yRadius:3];
	[textViewSurround setLineWidth:1.0];
	
	[[NSColor darkGrayColor] set];
	[textViewSurround stroke];
	
	[[self backgroundColor] set];
	[textViewSurround fill];	
	
	[NSGraphicsContext restoreGraphicsState];
	
	NSRange range;
	if(![self layoutManager])
		return;

	range = [[self layoutManager] glyphRangeForBoundingRectWithoutAdditionalLayout:rect inTextContainer:[super textContainer]];
	
	if([self selectedRange].length > 0)
		[[self layoutManager] drawBackgroundForGlyphRange:range atPoint:[super textContainerOrigin]];
	
	[[self layoutManager] drawGlyphsForGlyphRange:range atPoint:[super textContainerOrigin]];
}



- (void)insertAttributedString:(NSAttributedString *)string atIndex:(NSUInteger)index {
	[super insertAttributedString:string atIndex:index];
	
	[self setNeedsDisplay:YES];
}


@end
