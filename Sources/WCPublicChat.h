/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

@class WCPublicChatController, WCServerConnection;
@class WCErrorQueue, WCServerContainer, WCServerBonjour, WCServerBookmarks;
@class WCServerBookmarkController, WCTrackerBookmarkController;
@class WCTabBarView;

@interface WCPublicChat : WIWindowController <NSToolbarDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, NSMenuDelegate, NSSplitViewDelegate> {
	IBOutlet NSTabView                      *_chatTabView;
    IBOutlet WCTabBarView                   *_tabBarView;
    IBOutlet WISplitView                    *_resourcesSplitView;
    IBOutlet NSImageView                    *_splitResizeView;
    IBOutlet WIOutlineView                  *_serversOutlineView;
    IBOutlet NSTextField                    *_noConnectionTextField;
    IBOutlet NSProgressIndicator            *_progressIndicator;
    IBOutlet NSSegmentedControl             *_viewsSegmentedControl;
	IBOutlet NSMenu                         *_serversOutlineMenu;
    
    IBOutlet WCServerBookmarkController     *_serverBookmarkController;
    IBOutlet WCTrackerBookmarkController    *_trackerBookmarkController;
    
	NSMutableDictionary                     *_chatControllers;
	NSMutableDictionary                     *_chatActivity;
    
    NSNetServiceBrowser                     *_browser;
	
	WISizeFormatter                         *_sizeFormatter;
	WCErrorQueue                            *_errorQueue;
    
	WCServerContainer                       *_servers;
    WCServerContainer                       *_trackers;
	WCServerBonjour                         *_bonjour;
	WCServerBookmarks                       *_bookmarks;
}

@property (assign) IBOutlet NSSegmentedControl *viewsSegmentedControl;

+ (id)publicChat;

- (NSString *)saveDocumentMenuItemTitle;

- (NSInteger)numberOfUnreadsForConnection:(WCServerConnection *)connection;

- (IBAction)saveDocument:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)reconnect:(id)sender;
- (IBAction)serverInfo:(id)sender;
- (IBAction)files:(id)sender;
- (IBAction)administration:(id)sender;
- (IBAction)settings:(id)sender;
- (IBAction)monitor:(id)sender;
- (IBAction)log:(id)sender;
- (IBAction)accounts:(id)sender;
- (IBAction)banlist:(id)sender;
- (IBAction)console:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)nowPlaying:(id)sender;
- (IBAction)chatHistory:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)saveChat:(id)sender;
- (IBAction)setTopic:(id)sender;
- (IBAction)broadcast:(id)sender;

- (IBAction)switchViews:(id)sender;
- (IBAction)toggleServersList:(id)sender;
- (IBAction)showServerList:(id)sender;
- (IBAction)hideServerList:(id)sender;
- (IBAction)toggleUserList:(id)sender;
- (IBAction)showUserList:(id)sender;
- (IBAction)hideUserList:(id)sender;
- (IBAction)toggleTabBar:(id)sender; // unused

- (IBAction)connect:(id)sender;
- (IBAction)addServerBookmark:(id)sender;
- (IBAction)addTrackerBookmark:(id)sender;
- (IBAction)editBookmark:(id)sender;
- (IBAction)duplicateBookmark:(id)sender;
- (IBAction)deleteServerOrTrackerBookmark:(id)sender;

- (IBAction)openServer:(id)sender;
- (IBAction)addToBookmarks:(id)sender;
- (IBAction)reloadTracker:(id)sender;
- (IBAction)getTrackerServerInfo:(id)sender;

- (IBAction)addBookmark:(id)sender;

- (IBAction)nextConnection:(id)sender;
- (IBAction)previousConnection:(id)sender;

#pragma mark -
- (NSInteger)numberOfUnreads;
- (void)saveAllChatControllerHistory;

- (void)addChatController:(WCPublicChatController *)chatController;
- (void)selectChatController:(WCPublicChatController *)chatController;
- (void)selectChatController:(WCPublicChatController *)chatController firstResponder:(BOOL)firstResponder;
- (WCPublicChatController *)selectedChatController;
- (WCPublicChatController *)chatControllerForConnectionIdentifier:(NSString *)identifier;
- (WCPublicChatController *)chatControllerForBookmarkIdentifier:(NSString *)identifier;
- (WCPublicChatController *)chatControllerForURL:(WIURL *)url;
- (NSArray *)chatControllers;

@end
