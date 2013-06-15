//
//  WCServerConnectionController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 23/02/13.
//
//

#import <WiredFoundation/WiredFoundation.h>

@class WCServerConnection, WCPublicChatController, WCBoardsViewController;

@interface WCServerController : WIObject {
    WCServerConnection						*_connection;
    
    WCPublicChatController                  *_chatController;
    WCBoardsViewController                  *_boardsController;
}

+ (id)serverControllerWithConnection:(WCServerConnection *)connection;

- (NSView *)viewForIdentifier:(NSString *)identifier;

- (WCPublicChatController *)chatController;
- (WCBoardsViewController *)boardsController;

- (void)setConnection:(WCServerConnection *)connection;
- (WCServerConnection *)connection;

@end
