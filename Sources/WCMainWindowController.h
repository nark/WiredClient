//
//  WCMainWindowController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 23/02/13.
//
//

#import <WiredAppKit/WiredAppKit.h>
#import <MMTabBarView/MMTabBarView.h>
#import <MMTabBarView/MMSafariTabStyle.h>

@class WCServerConnection, WCServerController, WCBoardsViewController;
@class WCServerContainer, WCServerBonjour, WCServerBookmarks;

@interface WCMainWindowController : WIWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, MMTabBarViewDelegate> {
    WCServerContainer					*_servers;
    WCServerContainer					*_trackers;
	WCServerBonjour						*_bonjour;
	WCServerBookmarks					*_bookmarks;
    
    NSMutableDictionary					*_serverControllers;
    
    NSNetServiceBrowser					*_browser;
}

@property (assign) IBOutlet NSSplitView                 *mainSplitView;
@property (assign) IBOutlet NSImageView                 *mainSplitViewImageView;
@property (assign) IBOutlet NSProgressIndicator         *progressIndicator;
@property (assign) IBOutlet NSOutlineView               *resourcesOutlineView;
@property (assign) IBOutlet NSMenu                      *resourcesOutlineMenu;
@property (assign) IBOutlet MMTabBarView                *tabBarView;
@property (assign) IBOutlet NSTabView                   *tabView;

+ (id)mainWindow;

- (NSInteger)numberOfUnreadsForConnection:(WCServerConnection *)connection;
- (WCBoardsViewController *)boardsViewControllerWithConnection:(WCServerConnection *)connection;

- (IBAction)connect:(id)sender;
- (IBAction)selectView:(id)sender;

- (void)addServerController:(WCServerController *)serverController;
- (void)selectServerController:(WCServerController *)serverController;
- (void)selectServerController:(WCServerController *)serverController firstResponder:(BOOL)firstResponder;
- (WCServerController *)selectedServerController;
- (WCServerController *)serverControllerForConnectionIdentifier:(NSString *)identifier;
- (WCServerController *)serverControllerForBookmarkIdentifier:(NSString *)identifier;
- (WCServerController *)serverControllerForURL:(WIURL *)url;
- (NSArray *)serverControllers;

@end
