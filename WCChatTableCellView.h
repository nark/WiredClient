//
//  MessageTableCellView.h
//  Wired Client
//
//  Created by Rafael Warnault on 02/05/2020.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface WCChatTableCellView : NSTableCellView

@property (nonatomic, retain) IBOutlet NSTextField *nickTextField;
@property (nonatomic, retain) IBOutlet NSTextField *timeTextField;
@property (nonatomic, retain) IBOutlet NSTextField *messageTextField;
@property (nonatomic, retain) IBOutlet NSImageView *iconImageView;

@end

NS_ASSUME_NONNULL_END
