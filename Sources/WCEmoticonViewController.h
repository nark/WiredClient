//
//  WCEmoticonViewController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 30/09/13.
//
//

#import <Cocoa/Cocoa.h>

@protocol WCEmoticonViewControllerDelegate;



@interface WCEmoticonViewController : NSViewController <NSPopoverDelegate, NSWindowDelegate> {
    IBOutlet NSArrayController  *_emoticonsArrayController;
    IBOutlet NSCollectionView   *_emoticonsCollectionView;
    IBOutlet NSWindow           *_popoverWindow;
    
    NSPopover                   *_popover;
    NSTextView                  *_textView;
    NSTextField                 *_textField;
    
    id<WCEmoticonViewControllerDelegate> _delegate;
}

@property (readwrite, retain)       id<WCEmoticonViewControllerDelegate> delegate;
@property (readonly)                NSArray *emoticons;

+ (id)emoticonController;

- (void)popoverWithSender:(id)sender textView:(NSTextView *)view;
- (void)popoverWithSender:(id)sender textField:(NSTextField *)view;

- (IBAction)emoticonClicked:(id)sender;

@end





@protocol WCEmoticonViewControllerDelegate <NSObject>
@optional
- (void)emoticonViewController:(WCEmoticonViewController *)controller
             didInsertEmoticon:(WIEmoticon *)emoticon
                     inControl:(NSControl *)control;
@end