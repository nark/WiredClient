//
//  WCBookmarkController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 26/06/13.
//
//


@interface WCBookmarkController : WISheetController {
    IBOutlet NSTextField            *_bookmarksNameTextField;
    IBOutlet NSTextField            *_bookmarksAddressTextField;
	IBOutlet NSTextField            *_bookmarksLoginTextField;
	IBOutlet NSSecureTextField      *_bookmarksPasswordTextField;
    
    NSMutableDictionary             *_bookmark;
    NSDictionary                    *_oldBookmark;
    NSString                        *_bookmarksPassword;
}

@property (nonatomic, readwrite, retain) NSMutableDictionary *bookmark;

@end
