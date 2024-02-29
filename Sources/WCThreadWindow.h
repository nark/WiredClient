//
//  WCThreadWindow.h
//  WiredClient
//
//  Created by nark on 21/10/13.
//
//

#import <WiredAppKit/WiredAppKit.h>

@class WCBoardThreadController, WCBoardThread, WCBoard;

@interface WCThreadWindow : WIWindowController <NSWindowDelegate> {
    WCBoardThreadController             *_threadController;
    WCBoard                             *_board;
    WCBoardThread                       *_thread;
}

+ (WCThreadWindow *)threadWindowWithThread:(WCBoardThread *)thread board:(WCBoard *)board;
+ (NSArray *)threadWindows;

- (WCBoardThread *)thread;
- (WCBoardThreadController *)threadController;

@end
