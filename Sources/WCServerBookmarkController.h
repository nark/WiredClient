//
//  WCServerBookmarkController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 25/06/13.
//
//

#import "WCBookmarkController.h"

@interface WCServerBookmarkController : WCBookmarkController {
	IBOutlet NSPopUpButton          *_bookmarksThemePopUpButton;
	IBOutlet NSButton               *_bookmarksAutoConnectButton;
	IBOutlet NSButton               *_bookmarksAutoReconnectButton;
	IBOutlet NSTextField            *_bookmarksNickTextField;
	IBOutlet NSTextField            *_bookmarksStatusTextField;
}

@end
