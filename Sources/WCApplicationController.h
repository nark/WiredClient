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


#define WCApplicationSupportPath			@"~/Library/Application Support/Wired Client"

extern NSString * const						WCDateDidChangeNotification;
extern NSString * const						WCExceptionHandlerReceivedBacktraceNotification;
extern NSString * const						WCExceptionHandlerReceivedExceptionNotification;


@interface WCApplicationController : WIObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, GrowlApplicationBridgeDelegate> {
	IBOutlet NSMenu							*_connectionMenu;
	IBOutlet NSMenuItem						*_disconnectMenuItem;
	IBOutlet NSMenuItem						*_newDocumentMenuItem;
	IBOutlet NSMenuItem						*_deleteDocumentMenuItem;
	IBOutlet NSMenuItem						*_reloadDocumentMenuItem;
	IBOutlet NSMenuItem						*_quickLookMenuItem;
	IBOutlet NSMenuItem						*_saveDocumentMenuItem;
	IBOutlet NSMenu							*_bookmarksMenu;
    IBOutlet NSView							*_bookmarksExportView;
	IBOutlet NSMenu							*_insertSmileyMenu;
	IBOutlet NSMenu							*_debugMenu;
	IBOutlet NSMenu							*_windowMenu;
	IBOutlet NSMenuItem						*_closeWindowMenuItem;
	
	IBOutlet SUUpdater						*_updater;
	
	NSString								*_clientVersion;
	NSMutableDictionary						*_smileys;
    
    NSMutableArray                          *_availableEmoticonPacks;
    NSMutableArray                          *_enabledEmoticonPacks;
    NSMutableArray                          *_emoticons;
    NSMutableArray                          *_emoticonEquivalents;
    
	NSArray									*_sortedSmileys;
	NSUInteger								_unread;
	
	WIChatLogController						*_logController;
}

+ (WCApplicationController *)sharedController;

+ (NSString *)copiedNameForName:(NSString *)name existingNames:(NSArray *)names;
+ (NSArray *)systemSounds;

- (NSMenu *)insertSmileyMenu;

- (NSArray *)availableEmoticonPacks;
- (NSArray *)enabledEmoticonPacks;
- (NSArray *)computedEmoticonPacks;
- (NSArray *)enabledEmoticons;
- (WIEmoticon *)emoticonForPath:(NSString *)path;

- (NSURL *)applicationFilesDirectory;

- (NSString *)chatLogsPath;
- (WIChatLogController *)logController;
- (void)reloadChatLogsWithPath:(NSString *)path;

- (void)connectWithBookmark:(NSDictionary *)bookmark;

- (void)checkForUpdate;

- (IBAction)about:(id)sender;
- (IBAction)preferences:(id)sender;

- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)reconnect:(id)sender;
- (IBAction)serverInfo:(id)sender;
- (IBAction)files:(id)sender;
- (IBAction)administration:(id)sender;
- (IBAction)broadcast:(id)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)deleteDocument:(id)sender;
- (IBAction)changePassword:(id)sender;

- (IBAction)console:(id)sender;

- (IBAction)chat:(id)sender;
- (IBAction)servers:(id)sender;
- (IBAction)messages:(id)sender;
- (IBAction)boards:(id)sender;
- (IBAction)transfers:(id)sender;
- (IBAction)chatHistory:(id)sender;
- (IBAction)nextConnection:(id)sender;
- (IBAction)previousConnection:(id)sender;

- (IBAction)toggleServersList:(id)sender;
- (IBAction)toggleUserList:(id)sender;
- (IBAction)toggleTabBar:(id)sender;

- (IBAction)releaseNotes:(id)sender;
- (IBAction)crashReports:(id)sender;
- (IBAction)manual:(id)sender;
- (IBAction)support:(id)sender;

- (IBAction)exportBookmarks:(id)sender;
- (IBAction)exportTrackerBookmarks:(id)sender;
- (IBAction)importBookmarks:(id)sender;

@end
