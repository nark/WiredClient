//
//  WCEmoticonViewController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 30/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface WCEmoticonViewController : NSViewController <NSPopoverDelegate> {
    IBOutlet NSArrayController  *_emoticonsArrayController;
    IBOutlet NSCollectionView   *_emoticonsCollectionView;
    
    NSPopover                   *_popover;
    NSTextView                  *_textView;
    NSTextField                 *_textField;
}


@property (readonly) NSArray *emoticons;

+ (id)emoticonController;

- (void)popoverWithSender:(id)sender textView:(NSTextView *)view;
- (void)popoverWithSender:(id)sender textField:(NSTextField *)view;

- (IBAction)emoticonClicked:(id)sender;

@end
