//
//  WCBoardPostCellView.m
//  Wired Client
//
//  Created by Rafael Warnault on 04/05/2020.
//

#import "WCBoardPostCellView.h"

@implementation WCBoardPostCellView

#pragma mark -

- (void)ensureTrackingArea {
    if (_trackingArea == nil) {
        _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                     options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited
                                                       owner:self
                                                    userInfo:nil];
        
        [self addTrackingArea:_trackingArea];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
}

- (void)dealloc {
    [_trackingArea release];
    
    
    [super dealloc];
}


#pragma mark -

- (void)awakeFromNib {
    [self setButtonsHidden:YES];
    
    [self ensureTrackingArea];
}


- (void)layout {
    [super layout];
    
    [self ensureTrackingArea];
    [self updateTrackingAreas];
}

#pragma mark -

- (void)mouseEntered:(NSEvent *)theEvent {
    [self setButtonsHidden:NO];
    [self.unreadImageView setHidden:YES];
    
}

- (void)mouseExited:(NSEvent *)theEvent {
    [self setButtonsHidden:YES];
}


- (void)setButtonsHidden:(BOOL)hidden {
    [self.replyButton setHidden:hidden];
    [self.quoteButton setHidden:hidden];
    [self.editButton setHidden:hidden];
    [self.deleteButton setHidden:hidden];
}


#pragma mark -

- (IBAction)replyPost:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(postCell:replyButtonClicked:)]) {
        [self.delegate postCell:self replyButtonClicked:sender];
    }
}

- (IBAction)quotePost:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(postCell:quoteButtonClicked:)]) {
        [self.delegate postCell:self quoteButtonClicked:sender];
    }
}

- (IBAction)editPost:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(postCell:editButtonClicked:)]) {
        [self.delegate postCell:self editButtonClicked:sender];
    }
}

- (IBAction)deletePost:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(postCell:deleteButtonClicked:)]) {
        [self.delegate postCell:self deleteButtonClicked:sender];
    }
}

@end
