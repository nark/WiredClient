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

//#import <Sparkle/SUStandardVersionComparator.h>
//#import <Sparkle/SUHost.h>

#import "WCAccountsController.h"
#import "WCAdministration.h"
#import "WCApplicationController.h"
#import "WCBanlistController.h"
#import "WCDatabaseController.h"
#import "WCBoards.h"
#import "WCConnect.h"
#import "WCConsole.h"
#import "WCFiles.h"
#import "WCFile.h"
#import "WCKeychain.h"
#import "WCMessage.h"
#import "WCMessages.h"
#import "WCPreferences.h"
#import "WCPublicChat.h"
#import "WCPublicChatController.h"
#import "WCServerConnection.h"
#import "WCStats.h"
#import "WCTransfers.h"
#import "WCChatHistory.h"
#import "WCUser.h"


#define WCGrowlServerConnected										@"Connected to server"
#define WCGrowlServerDisconnected									@"Disconnected from server"
#define WCGrowlError												@"Error"
#define WCGrowlUserJoined											@"User joined"
#define WCGrowlUserChangedNick										@"User changed nick"
#define WCGrowlUserChangedStatus									@"User changed status"
#define WCGrowlUserLeft												@"User left"
#define WCGrowlChatReceived											@"Chat received"
#define WCGrowlHighlightedChatReceived								@"Highlighted chat received"
#define WCGrowlChatInvitationReceived								@"Private chat invitation received"
#define WCGrowlMessageReceived										@"Message received"
#define WCGrowlBoardPostReceived									@"Board post added"
#define WCGrowlBroadcastReceived									@"Broadcast received"
#define WCGrowlTransferStarted										@"Transfer started"
#define WCGrowlTransferFinished										@"Transfer finished"


NSString * const WCDateDidChangeNotification						= @"WCDateDidChangeNotification";
NSString * const WCExceptionHandlerReceivedBacktraceNotification	= @"WCExceptionHandlerReceivedBacktraceNotification";
NSString * const WCExceptionHandlerReceivedExceptionNotification	= @"WCExceptionHandlerReceivedExceptionNotification";

/*
static NSInteger _WCCompareSmileyLength(id, id, void *);

static NSInteger _WCCompareSmileyLength(id object1, id object2, void *context) {
	NSUInteger	length1 = [(NSString *) object1 length];
	NSUInteger	length2 = [(NSString *) object2 length];
	
	if(length1 > length2)
		return -1;
	else if(length1 < length2)
		return 1;
	
	return 0;
}
*/

static NSArray *_systemSounds;


@interface WCApplicationController(Private)

- (void)_update;
- (void)_updateApplicationIcon;
- (void)_updateBookmarksMenu;

- (void)_reloadChatLogsControllerWithPath:(NSString *)path;

- (void)_connectWithBookmark:(NSDictionary *)bookmark;
- (BOOL)_openConnectionWithURL:(WIURL *)url;

- (void)_userNotificationWithNotification:(NSNotification *)notification;
- (void)_handleGrowlNotificationWithUserInfo:(NSDictionary *)userInfo;
- (void)_handleUserNotification:(NSUserNotification *)userNotification;

@end


@implementation WCApplicationController(Private)

#pragma mark -

- (void)_update {
	if([[WCSettings settings] boolForKey:WCConfirmDisconnect])
		[_disconnectMenuItem setTitle:NSLS(@"Disconnect\u2026", @"Disconnect menu item")];
	else
		[_disconnectMenuItem setTitle:NSLS(@"Disconnect", @"Disconnect menu item")];
	
	[_updater setAutomaticallyChecksForUpdates:[[WCSettings settings] boolForKey:WCCheckForUpdate]];
}



- (void)_updateApplicationIcon {
    if(_unread > 0)
        [[NSApp dockTile] setBadgeLabel:[NSSWF:@"%ld", (unsigned long)_unread]];
    else
        [[NSApp dockTile] setBadgeLabel:nil];
}



- (void)_updateBookmarksMenu {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
	NSEnumerator	*enumerator;
	NSArray			*bookmarks;
	NSDictionary	*bookmark;
	NSMenuItem		*item;
	NSUInteger		i = 1;
        
	while((item = (NSMenuItem *) [_bookmarksMenu itemWithTag:0]))
		[_bookmarksMenu removeItem:item];

	bookmarks = [[WCSettings settings] objectForKey:WCBookmarks];

	if([bookmarks count] > 0)
		[_bookmarksMenu addItem:[NSMenuItem separatorItem]];

	enumerator = [bookmarks objectEnumerator];

	while((bookmark = [enumerator nextObject])) {
		item = [NSMenuItem itemWithTitle:[bookmark objectForKey:WCBookmarksName] action:@selector(bookmark:)];
		[item setTarget:self];
		[item setRepresentedObject:bookmark];
		
		if(i <= 10) {
			[item setKeyEquivalent:[NSSWF:@"%lu", (i == 10) ? 0 : i]];
			[item setKeyEquivalentModifierMask:NSCommandKeyMask];
		}
		else if(i <= 20) {
			[item setKeyEquivalent:[NSSWF:@"%lu", (i == 20) ? 0 : i - 10]];
			[item setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
		}
		else if(i <= 30) {
			[item setKeyEquivalent:[NSSWF:@"%lu", (i == 30) ? 0 : i - 20]];
			[item setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
		}

		[_bookmarksMenu addItem:item];

		i++;
	}
    
    [_bookmarksMenu addItem:[NSMenuItem separatorItem]];
    
    [_bookmarksMenu addItem:[NSMenuItem itemWithTitle:NSLS(@"Export Server Bookmarks...", @"Bookmarks menu item title")
                                               action:@selector(exportBookmarks:)
                                        keyEquivalent:@""]];

    [_bookmarksMenu addItem:[NSMenuItem itemWithTitle:NSLS(@"Export Tracker Bookmarks...", @"Bookmarks menu item title")
                                               action:@selector(exportTrackerBookmarks:)
                                        keyEquivalent:@""]];
    
    [_bookmarksMenu addItem:[NSMenuItem itemWithTitle:NSLS(@"Import Bookmarks...", @"Bookmarks menu item title")
                                               action:@selector(importBookmarks:)
                                        keyEquivalent:@""]];
    #pragma clang diagnostic pop
}



#pragma mark -

- (void)_connectWithBookmark:(NSDictionary *)bookmark {
	NSString			*address, *login, *password;
	WCConnect			*connect;
	WIURL				*url;

	address		= [bookmark objectForKey:WCBookmarksAddress];
	login		= [bookmark objectForKey:WCBookmarksLogin];
	password	= [[WCKeychain keychain] passwordForBookmark:bookmark];

	url = [WIURL URLWithString:address scheme:@"wiredp7"];
	[url setUser:login];
	[url setPassword:password ? password : @""];
	
	if(![self _openConnectionWithURL:url]) {
		connect = [WCConnect connectWithURL:url bookmark:bookmark];
		[connect showWindow:self];
		[connect connect:self];
	}
}


- (void)_connectWithURL:(WIURL *)url bookmark:(NSDictionary *)bookmark {
	NSString			*login, *password;
	WCConnect			*connect;
    
	login		= [bookmark objectForKey:WCBookmarksLogin];
	password	= [[WCKeychain keychain] passwordForBookmark:bookmark];

    [url setUser:login];
	[url setPassword:password ? password : @""];
	
	if(![self _openConnectionWithURL:url]) {
		connect = [WCConnect connectWithURL:url bookmark:bookmark];
		[connect showWindow:self];
		[connect connect:self];
	}
}


- (BOOL)_openConnectionWithURL:(WIURL *)url {
	NSEnumerator            *enumerator;
	WCPublicChatController	*chatController;
    WIURL                   *connectionURL;
    
	enumerator  = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	    
	while((chatController = [enumerator nextObject])) {
        connectionURL = [[chatController connection] URL];
        
		if([[url host] isEqual:[connectionURL host]] &&
           [[url user] isEqual:[connectionURL user]] &&
           [url port] == [connectionURL port]) {
            
			[[WCPublicChat publicChat] selectChatController:chatController];
			[[WCPublicChat publicChat] showWindow:self];
            
            // try to download the file if Wired URL has a path extention
            if([url pathExtension]) {
                [WCTransfers downloadFileAtPath:[url path] forConnection:[chatController connection]];
            }
			
			return YES;
		}
	}
	
	return NO;
}



#pragma mark -

- (void)_reloadChatLogsControllerWithPath:(NSString *)path {
	NSString		*newPath;
	NSFileManager	*fileManager;
	NSError			*error;
	
	/* We are in a background thread */
	
	fileManager = [NSFileManager defaultManager];
	
	// move old chat history if needed
	if([fileManager fileExistsAtPath:[_logController publicHistoryBundlePath]]) {
		newPath	= [path stringByAppendingPathComponent:[[_logController publicHistoryBundlePath] lastPathComponent]];
		[fileManager copyItemAtPath:[_logController publicHistoryBundlePath] 
							 toPath:newPath 
							  error:&error];
	}
	
	if([fileManager fileExistsAtPath:[_logController privateHistoryBundlePath]]) {
		newPath	= [path stringByAppendingPathComponent:[[_logController privateHistoryBundlePath] lastPathComponent]];
		[fileManager copyItemAtPath:[_logController privateHistoryBundlePath] 
							 toPath:newPath 
							  error:&error];
	}
	
	// move old chat logs if needed
	if([fileManager fileExistsAtPath:[_logController chatLogsPath]]) {
		newPath	= [path stringByAppendingPathComponent:[[_logController chatLogsPath] lastPathComponent]];
		[fileManager copyItemAtPath:[_logController chatLogsPath] 
							 toPath:newPath 
							  error:&error];
	}
	

    if(_logController) {
        [_logController release];
        _logController = nil;
    }
    
    _logController = [[WIChatLogController alloc] initWithPath:path];
}



#pragma mark -

- (void)_userNotificationWithNotification:(NSNotification *)notification {
    NSUserNotificationCenter    *center;
    NSUserNotification          *note;
    NSDictionary                *event, *userInfo;
    WCServerConnection          *connection;
    id                          info1, info2;
    
    center      = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];
    
    event		= [notification object];
	connection	= [[notification userInfo] objectForKey:WCServerConnectionEventConnectionKey];
	info1		= [[notification userInfo] objectForKey:WCServerConnectionEventInfo1Key];
	info2		= [[notification userInfo] objectForKey:WCServerConnectionEventInfo2Key];
    
    if(![event boolForKey:WCEventsNotificationCenter])
        return;
    
    note        = [[NSUserNotification alloc] init];
    
    if([info2 isKindOfClass:[WCUser class]]) {
        userInfo = @{ @"event":             event,
                      @"identifier":        [connection identifier],
                      @"userID":            [NSNumber numberWithInteger:[(WCUser *)info2 userID]] };
    }
    else {
        userInfo = @{ @"event":             event,
                      @"identifier":        [connection identifier] };
    }
    
    [note setUserInfo:userInfo];
    
    switch([event intForKey:WCEventsEvent]) {
		case WCEventsServerConnected:
            [note setTitle:NSLS(@"Connected", @"Growl event connected title")];
            [note setInformativeText:[NSSWF:NSLS(@"Connected to %@", @"Growl event connected description (server)"), [connection name]]];
			break;
            
		case WCEventsServerDisconnected:
            [note setTitle:NSLS(@"Disconnected", @"Growl event disconnected title")];
            [note setInformativeText:[NSSWF:NSLS(@"Disconnected from %@", @"Growl event disconnected description (server)"), [connection name]]];
			break;
            
		case WCEventsError:
            [note setTitle:[info1 localizedDescription]];
            [note setInformativeText:[info1 localizedFailureReason]];
			break;
            
		case WCEventsUserJoined:
            [note setTitle:NSLS(@"User joined", @"Growl event user joined title")];
            [note setInformativeText:[info1 nick]];
			break;
            
		case WCEventsUserChangedNick:
            [note setTitle:NSLS(@"User changed nick", @"Growl event user changed nick title")];
            [note setInformativeText:[NSSWF:NSLS(@"%@ is now known as %@", @"Growl event user changed nick description (oldnick, newnick)"), [info1 nick], info2]];
			break;
            
		case WCEventsUserChangedStatus:
            [note setTitle:NSLS(@"User changed status", @"Growl event user changed status title")];
            [note setInformativeText:[NSSWF:NSLS(@"%@ changed status to %@", @"Growl event user changed status description (nick, status)"), [info1 nick], info2]];
			break;
            
		case WCEventsUserLeft:
            [note setTitle:NSLS(@"User left", @"Growl event user left title")];
            [note setInformativeText:[info1 nick]];
			break;
            
		case WCEventsChatReceived:
            note.hasReplyButton = YES;
            
            [note setTitle:NSLS(@"Chat received", @"Growl event chat received title")];
            [note setInformativeText:[NSSWF:@"%@: %@", [info1 nick], info2]];
			break;
            
		case WCEventsHighlightedChatReceived:
            [note setTitle:NSLS(@"Chat received", @"Growl event chat received title")];
            [note setInformativeText:[NSSWF:@"%@: %@", [info1 nick], info2]];            
			break;
            
		case WCEventsChatInvitationReceived:
            [note setTitle:NSLS(@"Private chat invitation received", @"Growl event private chat invitation received title")];
            [note setInformativeText:[info1 nick]];
			break;
            
		case WCEventsMessageReceived:
            note.hasReplyButton = YES;
            [note setTitle:NSLS(@"Message received", @"Growl event message received title")];
            [note setInformativeText:[NSSWF:@"%@: %@", [info1 nick], [info1 valueForKey:@"messageString"]]];
			break;
            
		case WCEventsBoardPostReceived:
            [note setTitle:NSLS(@"Board post received", @"Growl event news posted title")];
            [note setInformativeText:[NSSWF:@"%@: %@", info1, info2]];
			break;
            
		case WCEventsBroadcastReceived:
            [note setTitle:NSLS(@"Broadcast received", @"Growl event broadcast received title")];
            [note setInformativeText:[NSSWF:@"%@: %@", [info1 nick], [info1 message]]];
			break;
            
		case WCEventsTransferStarted:
            [note setTitle:NSLS(@"Transfer started", @"Growl event transfer started title")];
            [note setInformativeText:[info1 name]];
			break;
            
		case WCEventsTransferFinished:
            [note setTitle:NSLS(@"Transfer finished", @"Growl event transfer started title")];
            [note setInformativeText:[info1 name]];
			break;
	}

    [center deliverNotification:note];
    [note release];
}


- (void)_handleGrowlNotificationWithUserInfo:(NSDictionary *)userInfo {
    NSDictionary            *event;
	NSEnumerator			*enumerator;
	WCPublicChatController	*chatController;
	
	[NSApp activateIgnoringOtherApps:YES];
	
	enumerator  = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	
	while((chatController = [enumerator nextObject])) {
		if([[userInfo valueForKey:@"identifier"] isEqualToString:[[chatController connection] identifier]]) {
            event = [userInfo valueForKey:@"event"];
            
            if([event intForKey:WCEventsEvent] == WCEventsServerConnected ||
               [event intForKey:WCEventsEvent] == WCEventsServerDisconnected ||
               [event intForKey:WCEventsEvent] == WCEventsError ||
               [event intForKey:WCEventsEvent] == WCEventsUserJoined ||
               [event intForKey:WCEventsEvent] == WCEventsUserChangedNick ||
               [event intForKey:WCEventsEvent] == WCEventsUserChangedStatus ||
               [event intForKey:WCEventsEvent] == WCEventsUserLeft ||
               [event intForKey:WCEventsEvent] == WCEventsChatReceived ||
               [event intForKey:WCEventsEvent] == WCEventsHighlightedChatReceived ||
               [event intForKey:WCEventsEvent] == WCEventsChatInvitationReceived) {
                
                [[WCPublicChat publicChat] selectChatController:chatController];
                [[WCPublicChat publicChat] showWindow:self];
            }
            else if([event intForKey:WCEventsEvent] == WCEventsMessageReceived) {
                WCUser *user = [userInfo objectForKey:WCServerConnectionEventInfo1Key];
                
                [[WCMessages messages] showWindow:self];
                
                if(user)
                    [[WCMessages messages] showPrivateMessageToUser:user];
                
            } else if ([event intForKey:WCEventsEvent] == WCEventsBroadcastReceived) {
                [[WCMessages messages] showWindow:self];
                [[WCMessages messages] showBroadcastForConnection:[chatController connection]];
            }
            else if([event intForKey:WCEventsEvent] == WCEventsBoardPostReceived) {
                [[WCBoards boards] showWindow:self];
                
            }
            else if([event intForKey:WCEventsEvent] == WCEventsTransferStarted ||
                    [event intForKey:WCEventsEvent] == WCEventsTransferFinished) {
                [[WCTransfers transfers] showWindow:self];
            }
            else {
                [[WCPublicChat publicChat] selectChatController:chatController];
                [[WCPublicChat publicChat] showWindow:self];
            }
		}
	}
}


- (void)_handleUserNotification:(NSUserNotification *)userNotification {
    NSDictionary            *userInfo, *event;
	NSEnumerator			*enumerator;
    NSString                *string;
    NSInteger               userID;
	WCPublicChatController	*chatController;
    WCUser                  *user;
	
	[NSApp activateIgnoringOtherApps:NO];
	
    userInfo    = [userNotification userInfo];
	enumerator  = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	
	while((chatController = [enumerator nextObject])) {
		if([[userInfo valueForKey:@"identifier"] isEqualToString:[[chatController connection] identifier]]) {
            event   = [userInfo valueForKey:@"event"];
            string = [[userNotification response] string];
            
            if([event intForKey:WCEventsEvent] == WCEventsChatReceived) {
                [chatController sendChat:string];
            }
            else if([event intForKey:WCEventsEvent] == WCEventsMessageReceived) {
                userID  = [userInfo integerForKey:@"userID"];
                user    = [chatController userWithUserID:userID];
                
                if(user)
                    [[WCMessages messages] sendMessage:string toUser:user];
            }
        }
    }
}

@end





@implementation WCApplicationController

static WCApplicationController		*sharedController;


+ (WCApplicationController *)sharedController {
	return sharedController;
}



#pragma mark -

+ (NSString *)copiedNameForName:(NSString *)name existingNames:(NSArray *)names {
	NSMutableString		*copiedName;
	NSString			*string, *copy;
	NSUInteger			number;
	
	copy = NSLS(@"Copy", @"Account copy");
	
	if([name containsSubstring:[NSSWF:@" %@", copy]]) {
		string			= [name stringByMatching:[NSSWF:@"(\\d+)$"] capture:1];
		number			= string ? [string unsignedIntegerValue] + 1 : 2;
		copiedName		= [[name mutableCopy] autorelease];
	} else {
		number			= 2;
		copiedName		= [NSMutableString stringWithFormat:@"%@ %@", name, copy];
	}
	
	while([names containsObject:copiedName]) {
		if([copiedName replaceOccurrencesOfRegex:@"(\\d+)$" withString:[NSSWF:@"%lu", (unsigned long)number]] == 0)
			[copiedName appendFormat:@" %lu", (unsigned long)number];
		
		number++;
	}
	
	return copiedName;
}


+ (NSArray *)systemSounds
{
    if ( !_systemSounds )
    {
        NSMutableArray *returnArr = [[NSMutableArray alloc] init];
        NSEnumerator *librarySources = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES) objectEnumerator];
        NSString *sourcePath;
        
        while ( sourcePath = [librarySources nextObject] )
        {
            NSEnumerator *soundSource = [[NSFileManager defaultManager] enumeratorAtPath: [sourcePath stringByAppendingPathComponent: @"Sounds"]];
            NSString *soundFile;
            while ( soundFile = [soundSource nextObject] )
                if ( [NSSound soundNamed: [soundFile stringByDeletingPathExtension]] )
                    [returnArr addObject: [soundFile stringByDeletingPathExtension]];
        }
        
        _systemSounds = [[NSArray alloc] initWithArray: [returnArr sortedArrayUsingSelector:@selector(compare:)]];
        [returnArr release];
    }
    return _systemSounds;
}







#pragma mark -

- (id)init {
	NSTimer		*timer;
	NSDate		*date;
	
	sharedController = self = [super init];
    
    _dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];

#ifndef WCConfigurationRelease
	[[WIExceptionHandler sharedExceptionHandler] enable];
	[[WIExceptionHandler sharedExceptionHandler] setDelegate:self];
#endif
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(preferencesDidChange:)
			   name:WCPreferencesDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(bookmarksDidChange:)
			   name:WCBookmarksDidChangeNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionWillConnect:)
			   name:WCLinkConnectionWillConnectNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(boardsDidChangeUnreadCount:)
			   name:WCBoardsDidChangeUnreadCountNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		  selector:@selector(messagesDidChangeUnreadCount:)
			   name:WCMessagesDidChangeUnreadCountNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(serverConnectionTriggeredEvent:)
			   name:WCServerConnectionTriggeredEventNotification];
	
	[[NSAppleEventManager sharedAppleEventManager]
		setEventHandler:self
			andSelector:@selector(handleAppleEvent:withReplyEvent:)
		  forEventClass:kInternetEventClass
			 andEventID:kAEGetURL];
	
	[[NSFileManager defaultManager] createDirectoryAtPath:[WCApplicationSupportPath stringByStandardizingPath]];
	
	date = [[NSDate dateAtStartOfCurrentDay] dateByAddingDays:1];
	timer = [[NSTimer alloc] initWithFireDate:date
									 interval:86400.0
									   target:self
									 selector:@selector(dailyTimer:)
									 userInfo:NULL
									  repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[timer release];
	
	signal(SIGPIPE, SIG_IGN);

	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_clientVersion release];
	[_logController release];
    [_dateFormatter release];

	[super dealloc];
}



#pragma mark -

- (void)awakeFromNib {
	NSEnumerator		*enumerator;
	NSDictionary		*bookmark;
	NSString			*path;
	WIError				*error;
	
    // remove the Console menu in Release mode
#ifdef WCConfigurationRelease
	if(![[WCSettings settings] boolForKey:WCDebug])
		[[NSApp mainMenu] removeItemAtIndex:[[NSApp mainMenu] indexOfItemWithSubmenu:_debugMenu]];
#endif
    
	[WIDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	[NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
    
    // set the auto-update feed URL regarding to the selected configuration (Debug or Release)
#ifdef WCConfigurationRelease
    [_updater setFeedURL:[NSURL URLWithString:@"http://wired.read-write.fr/xml/sparkle.php?file=wiredclientcast"]];
#else
    [_updater setFeedURL:[NSURL URLWithString:@"http://wired.read-write.fr/xml/sparkle.php?file=wiredclient_debugcast"]];
#endif
    
	[_updater setSendsSystemProfile:YES];
    [_updater performSelector:@selector(checkForUpdatesInBackground) afterDelay:5.0f];
	
	path = [[NSBundle mainBundle] pathForResource:@"wired" ofType:@"xml"];
	
    // verify the P7 specification in debug mode
#ifdef WCConfigurationDebug
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"WebKitDeveloperExtras"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//	if([[NSFileManager defaultManager] fileExistsAtPath:@"p7-specification.xsd"]) {
//		if(![[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] options:NSXMLDocumentValidate error:(NSError **) &error] autorelease]) {
//			[[error alert] runModal];
//			
//			[NSApp terminate:self];
//		}
//	}
#endif
	
    // init and load the Wired 2.0 P7 Specification
	WCP7Spec = [[WIP7Spec alloc] initWithPath:path originator:WIP7Client error:&error];
	if(!WCP7Spec) {
		[[error alert] runModal];
		
		[NSApp terminate:self];
	}


	[self _update];
	[self _updateBookmarksMenu];
    //[self _reloadEmoticons];
	[self _reloadChatLogsControllerWithPath:[self chatLogsPath]];

    if([[WCSettings settings] boolForKey:WCShowChatWindowAtStartup])
		[[WCPublicChat publicChat] showWindow:self];

	if([[WCSettings settings] boolForKey:WCShowConnectAtStartup])
		[[WCConnect connect] showWindow:self];
	
	if((GetCurrentKeyModifiers() & optionKey) == 0) {
		enumerator = [[[WCSettings settings] objectForKey:WCBookmarks] objectEnumerator];

		while((bookmark = [enumerator nextObject])) {
			if([[bookmark objectForKey:WCBookmarksAutoConnect] boolValue])
				[self _connectWithBookmark:bookmark];
		}
	}
}



#pragma mark -

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)application {
    NSApplicationTerminateReply reply;
	NSEnumerator                *enumerator;
	WCPublicChatController      *chatController;
	NSUInteger                  count;
	
    reply = NSTerminateNow;
	enumerator = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	count = 0;
	
	while((chatController = [enumerator nextObject])) {
		if([[chatController connection] isConnected])
			count++;
	}
	
	if([[WCSettings settings] boolForKey:WCConfirmDisconnect] && count > 0)
		reply = [(WIApplication *) NSApp runTerminationDelayPanelWithTimeInterval:30.0];
    
	return reply;
}



- (void)applicationWillTerminate:(NSNotification *)notification {
	_unread = 0;
	
	[[WCPublicChat publicChat] saveAllChatControllerHistory];

	[self _updateApplicationIcon];
}



- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename {
	NSString		*extension;
	
	extension = [filename pathExtension];
	
	if([extension isEqualToString:@"WiredTheme"])
		return [[WCPreferences preferences] importThemeFromFile:filename];
    else if([extension isEqualToString:@"WiredTemplate"])
		return [[WCPreferences preferences] importTemplateFromFile:filename];
	else if([extension isEqualToString:@"WiredBookmarks"])
		return [[WCPreferences preferences] importBookmarksFromFile:filename];
	else if([extension isEqualToString:@"WiredTrackerBookmarks"])
		return [[WCPreferences preferences] importTrackerBookmarksFromFile:filename];
	else if([extension isEqualToString:@"WiredTransfer"])
		return [[WCTransfers transfers] addTransferAtPath:filename];
	
	return NO;
}


- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    [[WCPublicChat publicChat] showWindow:self];
    return NO;
}



- (void)menuNeedsUpdate:(NSMenu *)menu {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
	NSString		*newString, *deleteString, *reloadString, *quickLookString, *saveString;
	id				delegate;
	
	if(menu == _connectionMenu) {
		delegate = [[NSApp keyWindow] delegate];
		
		if([delegate respondsToSelector:@selector(newDocumentMenuItemTitle)])
			newString = [delegate newDocumentMenuItemTitle];
		else
			newString = NULL;
		
		if([delegate respondsToSelector:@selector(deleteDocumentMenuItemTitle)])
			deleteString = [delegate deleteDocumentMenuItemTitle];
		else
			deleteString = NULL;
		
		if([delegate respondsToSelector:@selector(reloadDocumentMenuItemTitle)])
			reloadString = [delegate reloadDocumentMenuItemTitle];
		else
			reloadString = NULL;
		
		if([delegate respondsToSelector:@selector(quickLookMenuItemTitle)])
			quickLookString = [delegate quickLookMenuItemTitle];
		else
			quickLookString = NULL;
		
		if([delegate respondsToSelector:@selector(saveDocumentMenuItemTitle)])
			saveString = [delegate saveDocumentMenuItemTitle];
		else
			saveString = NULL;
		
		[_newDocumentMenuItem setTitle:newString ? newString : NSLS(@"New Thread", @"New menu item")];
		[_deleteDocumentMenuItem setTitle:deleteString ? deleteString : NSLS(@"Delete", @"Delete menu item")];
		[_reloadDocumentMenuItem setTitle:reloadString ? reloadString : NSLS(@"Reload", @"Reload menu item")];
		[_quickLookMenuItem setTitle:quickLookString ? quickLookString : NSLS(@"Quick Look", @"Quick Look menu item")];
		[_saveDocumentMenuItem setTitle:saveString ? saveString : NSLS(@"Save", @"Save menu item")];
	}
	else if(menu == _windowMenu) {
		if([NSApp keyWindow] == [[WCPublicChat publicChat] window] && [[WCPublicChat publicChat] selectedChatController] != NULL) {
			[_closeWindowMenuItem setAction:@selector(closeTab:)];
			[_closeWindowMenuItem setTitle:NSLS(@"Close Tab", @"Close tab menu item")];
		} else {
			[_closeWindowMenuItem setAction:@selector(performClose:)];
			[_closeWindowMenuItem setTitle:NSLS(@"Close Window", @"Close window menu item")];
		}
	}
#pragma clang diagnostic pop
    
}



- (void)preferencesDidChange:(NSNotification *)notification {
	[self _update];
}




- (void)bookmarksDidChange:(NSNotification *)notification {
	[self _updateBookmarksMenu];
}



- (void)linkConnectionWillConnect:(NSNotification *)notification {
	[WCStats stats];
	[WCTransfers transfers];
	[WCMessages messages];
	[WCBoards boards];
}



- (void)messagesDidChangeUnreadCount:(NSNotification *)notification {
	_unread = [[WCMessages messages] numberOfUnreadMessages] + [[WCBoards boards] numberOfUnreadThreads];
	
	[self performSelector:@selector(_updateApplicationIcon) withObject:NULL afterDelay:0.0];
}



- (void)boardsDidChangeUnreadCount:(NSNotification *)notification {
	_unread = [[WCMessages messages] numberOfUnreadMessages] + [[WCBoards boards] numberOfUnreadThreads];
	
	[self performSelector:@selector(_updateApplicationIcon) withObject:NULL afterDelay:0.0];
}



- (void)serverConnectionTriggeredEvent:(NSNotification *)notification {
        
	NSDictionary			*event, *userInfo;
	NSString				*sound;
	WCServerConnection		*connection;
	id						info1, info2;
	
	event		= [notification object];
	connection	= [[notification userInfo] objectForKey:WCServerConnectionEventConnectionKey];
	info1		= [[notification userInfo] objectForKey:WCServerConnectionEventInfo1Key];
	info2		= [[notification userInfo] objectForKey:WCServerConnectionEventInfo2Key];
    
    userInfo    = [NSDictionary dictionaryWithObjectsAndKeys:event,  @"event",
                                            [connection identifier], @"identifier", nil];
	
	if([event boolForKey:WCEventsPlaySound]) {
		sound = [event objectForKey:WCEventsSound];
		
		if(sound)
			[NSSound playSoundNamed:sound atVolume:[[WCSettings settings] floatForKey:WCEventsVolume]];
	}
	
	if([event boolForKey:WCEventsBounceInDock])
		[NSApp requestUserAttention:NSInformationalRequest];
    
    if ([NSUserNotification class] && [NSUserNotificationCenter class]) {
        [self _userNotificationWithNotification:notification];
    }
}



#pragma mark -

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSDictionary	*bookmark;
	NSString		*string;
	WIURL			*url;
	WCConnect		*connect;
	
	string = [[event descriptorForKeyword:keyDirectObject] stringValue];
    
    while([string characterAtIndex:[string length] - 1] == '/')
        string = [string stringByReplacingCharactersInRange:NSMakeRange([string length] - 1, 1)
                                                 withString:@""];
    
	url = [WIURL URLWithString:string];
	
	if([[url scheme] isEqualToString:@"wired"]) {
		if([[url host] length] > 0) {
			[[NSWorkspace sharedWorkspace] openURL:[url URL]];
		}
	}
    else if([[url scheme] isEqualToString:@"wiredp7"]) {
		if([[url host] length] > 0) {
			if(![self _openConnectionWithURL:url]) {
                bookmark    = [[WCSettings settings] bookmarkForURL:url];
                
                if(bookmark) {
                    [self _connectWithURL:url bookmark:bookmark];
                    
                } else {
                    connect     = [WCConnect connectWithURL:url bookmark:bookmark];
                    [connect showWindow:self];
                    [connect connect:self];
                }
			}
		}
	}
	else if([[url scheme] isEqualToString:@"wiredtracker"]) {
		bookmark = [NSDictionary dictionaryWithObjectsAndKeys:
					[url host],					WCTrackerBookmarksName,
					[url hostpair],				WCTrackerBookmarksAddress,
					@"",						WCTrackerBookmarksLogin,
					[NSString UUIDString],		WCTrackerBookmarksIdentifier,
					NULL];
		
		[[WCSettings settings] addObject:bookmark toArrayForKey:WCTrackerBookmarks];
		
        [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification
                                                            object:bookmark
                                                          userInfo:bookmark];
	}
}



- (void)exceptionHandler:(WIExceptionHandler *)exceptionHandler receivedException:(NSException *)exception withBacktrace:(NSString *)backtrace {
	NSAlert		*alert;
	
	if(backtrace)
		[[NSNotificationCenter defaultCenter] postNotificationName:WCExceptionHandlerReceivedBacktraceNotification object:backtrace];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:WCExceptionHandlerReceivedExceptionNotification object:exception];
	
	alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLS(@"Internal Client Error", @"Internal error dialog title")];
	[alert setInformativeText:NSLS(@"Wired Client has encountered an exception. More information has been logged to the console.", @"Internal error dialog description")];
	[alert runModal];
	[alert release];
}





#pragma mark -

- (NSDictionary *)registrationDictionaryForGrowl {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArray arrayWithObjects:
			WCGrowlServerConnected,
			WCGrowlServerDisconnected,
			WCGrowlError,
			WCGrowlUserJoined,
			WCGrowlUserChangedNick,
			WCGrowlUserChangedStatus,
			WCGrowlUserLeft,
			WCGrowlChatReceived,
			WCGrowlHighlightedChatReceived,
			WCGrowlChatInvitationReceived,
			WCGrowlMessageReceived,
			WCGrowlBroadcastReceived,
			WCGrowlBoardPostReceived,
			WCGrowlTransferStarted,
			WCGrowlTransferFinished,
			NULL],
			"",
		[NSArray arrayWithObjects:
			WCGrowlServerDisconnected,
			WCGrowlHighlightedChatReceived,
			WCGrowlMessageReceived,
			WCGrowlBroadcastReceived,
			WCGrowlBoardPostReceived,
			WCGrowlTransferFinished,
			NULL],
			"",
		NULL];
}



- (void)growlNotificationWasClicked:(id)clickContext {
    [self _handleGrowlNotificationWithUserInfo:clickContext];
}





#pragma mark -

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    if(notification.activationType == NSUserNotificationActivationTypeReplied) {
        [self _handleUserNotification:notification];
    }
    else if(notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
        [self _handleGrowlNotificationWithUserInfo:[notification userInfo]];
    }
}






#pragma mark -


- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
	return NO;
}


- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile {
    NSMutableArray *params;
    
    params = [NSMutableArray array];
    
    [params addObject: @{
       @"key":          @"debug",
#ifdef WCConfigurationRelease
       @"value":        @"false"
#else
       @"value":        @"true"
#endif
    }];
    
    [params addObject: @{
       @"key":          @"appShortVersion",
       @"value":        [[[NSApp bundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"],
    }];
    
    return params;
}





#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;

	selector = [item action];
	
	if(selector == @selector(disconnect:) || selector == @selector(reconnect:) ||
	   selector == @selector(serverInfo:) || selector == @selector(files:) ||
	   selector == @selector(administration:) || selector == @selector(broadcast:) ||
	   selector == @selector(changePassword:) || selector == @selector(addBookmark:) ||
	   selector == @selector(console:) || selector == @selector(nextConnection:) ||
	   selector == @selector(previousConnection:) || selector == @selector(toggleUserList:)) {
		return [[WCPublicChat publicChat] validateMenuItem:item];
	}
	else if(selector == @selector(newDocument:) || selector == @selector(deleteDocument:)) {
		return [[WCBoards boards] validateMenuItem:item];
	}
	else if(selector == @selector(insertSmiley:)) {
		return ([[[NSApp keyWindow] firstResponder] respondsToSelector:@selector(insertText:)]);
	}
    else if(selector == @selector(exportBookmarks:)) {
        return ([[[WCSettings settings] objectForKey:WCBookmarks] count] > 0);
    }

	return YES;
}





#pragma mark -

- (void)dailyTimer:(NSTimer *)timer {
	[[NSNotificationCenter defaultCenter] postNotificationName:WCDateDidChangeNotification];
}





#pragma mark -

- (NSString *)chatLogsPath {
	NSString *path;
	
	path = [[WCSettings settings] stringForKey:WCChatLogsPath];
	
	if(!path)
		path = WCApplicationSupportPath;
		
	return [path stringByStandardizingPath];
}


- (void)reloadChatLogsWithPath:(NSString *)path {
	[self _reloadChatLogsControllerWithPath:path];
}


- (WIChatLogController *)logController {
	return _logController;
}




#pragma mark -

- (WIDateFormatter *)dateFormatter {
    return _dateFormatter;
}




#pragma mark -

- (void)checkForUpdate {
	[_updater checkForUpdates:self];
}





#pragma mark -


- (void)connectWithBookmark:(NSDictionary *)bookmark {
    [self _connectWithBookmark:bookmark];
}





#pragma mark -

- (NSURL *)applicationFilesDirectory
{
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *url = [appSupportURL URLByAppendingPathComponent:@"Wired Client"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[url path]])
        [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
    
    if(error)
        NSLog(@"ERROR: Application Support Directory: %@", error);
    
    return url;
}





#pragma mark -

- (IBAction)about:(id)sender {
	NSMutableParagraphStyle		*style;
	NSMutableAttributedString	*credits;
	NSDictionary				*attributes;
	NSAttributedString			*header, *stats;
	NSData						*rtf;
	NSString					*string;
	
    rtf = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"]];
    credits = [[[NSMutableAttributedString alloc] initWithRTF:rtf documentAttributes:NULL] autorelease];
    
    style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [style setAlignment:NSCenterTextAlignment];
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSFont boldSystemFontOfSize:11.0],	NSFontAttributeName,
                  [NSColor grayColor],					NSForegroundColorAttributeName,
                  style,									NSParagraphStyleAttributeName,
                  NULL];
    string = [NSSWF:@"%@\n", NSLS(@"Stats", @"About box title")];
    header = [NSAttributedString attributedStringWithString:string attributes:attributes];
    
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSFont systemFontOfSize:11.0],			NSFontAttributeName,
                  style,									NSParagraphStyleAttributeName,
                  NULL];
    string = [NSSWF:@"%@\n\n", [[WCStats stats] stringValue]];
    stats = [NSAttributedString attributedStringWithString:string attributes:attributes];
    
    [credits insertAttributedString:stats atIndex:0];
    [credits insertAttributedString:header atIndex:0];
    
    [NSApp orderFrontStandardAboutPanelWithOptions:
     [NSDictionary dictionaryWithObject:credits forKey:@"Credits"]];
}



- (IBAction)preferences:(id)sender {
	[[WCPreferences preferences] showWindow:self];
}



#pragma mark -

- (IBAction)connect:(id)sender {
	[[WCConnect connect] showWindow:sender];
}



- (IBAction)disconnect:(id)sender {
	[[WCPublicChat publicChat] disconnect:sender];
}



- (IBAction)reconnect:(id)sender {
	[[WCPublicChat publicChat] reconnect:sender];
}



- (IBAction)serverInfo:(id)sender {
	[[WCPublicChat publicChat] serverInfo:sender];
}



- (IBAction)files:(id)sender {
	[[WCPublicChat publicChat] files:sender];
}



- (IBAction)administration:(id)sender {
	[[WCPublicChat publicChat] administration:sender];
}



- (IBAction)broadcast:(id)sender {
	[[WCPublicChat publicChat] broadcast:sender];
}



- (IBAction)newDocument:(id)sender {
	[[WCBoards boards] showWindow:sender];
	[[WCBoards boards] newDocument:sender];
}



- (IBAction)deleteDocument:(id)sender {
	[[WCBoards boards] showWindow:sender];
	[[WCBoards boards] deleteDocument:sender];
}



- (IBAction)changePassword:(id)sender {
	[[WCPublicChat publicChat] changePassword:sender];
}



#pragma mark -

- (IBAction)insertSmiley:(id)sender {
	NSFileWrapper		*wrapper;
	NSTextAttachment	*attachment;
	NSAttributedString	*attributedString;
	
	wrapper				= [[NSFileWrapper alloc] initWithPath:[sender representedObject]];
	attachment			= [[WITextAttachment alloc] initWithFileWrapper:wrapper string:[sender toolTip]];
	attributedString	= [NSAttributedString attributedStringWithAttachment:attachment];
	
	[[[NSApp keyWindow] firstResponder] tryToPerform:@selector(insertText:) with:attributedString];
	
	[attachment release];
	[wrapper release];
}



#pragma mark -

- (IBAction)addBookmark:(id)sender {
	[[WCPublicChat publicChat] addBookmark:sender];
}



- (void)bookmark:(id)sender {
	[self _connectWithBookmark:[sender representedObject]];
}


- (IBAction)exportBookmarks:(id)sender {
	__block NSSavePanel     *savePanel;
    
    [[WCPublicChat publicChat] showWindow:self];
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredBookmarks"]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAccessoryView:_bookmarksExportView];
    [savePanel setNameFieldStringValue:[NSLS(@"Bookmarks", @"Default export bookmarks name")
										stringByAppendingPathExtension:@"WiredBookmarks"]];
    
    [savePanel beginSheetModalForWindow:[[WCPublicChat publicChat] window] completionHandler:^(NSInteger result) {
        NSEnumerator			*enumerator;
        NSMutableArray			*bookmarks;
        NSMutableDictionary		*bookmark;
        NSDictionary			*dictionary;
        NSString				*password;
        
        if(result == NSModalResponseOK) {
            bookmarks	= [NSMutableArray array];
            enumerator	= [[[WCSettings settings] objectForKey:WCBookmarks] objectEnumerator];
            
            while((dictionary = [enumerator nextObject])) {
                bookmark = [[dictionary mutableCopy] autorelease];
                password = [[WCKeychain keychain] passwordForBookmark:bookmark];
                
                if(password)
                    [bookmark setObject:password forKey:WCBookmarksPassword];
                
                [bookmark removeObjectForKey:WCBookmarksIdentifier];
                
                [bookmarks addObject:bookmark];
            }
            
            [bookmarks writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}


- (IBAction)exportTrackerBookmarks:(id)sender {
    __block NSSavePanel     *savePanel;
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredTrackerBookmarks"]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAccessoryView:_bookmarksExportView];
    [savePanel setNameFieldStringValue:[NSLS(@"Bookmarks", @"Default export bookmarks name")
										stringByAppendingPathExtension:@"WiredTrackerBookmarks"]];
    
    [savePanel beginSheetModalForWindow:[[WCPublicChat publicChat] window] completionHandler:^(NSInteger result) {
        NSEnumerator			*enumerator;
        NSMutableArray			*bookmarks;
        NSMutableDictionary		*bookmark;
        NSDictionary			*dictionary;
        NSString				*password;
        
        if(result == NSModalResponseOK) {
            bookmarks	= [NSMutableArray array];
            enumerator	= [[[WCSettings settings] objectForKey:WCTrackerBookmarks] objectEnumerator];
            
            while((dictionary = [enumerator nextObject])) {
                bookmark = [[dictionary mutableCopy] autorelease];
                password = [[WCKeychain keychain] passwordForTrackerBookmark:bookmark];
                
                if(password)
                    [bookmark setObject:password forKey:WCTrackerBookmarksPassword];
                
                [bookmark removeObjectForKey:WCTrackerBookmarksIdentifier];
                
                [bookmarks addObject:bookmark];
            }
            
            [bookmarks writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}



- (IBAction)importBookmarks:(id)sender {
	__block NSOpenPanel     *openPanel;
	
	openPanel = [NSOpenPanel openPanel];
    
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"WiredBookmarks", @"WiredTrackerBookmarks", nil]];
    
    [openPanel beginSheetModalForWindow:[[WCPublicChat publicChat] window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK) {
            if([[[openPanel URL] pathExtension] isEqualToString:@"WiredBookmarks"]) {
                [[WCPreferences preferences] importBookmarksFromFile:[[openPanel URL] path]];
            }
            else if([[[openPanel URL] pathExtension] isEqualToString:@"WiredTrackerBookmarks"]) {
                [[WCPreferences preferences] importTrackerBookmarksFromFile:[[openPanel URL] path]];
            }
        }
    }];
}





#pragma mark -

- (IBAction)console:(id)sender {
	[[WCPublicChat publicChat] console:sender];
}



#pragma mark -

- (IBAction)chat:(id)sender {
	[[WCPublicChat publicChat] showWindow:sender];
}



- (IBAction)servers:(id)sender {

}



- (IBAction)boards:(id)sender {
	[[WCBoards boards] showWindow:sender];
}



- (IBAction)messages:(id)sender {
	[[WCMessages messages] showWindow:sender];
}



- (IBAction)transfers:(id)sender {
	[[WCTransfers transfers] showWindow:sender];
}



- (IBAction)chatHistory:(id)sender {
	[[WCChatHistory chatHistory] showWindow:sender];
}


- (IBAction)nextConnection:(id)sender {
	[[WCPublicChat publicChat] nextConnection:sender];
}



- (IBAction)previousConnection:(id)sender {
	[[WCPublicChat publicChat] previousConnection:sender];
}



#pragma mark -

- (IBAction)toggleUserList:(id)sender {
    [[WCPublicChat publicChat] toggleUserList:sender];
}

- (IBAction)toggleServersList:(id)sender {
    [[WCPublicChat publicChat] toggleServersList:sender];
}

- (IBAction)toggleTabBar:(id)sender {
    [[WCPublicChat publicChat] toggleTabBar:sender];
}




#pragma mark -

- (IBAction)releaseNotes:(id)sender {
	NSString		*path;
	
	path = [[self bundle] pathForResource:@"wiredclientrnote" ofType:@"html"];
	
	[[WIReleaseNotesController releaseNotesController]
		setReleaseNotesWithHTML:[NSData dataWithContentsOfFile:path]];
	[[WIReleaseNotesController releaseNotesController] showWindow:self];
}



- (IBAction)crashReports:(id)sender {
	[[WICrashReportsController crashReportsController] setApplicationName:[NSApp name]];
	[[WICrashReportsController crashReportsController] showWindow:self];
}



- (IBAction)manual:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wired.read-write.fr/wiki/"]];
}


- (IBAction)support:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/nark/WiredClient/issues?milestone=1&state=open"]];
}

@end
