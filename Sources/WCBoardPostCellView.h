//
//  WCBoardPostCellView.h
//  Wired Client
//
//  Created by Rafael Warnault on 04/05/2020.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class WCBoardPostCellView;

@protocol WCBoardPostCellViewDelegate <NSObject>

@optional
- (void)postCell:(WCBoardPostCellView *)cell replyButtonClicked:(NSButton *)sender;
- (void)postCell:(WCBoardPostCellView *)cell quoteButtonClicked:(NSButton *)sender;
- (void)postCell:(WCBoardPostCellView *)cell editButtonClicked:(NSButton *)sender;
- (void)postCell:(WCBoardPostCellView *)cell deleteButtonClicked:(NSButton *)sender;

@end


@interface WCBoardPostCellView : NSTableCellView {
    NSTrackingArea  *_trackingArea;
    NSEvent         *event;
}

@property (nonatomic, weak) id <WCBoardPostCellViewDelegate> delegate;

@property (nonatomic, retain) IBOutlet NSButton *replyButton;
@property (nonatomic, retain) IBOutlet NSButton *quoteButton;
@property (nonatomic, retain) IBOutlet NSButton *editButton;
@property (nonatomic, retain) IBOutlet NSButton *deleteButton;

@property (nonatomic, retain) IBOutlet NSTextField *nickTextField;
@property (nonatomic, retain) IBOutlet NSTextField *timeTextField;
@property (nonatomic, retain) IBOutlet NSTextField *messageTextField;
@property (nonatomic, retain) IBOutlet NSImageView *iconImageView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;

- (IBAction)replyPost:(id)sender;
- (IBAction)quotePost:(id)sender;
- (IBAction)editPost:(id)sender;
- (IBAction)deletePost:(id)sender;

@end

NS_ASSUME_NONNULL_END
