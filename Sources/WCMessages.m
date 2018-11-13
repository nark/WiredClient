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

#import "WCApplicationController.h"
#import "WCChatController.h"
#import "WCPublicChat.h"
#import "WCConversation.h"
#import "WCConversationController.h"
#import "WCMessage.h"
#import "WCMessages.h"
#import "WCPreferences.h"
#import "WCPublicChat.h"
#import "WCServerConnection.h"
#import "WCSourceSplitView.h"
#import "WCStats.h"
#import "WCUser.h"
#import "WCEmoticonViewController.h"
#import "WCDatabaseController.h"
#import "WDWiredModel.h"
#import "NSManagedObjectContext+Fetch.h"


NSString * const WCMessagesDidChangeUnreadCountNotification		= @"WCMessagesDidChangeUnreadCountNotification";





@interface WCMessages (Data)

- (WDMessagesConversation *)        _messagesConversationForUser:(WCUser *)user;
- (WDBroadcastsConversation *)      _broadcastsConversationForUser:(WCUser *)user;

@end



@interface WCMessages (Private)

- (void)                    _validate;
- (void)                    _themeDidChange;
- (void)                    _adjustMessageTextFieldHeight;

- (void)                    _showDialogForMessage:(WDMessage *)message;
- (NSString *)              _stringForMessageString:(NSString *)string;
- (void)                    _sendMessage;

- (NSArray *)               _commands;
- (BOOL)                    _runCommand:(NSString *)string;

- (WDMessagesNode *)        _selectedNode;
- (WDConversation *)        _selectedConversation;
- (WDMessage *)             _selectedMessage;

- (void)                    _selectConversation:(WDConversation *)conversation;
- (void)                    _updateSelectedConversation;
- (NSInteger)               _numberOfConversations;

- (void)                    _sortConversations;
- (void)                    _filterConversations;

- (void)                    _revalidateConversationsWithConnection:(WCServerConnection *)connection;
- (void)                    _invalidateConversationsWithConnection:(WCServerConnection *)connection;
- (void)                    _revalidateConversationsWithUser:(WCUser *)user;
- (void)                    _invalidateConversationsWithUser:(WCUser *)user;

- (void)                    _markConversationAsRead:(WDConversation *)conversation;

- (void)                    _migrateToCoreData;
- (void)                    _migrateConversations:(NSArray *)conversations;

@end






@implementation WCMessages (Data)

- (WDMessagesConversation *)_messagesConversationForUser:(WCUser *)user {
    WDMessagesConversation      *conversation;
    NSPredicate                 *predicate;
    NSError                     *error = nil;
    
    predicate = [NSPredicate predicateWithFormat:
                 @"(nick == %@) && (identifier == %@)",
                 [user nick],
                 [[user connection] URLIdentifier]];
    
    conversation = [self.managedObjectContext fetchEntityNammed:@"MessagesConversation"
                                                  withPredicate:predicate
                                                          error:&error];
    
    if(error) {
        [NSApp presentError:error];
        return nil;
    }
    
    if(!conversation) {
        conversation = [WDMessagesConversation conversationWithUser:user
                                                         connection:[user connection]];
        
        [[WCDatabaseController sharedController] save];
    } else {
        [conversation setUser:user];
        [conversation setConnection:[user connection]];
    }
    
    return conversation;
}


- (WDBroadcastsConversation *)_broadcastsConversationForUser:(WCUser *)user {
    WDBroadcastsConversation    *conversation;
    NSPredicate                 *predicate;
    NSError                     *error = nil;
    
    predicate = [NSPredicate predicateWithFormat:
                 @"(nick == %@) && (identifier == %@)",
                 [user nick],
                 [[user connection] URLIdentifier]];
    
    conversation = [self.managedObjectContext fetchEntityNammed:@"BroadcastsConversation"
                                                  withPredicate:predicate
                                                          error:&error];
    
    if(error) {
        [NSApp presentError:error];
        return nil;
    }
    
    if(!conversation) {
        conversation = [WDBroadcastsConversation conversationWithUser:user
                                                           connection:[user connection]];
        
        [[WCDatabaseController sharedController] save];
    } else {
        [conversation setUser:user];
        [conversation setConnection:[user connection]];
    }
    
    return conversation;
}

@end





@implementation WCMessages(Private)

- (void)_validate {
	WDConversation		*conversation;
	WCServerConnection	*connection;
    BOOL                enabled;
	
	conversation	= [self _selectedConversation];
	connection		= [conversation connection];
    enabled         = (connection != NULL && [connection isConnected] && [[conversation user] connection] != NULL);
    
	[_messageTextField setEditable:enabled];
	[_emoticonButton setEnabled:enabled];
    
	[[[self window] toolbar] validateVisibleItems];
}



- (void)_themeDidChange {
	NSDictionary				*theme;
	NSFont						*font;
	NSColor						*textColor, *backgroundColor;
	NSString					*templatePath;
	NSBundle					*templateBundle;
    
	theme						= [[[self _selectedConversation] connection] theme];
	
	if(!theme)
		theme					= [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
    
	templateBundle				= [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];
    
	font						= WIFontFromString([theme objectForKey:WCThemesMessagesFont]);
	textColor					= WIColorFromString([theme objectForKey:WCThemesMessagesTextColor]);
	backgroundColor				= WIColorFromString([theme objectForKey:WCThemesMessagesBackgroundColor]);
	templatePath				= [templateBundle bundlePath];
    
	[_conversationController setTemplatePath:templatePath];
	[_conversationController setFont:font];
	[_conversationController setTextColor:textColor];
	[_conversationController setBackgroundColor:backgroundColor];
		
	[_messageTextField setFont:font];
	[_messageTextField setTextColor:textColor];
	//[_messageTextField setInsertionPointColor:textColor];
    [[_messageTextField.cell fieldEditorForView:_messageTextField] setInsertionPointColor:textColor];
	[_messageTextField setBackgroundColor:backgroundColor];
	
	[_broadcastTextView setFont:font];
	[_broadcastTextView setTextColor:textColor];
	[_broadcastTextView setInsertionPointColor:textColor];
	[_broadcastTextView setBackgroundColor:backgroundColor];
	
	[_conversationController reloadTemplate];
    [_conversationController reloadData];
}


- (void)_adjustMessageTextFieldHeight {
    [_messageTextField adjustHeightForTopView:_conversationWebView bottomView:_messagesView];
    [_conversationWebView scrollToBottom];
}





#pragma mark -

- (void)_showDialogForMessage:(WDMessage *)message {
	NSAlert		*alert;
	NSString	*title, *nick, *server, *time;
	
	nick	= [message nick];
	server	= [[message connection] name];
	time	= [_dialogDateFormatter stringFromDate:[message date]];
	
	if([message isKindOfClass:[WDPrivateMessage class]])
		title = [NSSWF:NSLS(@"Private message from %@ on %@ at %@", @"Message dialog title (nick, server, time)"), nick, server, time];
	else
		title = [NSSWF:NSLS(@"Broadcast from %@ on %@ at %@", @"Broadcast dialog title (nick, server, time)"), nick, server, time];
	
	alert = [[NSAlert alloc] init];
	[alert setMessageText:title];
	[alert setInformativeText:[message messageString]];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert runNonModal];
	[alert release];
	
	[message setUnreadValue:NO];
}



- (NSString *)_stringForMessageString:(NSString *)string {
	NSString	*command, *argument;
	NSRange		range;
	
	range = [string rangeOfString:@" "];
	
	if(range.location == NSNotFound) {
		command = string;
		argument = @"";
	} else {
		command = [string substringToIndex:range.location];
		argument = [string substringFromIndex:range.location + 1];
	}
	
	if([command isEqualToString:@"/exec"] && [argument length] > 0)
		return [WCChatController outputForShellCommand:argument];
	else if([command isEqualToString:@"/stats"])
		return [[WCStats stats] stringValue];
	
	return string;
}



- (void)_sendMessage {
	NSString				*string;
	WIP7Message				*p7Message;
	WCServerConnection		*connection;
	WDConversation			*conversation;
	WDMessage               *message;
	WCUser					*user, *selfUser;
	
	if([self _runCommand:[_messageTextField stringValue]])
		return;
    
    conversation	= [self _selectedConversation];
	string			= [WCChatController stringByDecomposingSmileyAttributesInAttributedString:[_messageTextField attributedStringValue]];
    selfUser        = [[[conversation connection] chatController] userWithUserID:[[conversation connection] userID]];
	user			= [conversation user];
    connection      = [user connection];
    
    NSLog(@"connection : %@ %d %@", connection, [connection isConnected], user);
        
    if(![conversation direction])
        [conversation setDirection:[NSNumber numberWithInteger:WCMessageTo]];
    
	message			= [WDPrivateMessage messageToSomeoneFromUser:selfUser
												   message:string
												connection:connection];
    
    [message setUnreadValue:NO];
    
    [conversation setDate:[message date]];
	[conversation addMessagesObject:message];
	
	[[WCDatabaseController sharedController] save];
    [self _sortConversations];

	p7Message = [WIP7Message messageWithName:@"wired.message.send_message" spec:WCP7Spec];
	[p7Message setUInt32:[[conversation user] userID] forName:@"wired.user.id"];
	[p7Message setString:[self _stringForMessageString:[message messageString]] forName:@"wired.message.message"];
	[[conversation connection] sendMessage:p7Message];
	
	[[WCStats stats] addUnsignedInt:1 forKey:WCStatsMessagesSent];
	
	[_conversationController appendMessage:message];
	
	[_messageTextField setStringValue:@""];
}




#pragma mark -

- (void)_printHTML:(NSString *)html {
	NSString				*string;
	WIP7Message				*p7Message;
	WCServerConnection		*connection;
	WDConversation			*conversation;
	WDMessage               *message;
	WCUser					*user;
	
	string			= html;
	conversation	= [self _selectedConversation];
	connection		= [conversation connection];
	user			= [[connection chatController] userWithUserID:[connection userID]];
	message			= [WDPrivateMessage messageToSomeoneFromUser:user
												   message:string
												connection:connection];
	
	[conversation addMessagesObject:message];
	
	[[WCDatabaseController sharedController] save];
	
	p7Message = [WIP7Message messageWithName:@"wired.message.send_message" spec:WCP7Spec];
	[p7Message setUInt32:[[conversation user] userID] forName:@"wired.user.id"];
	[p7Message setString:[self _stringForMessageString:[message messageString]] forName:@"wired.message.message"];
	[[message connection] sendMessage:p7Message];
	
	[[WCStats stats] addUnsignedInt:1 forKey:WCStatsMessagesSent];
	
    [_conversationController appendMessage:message];
	
	[_messageTextField setStringValue:@""];
}



- (void)_sendImage:(NSString *)path {
	NSURL		*url;
	NSString	*html;
	
	url = [NSURL URLWithString:path];
	
	if(!url)
		return;
	
	if([[url scheme] containsSubstring:@"http"]) {
		html = [NSSWF:@"<a class='chat-media-frame' href='%@'><img src='%@' alt='' /></a>", [url absoluteString], [url absoluteString]];
	} else {
		html = nil;
	}
	
	if(html && [html length] > 0)
		[self _printHTML:html];
}

- (void)_sendYouTube:(NSURL *)url {
	NSString		*html, *videoID;
	NSArray			*parameters;
	
	if([[url scheme] containsSubstring:@"http"]) {
		
		if([[url host] containsSubstring:@"youtu.be"])
			videoID = [[url absoluteString] lastPathComponent];
		
		else if([[url host] containsSubstring:@"youtube.com"]) {
			parameters = [[url query] componentsSeparatedByString:@"&"];
			
			for (NSString * pair in parameters) {
				NSArray * bits = [pair componentsSeparatedByString:@"="];
				NSString * key = [[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
				NSString * value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
				
				if([key isEqualToString:@"v"]) {
					videoID = value;
					continue;
				}
			}
		} else
			videoID = nil;
		
		NSLog(@"videoID : %@", videoID);
		
		if(videoID)
			html = [NSSWF:@"<div class='chat-media-frame'><iframe width='300' height='233' src='http://www.youtube.com/embed/%@' frameborder='0' allowfullscreen></iframe></div>", videoID];
	} else {
		html = nil;
	}
	
	if(html && [html length] > 0) {
		[self _printHTML:html];
	}
}



#pragma mark -

- (NSArray *)_commands {
	return [NSArray arrayWithObjects:
			@"/img",
			@"/html",
			@"/youtube",
			@"/utube",
			NULL];
}



- (BOOL)_runCommand:(NSString *)string {
	NSString		*command, *argument;
	NSRange			range;
	
	range = [string rangeOfString:@" "];
	
	if(range.location == NSNotFound) {
		command = string;
		argument = @"";
	} else {
		command = [string substringToIndex:range.location];
		argument = [string substringFromIndex:range.location + 1];
	}
	
	if([command isEqualToString:@"/img"]) {
		
		if(argument && [argument length] > 0)
			[self _sendImage:argument];
		
		return YES;
	}
	else if([command isEqualToString:@"/html"]) {
		
		if(argument && [argument length] > 0)
			if([[WCChatController class] checkHTMLRestrictionsForString:argument])
				[self _printHTML:argument];
		
		return YES;
	}
	else if([command isEqualToString:@"/youtube"] || [command isEqualToString:@"/utube"]) {
		if(argument && [argument length] > 0) {
			NSURL *url = [NSURL URLWithString:argument];
			
			if(url)
				[self _sendYouTube:url];
		}
		
		return YES;
	}
	
	return NO;
}







#pragma mark -

- (WDMessagesNode *)_selectedNode {
    NSInteger		row;
    
    row = [_conversationsOutlineView clickedRow];
	
    if(row < 0)
        row = [_conversationsOutlineView selectedRow];
    
	if(row >= 0) {
		return [[_conversationsOutlineView itemAtRow:row] representedObject];
	}
    
    return nil;
}


- (WDMessage *)_selectedMessage {
    WDMessagesNode *node;
    
    node = [self _selectedNode];
    
    if([node isMemberOfClass:[WDMessage class]])
        return (WDMessage *)node;
    
	return nil;
}



- (WDConversation *)_selectedConversation {
	return _selectedConversation;
}




- (void)_updateSelectedConversation {
    WDMessagesNode  *node;
	NSInteger		row;
	id				item;
    
    node = [self _selectedNode];
    
    if(_selectedConversation)
        [NSObject cancelPreviousPerformRequestsWithTarget:_selectedConversation];
    
	[_selectedConversation release];
	_selectedConversation = NULL;
	
	row = [_conversationsOutlineView clickedRow];
	
    if(row < 0)
        row = [_conversationsOutlineView selectedRow];
    
	if(row >= 0) {
		item = [[_conversationsOutlineView itemAtRow:row] representedObject];
        
        if([item isKindOfClass:[WDConversation class]])
            _selectedConversation = [item retain];
        else    
            _selectedConversation = [[item valueForKey:@"conversation"] retain];
	}
    
    if([_selectedConversation isUnread]) {
        [self performSelector:@selector(_markConversationAsRead:)
                   withObject:_selectedConversation
                   afterDelay:1.5];
    }
    
    [_conversationController setConversation:_selectedConversation];
    
    [self _validate];
}

- (NSInteger)_numberOfConversations {
    NSFetchRequest  *request;
    NSError         *err;
    NSUInteger      count;
    
    request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:@"Conversation"
                                   inManagedObjectContext:self.managedObjectContext]];
    
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    count = [self.managedObjectContext countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        return 0;
    }
    [request release];
    
    return count;
}



#pragma mark -

- (void)_sortConversations {
    _sorting = (BOOL*)YES;
    [_conversationsTreeController rearrangeObjects];
    _sorting = (BOOL*)NO;
}


- (void)_filterConversations {
    NSMutableString         *searchText;
    NSMutableArray          *subPredicates;
    NSPredicate             *predicate;
    BOOL                    active;
    
    subPredicates       = [[[NSMutableArray alloc] init] autorelease];
    searchText          = [NSMutableString stringWithString:[_conversationsSearchField stringValue]];
    active              = ([_conversationsOnlineButton state] == NSOnState);

    if(active)
        [subPredicates addObject:[NSPredicate predicateWithFormat:
                                  @"(active == %@)",
                                  [NSNumber numberWithBool:active]]];
        
    if([_conversationsFiltersPopUpButton selectedTag] == 0) {
        [_conversationsTreeController setEntityName:@"Conversation"];
    }
    else if([_conversationsFiltersPopUpButton selectedTag] == 1) {
        [_conversationsTreeController setEntityName:@"MessagesConversation"];
    }
    else if([_conversationsFiltersPopUpButton selectedTag] == 2) {
        [_conversationsTreeController setEntityName:@"BroadcastsConversation"];
    }
    else if([_conversationsFiltersPopUpButton selectedTag] == 3) {
        // Draft
    }
    else if([_conversationsFiltersPopUpButton selectedTag] == 4) {
        // Archives
    }
    
    while ([searchText rangeOfString:@"Â  "].location != NSNotFound) {
        // Remove extraenous whitespace
        [searchText replaceOccurrencesOfString:@"Â  " withString:@" " options:0 range:NSMakeRange(0, [searchText length])];
    }
    if ([searchText length] != 0) {
        // Remove leading space
        [searchText replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0,1)];
    }
    if ([searchText length] != 0) {
        // Remove trailing space
        [searchText replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange([searchText length]-1, 1)];
    }
    if ([searchText length] == 0) {
        // Reset predicate
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
        [_conversationsTreeController setFetchPredicate:predicate];
        return;
    }
    
    predicate = [NSPredicate predicateWithFormat:
                 @"(serverName CONTAINS[cd] %@) OR (nick CONTAINS[cd] %@) OR (identifier CONTAINS[cd] %@) OR (ANY messages.message CONTAINS[cd] %@)",
                 searchText,
                 searchText,
                 searchText,
                 searchText];
        
    [subPredicates addObject:predicate];
    
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    
    [_conversationsTreeController setSortDescriptors:self.sortDescriptors];
    [_conversationsTreeController setFetchPredicate:predicate];
}





#pragma mark -

- (void)_selectConversation:(WDConversation *)conversation {
    NSIndexPath *indexPath;
    
    indexPath = [_conversationsTreeController indexPathOfObject:conversation];
    
    if(indexPath) {
        [_conversationsTreeController setSelectionIndexPath:indexPath];
    }
}


- (void)_revalidateConversationsWithConnection:(WCServerConnection *)connection {
    NSPredicate     *predicate;
    NSArray         *conversations;
    
    predicate       = [NSPredicate predicateWithFormat:@"(identifier == %@)", [connection URLIdentifier]];
    conversations   = [self.managedObjectContext fetchEntitiesNammed:@"Conversation"
                                                       withPredicate:predicate
                                                               error:nil];
    
    for(WDConversation *conversation in conversations) {
        [conversation revalidateForConnection:connection];
    }
    
    [[WCDatabaseController sharedController] save];
}

- (void)_invalidateConversationsWithConnection:(WCServerConnection *)connection {
    NSPredicate     *predicate;
    NSArray         *conversations;
    
    predicate       = [NSPredicate predicateWithFormat:@"(identifier == %@)", [connection URLIdentifier]];
    conversations   = [self.managedObjectContext fetchEntitiesNammed:@"Conversation"
                                                       withPredicate:predicate
                                                               error:nil];
    
    for(WDConversation *conversation in conversations) {
        [conversation invalidateForConnection:connection];
    }
    [[WCDatabaseController sharedController] save];
}


- (void)_revalidateConversationsWithUser:(WCUser *)user {
    NSPredicate     *predicate;
    NSArray         *conversations;
    
    predicate       = [NSPredicate predicateWithFormat:
                       @"(identifier == %@)",
                       [[user connection] URLIdentifier]];
    
    conversations   = [self.managedObjectContext fetchEntitiesNammed:@"Conversation"
                                                       withPredicate:predicate
                                                               error:nil];
    
    for(WDConversation *conversation in conversations) {
        [conversation revalidateForUser:user];
    }
    [[WCDatabaseController sharedController] save];
}


- (void)_invalidateConversationsWithUser:(WCUser *)user {
    NSPredicate     *predicate;
    NSArray         *conversations;
    
    predicate       = [NSPredicate predicateWithFormat:
                       @"(identifier == %@)",
                       [[user connection] URLIdentifier]];
    
    conversations   = [self.managedObjectContext fetchEntitiesNammed:@"Conversation"
                                                       withPredicate:predicate
                                                               error:nil];
    
    for(WDConversation *conversation in conversations) {
        [conversation invalidateForUser:user];
    }
    [[WCDatabaseController sharedController] save];
}




#pragma mark -

- (void)_markConversationAsRead:(WDConversation *)conversation {
    if([conversation isUnread]) {
        if([[self window] isKeyWindow]) {
            [conversation setNumberOfUnreadsValue:0];
            
            [[WCDatabaseController sharedController] save];
            [[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification object:self];
        }
    }
}




#pragma mark - 

- (void)_migrateToCoreData {
    NSData                  *data;
	NSMutableArray			*array;
    
    array   = [NSMutableArray array];
    data    = [[WCSettings settings] objectForKey:WCMessageConversations];
    
    if(data) {
        [array addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    }
    
    data = [[WCSettings settings] objectForKey:WCBroadcastConversations];
    
    if(data) {
        [array addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    }
    
    if([array count] > 0) {
        NSInteger nbMessage = 0;
        for(WCConversation *conv in array) {
            nbMessage += [conv numberOfMessages];
        }
        
        NSAlert *alert = [NSAlert alertWithMessageText:NSLS(@"Messages Migration", @"Messages Migration Title")
                                         defaultButton:NSLS(@"Migrate", @"Messages Migration Migrate Button")
                                       alternateButton:NSLS(@"Erase", @"Messages Migration Erase Button")
                                           otherButton:NSLS(@"Quit", @"Messages Migration Quit Button")
                             informativeTextWithFormat:NSLS(@"Local storage of Messages moved to Core Data.\n\nChoose 'Migrate' in order to recover old messages. Choosing 'Erase' will erase all your messages and start on a fresh database (this cannot be undone).\n\nDepending to the number of messages (%d), the operation could take a while.", @"Messages Migration Message"), nbMessage];
        
        NSInteger result = [alert runModal];
        
        if(result == NSAlertDefaultReturn) {
            [self _migrateConversations:array];
        }
        else if(result == NSAlertAlternateReturn) {
            [[WCSettings settings] setObject:@{} forKey:WCMessageConversations];
            [[WCSettings settings] setObject:@{} forKey:WCBroadcastConversations];
        }
        else if(result == NSAlertOtherReturn) {
            exit(0);
        }
    }
}


- (void)_migrateConversations:(NSArray *)conversations {
    __block NSManagedObjectContext      *context;
    __block NSAutoreleasePool           *pool, *subpool;
    __block NSString                    *title;
    __block NSUInteger                  count, msgCount, totalMsgCount;
    
    NSBlockOperation                    *operation;
    
    title           = [[[self  window] title] copy];
    count           = 0;
    msgCount        = 0;
    totalMsgCount   = 0;
    
    [[self  window] setTitle:[NSSWF:NSLS(@"%@ (Migrating...)", @"Migrating Window Title"), title]];
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setPersistentStoreCoordinator:[[WCDatabaseController sharedController] persistentStoreCoordinator]];
    [context setUndoManager:nil];
    
    operation   = [NSBlockOperation blockOperationWithBlock:^{
        pool = [[NSAutoreleasePool alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:[WCDatabaseController sharedController]
                                                 selector:@selector(mergeChanges:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:context];
        
        for(WCConversation *conversation in conversations) {
            if([conversation numberOfMessages] > 0) {
                if([conversation isKindOfClass:[WCMessageConversation class]]) {
                    subpool = [[NSAutoreleasePool alloc] init];
                    
                    WDConversation *newConversation = [WDMessagesConversation conversationWithConversation:(WCMessageConversation *)conversation context:context];
                                        
                    for(WCPrivateMessage *message in [conversation messages]) {
                        if(![newConversation direction])
                            [newConversation setDirection:[NSNumber numberWithInteger:[message direction]]];
                        
                        WDPrivateMessage *newMessage = [WDPrivateMessage messageWithMessage:message context:context];
                        [newConversation addMessagesObject:newMessage];
                        [newConversation setDate:[newMessage date]];
                        totalMsgCount++;
                        msgCount++;
                        
                        if(msgCount > 50) {
                            [[WCDatabaseController sharedController] saveContext:context];
                            msgCount = 0;
                        }
                    }
                    
                    [subpool drain];
                }
                else if([conversation isKindOfClass:[WCBroadcastConversation class]]) {
                    subpool = [[NSAutoreleasePool alloc] init];
                    
                    WDConversation *newConversation = [WDBroadcastsConversation conversationWithConversation:(WCBroadcastConversation *)conversation context:context];
                                        
                    for(WCBroadcastMessage *message in [conversation messages]) {
                        WDBroadcastMessage *newMessage = [WDBroadcastMessage messageWithMessage:message context:context];
                        [newConversation addMessagesObject:newMessage];
                        [newConversation setDate:[newMessage date]];
                        totalMsgCount++;
                        msgCount++;
                        
                        if(msgCount > 50) {
                            [[WCDatabaseController sharedController] saveContext:context];
                            msgCount = 0;
                        }
                    }
                    
                    [subpool drain];
                }
            }
            
            [[WCDatabaseController sharedController] saveContext:context];
            count++;
        }
        
        [pool drain];
    }];
    
    [operation setCompletionBlock:^{
        if(count == [conversations count]) {
            [[WCSettings settings] setObject:@{} forKey:WCMessageConversations];
            [[WCSettings settings] setObject:@{} forKey:WCBroadcastConversations];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self  window] setTitle:title];
                [title autorelease];
            });
        }
    }];
    
    [[WCDatabaseController queue] addOperation:operation];
}




@end








@implementation WCMessages


#pragma mark -

@dynamic    managedObjectContext;
@synthesize sortDescriptors         = _sortDescriptors;

@synthesize conversationWebView     = _conversationWebView;
@synthesize messagesView            = _messagesView;



#pragma mark -

+ (id)messages {
	static WCMessages   *sharedMessages;
	
	if(!sharedMessages)
		sharedMessages = [[self alloc] init];
	
	return sharedMessages;
}




#pragma mark -

- (id)init {
    NSSortDescriptor *dateDescriptor;
    
	self = [super initWithWindowNibName:@"Messages"];
    
    if(self) {
        dateDescriptor          = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        _sortDescriptors        = [[NSArray arrayWithObjects:dateDescriptor, nil] retain];
        
        _dialogDateFormatter = [[WIDateFormatter alloc] init];
        [_dialogDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        _sorting = (BOOL*)NO;
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationWillTerminate:)
         name:NSApplicationWillTerminateNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(selectedThemeDidChange:)
         name:WCSelectedThemeDidChangeNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(linkConnectionLoggedIn:)
         name:WCLinkConnectionLoggedInNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(linkConnectionDidClose:)
         name:WCLinkConnectionDidCloseNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(linkConnectionDidTerminate:)
         name:WCLinkConnectionDidTerminateNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(chatUserNickDidChange:)
         name:WCChatUserNickDidChangeNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(chatUserAppeared:)
         name:WCChatUserAppearedNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(chatUserDisappeared:)
         name:WCChatUserDisappearedNotification];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(messagesDidChangeUnreadCount:)
         name:WCMessagesDidChangeUnreadCountNotification];
        
        [self window];
	}
	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_selectedConversation release];
    
    [_sortDescriptors release];
	
	[_dialogDateFormatter release];
    
	[super dealloc];
}



#pragma mark -

- (NSString *)saveDocumentMenuItemTitle {
    return NSLS(@"Save Conversation", @"Save conversation menu");
}




#pragma mark -

- (void)windowDidLoad {
	[self setShouldCascadeWindows:NO];
    
    [self _migrateToCoreData];
    
    [_conversationsTreeController setFetchPredicate:nil];
    [_conversationsTreeController setSortDescriptors:self.sortDescriptors];
    
    [_conversationsOutlineView setTarget:self];
    [_conversationsOutlineView setDeleteAction:@selector(deleteConversation:)];
    
    [_messagesView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [_messageTextField setTranslatesAutoresizingMaskIntoConstraints:YES];
    
	[self _themeDidChange];
    [self _sortConversations];
	[self _validate];
}

- (void)awakeFromNib {

}



- (void)windowDidBecomeKey:(NSWindow *)window {
	WDConversation		*conversation;
    	
	conversation = [self _selectedConversation];
	
	if(conversation) {
        if([conversation isUnread]) {
            [conversation setNumberOfUnreadsValue:0];
            [_conversationsTreeController fetch:self];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
            [self _sortConversations];
        }
	}
}



- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	if([identifier isEqualToString:@"RevealInUserList"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Reveal in User List", @"Reveal in user list message toolbar item")
												content:[NSImage imageNamed:@"RevealInUserList"]
												 target:self
												 action:@selector(revealInUserList:)];
	}
	else if([identifier isEqualToString:@"Clear"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Clear", @"Clear messages toolbar item")
												content:[NSImage imageNamed:@"ClearMessages"]
												 target:self
												 action:@selector(clearMessages:)];
	}
	
	return NULL;
}



- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
            @"RevealInUserList",
            NSToolbarFlexibleSpaceItemIdentifier,
            @"Clear",
            NULL];
}



- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
            @"RevealInUserList",
            @"Clear",
            NSToolbarSeparatorItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarCustomizeToolbarItemIdentifier,
            NULL];
}



- (void)applicationWillTerminate:(NSNotification *)notification {
    NSArray *activeConversations;
    NSPredicate *predicate;
    
    predicate = [NSPredicate predicateWithFormat:@"(active == YES)"];
    
    activeConversations = [[WCDatabaseController context] fetchEntitiesNammed:@"Conversation"
                                                                withPredicate:predicate
                                                                        error:nil];
    
    for(WDConversation *conversation in activeConversations) {
        [conversation invalidateForConnection:conversation.connection];
    }
    
	[[WCDatabaseController sharedController] save];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	WCServerConnection		*connection;
    
	connection = [notification object];
	
	if(![connection isKindOfClass:[WCServerConnection class]])
		return;
    
	[self _revalidateConversationsWithConnection:connection];
	
	[connection addObserver:self selector:@selector(wiredMessageMessage:) messageName:@"wired.message.message"];
	[connection addObserver:self selector:@selector(wiredMessageBroadcast:) messageName:@"wired.message.broadcast"];
	
	[self _validate];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	WCServerConnection		*connection;
	
	connection = [notification object];
	
	if(![connection isKindOfClass:[WCServerConnection class]])
		return;
    
	[self _invalidateConversationsWithConnection:connection];
	
	[connection removeObserver:self];
    
	[self _validate];
	
	[_conversationController reloadData];
}



- (void)linkConnectionDidTerminate:(NSNotification *)notification {
	WCServerConnection		*connection;
	
	connection = [notification object];
	
	if(![connection isKindOfClass:[WCServerConnection class]])
		return;
    
	[self _invalidateConversationsWithConnection:connection];
	
	[connection removeObserver:self];
	
	[self _validate];
	
	[_conversationController reloadData];
}



- (void)chatUserAppeared:(NSNotification *)notification {
	WCUser		*user;
	
	user = [notification object];
	
	[self _revalidateConversationsWithUser:user];
	
	if([[self _selectedConversation] user] == user)
		[_conversationController reloadData];
    
	
	[self _validate];
}



- (void)chatUserDisappeared:(NSNotification *)notification {
	WCUser		*user;
	
	user = [notification object];
	
	[self _invalidateConversationsWithUser:user];
	
	if([[self _selectedConversation] user] == user)
		[_conversationController reloadData];
    
	
	[self _validate];
}



- (void)chatUserNickDidChange:(NSNotification *)notification {
	WCUser		*user;
	
	user = [notification object];
	
	if([[self _selectedConversation] user] == user)
		[_conversationController reloadData];
    
	[_conversationsOutlineView reloadData];
	
	[self _validate];
}



- (void)messagesDidChangeUnreadCount:(NSNotification *)notification {
	[[WCDatabaseController sharedController] save];
	
	[_conversationsOutlineView setNeedsDisplay:YES];
}



- (void)wiredMessageMessage:(WIP7Message *)p7Message {
	WCServerConnection		*connection;
	WCUser					*user;
	WDPrivateMessage        *message;
	WDConversation			*conversation, *selectedConversation;
	WIP7UInt32				uid;
	
	[p7Message getUInt32:&uid forName:@"wired.user.id"];
	
	connection  = [p7Message contextInfo];
	user        = [[connection chatController] userWithUserID:uid];
	
	if(!user || [user isIgnored])
		return;
	
	conversation            = [self _messagesConversationForUser:user];
	selectedConversation    = [self _selectedConversation];
    
    if(![conversation direction])
        [conversation setDirection:[NSNumber numberWithInteger:WCMessageFrom]];
    
	message = [WDPrivateMessage messageFromUser:user
										message:[p7Message stringForName:@"wired.message.message"]
									 connection:connection];
	
    [conversation setDate:[message date]];
	[conversation addMessagesObject:message];
    
    if(![[self window] isKeyWindow])
        [conversation setNumberOfUnreadsValue:([conversation numberOfUnreadsValue] + 1)];
    
    [[WCDatabaseController sharedController] save];
    
    [self _sortConversations];
    
    if(selectedConversation == conversation) {
        [_conversationController appendMessage:message];
	}
    
	if([[[WCSettings settings] eventWithTag:WCEventsMessageReceived] boolForKey:WCEventsShowDialog])
		[self _showDialogForMessage:message];
    
	[[WCStats stats] addUnsignedInt:1 forKey:WCStatsMessagesReceived];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
	
	[connection triggerEvent:WCEventsMessageReceived info1:message info2:user];
	
	[self _validate];
}



- (void)wiredMessageBroadcast:(WIP7Message *)p7Message {
	WCServerConnection	*connection;
	WCUser				*user;
	WDBroadcastMessage  *message;
	WDConversation		*conversation, *selectedConversation;
	WIP7UInt32			uid;
    
	[p7Message getUInt32:&uid forName:@"wired.user.id"];
	
	connection  = [p7Message contextInfo];
	user        = [[connection chatController] userWithUserID:uid];
	
	if(!user || [user isIgnored])
		return;
    
	conversation            = [self _broadcastsConversationForUser:user];
	selectedConversation    = [self _selectedConversation];
    
    if(![conversation direction])
        [conversation setDirection:[NSNumber numberWithInteger:WCMessageFrom]];
    
	message = [WDBroadcastMessage broadcastFromUser:user
											message:[p7Message stringForName:@"wired.message.broadcast"]
										 connection:connection];
	
    [conversation setDate:[message date]];
	[conversation addMessagesObject:message];
    
    if(![[self window] isKeyWindow])
        [conversation setNumberOfUnreadsValue:([conversation numberOfUnreadsValue] + 1)];
    
    [[WCDatabaseController sharedController] save];

    [self _sortConversations];
    
	[self _selectConversation:selectedConversation];
    
	if([[[WCSettings settings] eventWithTag:WCEventsBroadcastReceived] boolForKey:WCEventsShowDialog])
		[self _showDialogForMessage:message];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
	
	[connection triggerEvent:WCEventsMessageReceived info1:message info2:user];
	
	[self _validate];
}


- (void)selectedThemeDidChange:(NSNotification *)notification {
	[self _themeDidChange];
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL		selector;
	
	selector = [menuItem action];
	
	if(selector == @selector(revealInUserList:))
		return ([[self _selectedConversation] user] != NULL);
    
    else if(selector == @selector(deleteConversation:))
		return ([self _selectedConversation] != NULL);
    
	else if(selector == @selector(clearMessages:))
		return ([self _numberOfConversations] > 0);
	
    else if(selector == @selector(saveDocument:))
        return ([self _selectedConversation] != NULL);
    
	return YES;
}





#pragma mark -

- (BOOL)showNextUnreadConversation {
//	WDConversation	*conversation;
//	NSRect			rect;
//	
//	if([[self window] firstResponder] == _messageTextField && [_messageTextField isEditable])
//		return NO;
//	
//	rect = [[[[[[_conversationController conversationWebView] mainFrame] frameView] documentView] enclosingScrollView] documentVisibleRect];
//	rect.origin.y += 0.9 * rect.size.height;
//	
//	if([[[[[_conversationController conversationWebView] mainFrame] frameView] documentView] scrollRectToVisible:rect])
//		return YES;
//    
//	conversation = [_conversations nextUnreadConversationStartingAtConversation:[self _selectedConversation]];
//	
//	if(!conversation)
//		conversation = [_conversations nextUnreadConversationStartingAtConversation:NULL];
//	
//	if(conversation) {
//		[self _selectConversation:conversation];
//		
//		return YES;
//	}
//	
	return NO;
}



- (BOOL)showPreviousUnreadConversation {
//	WCConversation	*conversation;
//	NSRect			rect;
//	
//	if([[self window] firstResponder] == _messageTextField && [_messageTextField isEditable])
//		return NO;
//	
//	rect = [[[[[[_conversationController conversationWebView] mainFrame] frameView] documentView] enclosingScrollView] documentVisibleRect];
//	rect.origin.y -= 0.9 * rect.size.height;
//	
//	if([[[[[_conversationController conversationWebView] mainFrame] frameView] documentView] scrollRectToVisible:rect])
//		return YES;
//	
//	conversation = [_conversations previousUnreadConversationStartingAtConversation:[self _selectedConversation]];
//	
//	if(!conversation)
//		conversation = [_conversations previousUnreadConversationStartingAtConversation:NULL];
//    
//	if(conversation) {
//		[self _selectConversation:conversation];
//		
//		return YES;
//	}
//	
	return NO;
}



- (void)sendMessage:(NSString *)string toUser:(WCUser *)user {
    WDMessagesConversation      *conversation;
    
    conversation = [self _messagesConversationForUser:user];
    
    if(![conversation direction])
        [conversation setDirection:[NSNumber numberWithInteger:WCMessageTo]];
    
    [self _selectConversation:conversation];
	
    [_messageTextField setStringValue:string];
    [self _sendMessage];
    
    [self _markConversationAsRead:conversation];
}



- (void)showPrivateMessageToUser:(WCUser *)user {
    WDMessagesConversation      *conversation;
    
    conversation = [self _messagesConversationForUser:user];
    
    if(![conversation direction])
        [conversation setDirection:[NSNumber numberWithInteger:WCMessageTo]];
    
    [self _selectConversation:conversation];
	
	[self showWindow:self];
	
	[self _validate];
	
	[[self window] makeFirstResponder:_messageTextField];
}



- (void)showBroadcastForConnection:(WCServerConnection *)connection {
	[self showWindow:self];
    
	[NSApp beginSheet:_broadcastPanel
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(broadcastSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:connection];
}




#pragma mark -

- (NSUInteger)numberOfUnreadMessages {
    NSArray         *conversations;
    NSUInteger      unreads = 0;
    
    conversations = [self.managedObjectContext fetchEntitiesNammed:@"Conversation" withPredicate:nil error:nil];
    
    for(WDConversation *conversation in conversations) {
        unreads += [conversation numberOfUnreadMessages];
    }
    
	return unreads;
}



- (NSUInteger)numberOfUnreadMessagesForConnection:(WCServerConnection *)connection {
    NSArray         *conversations;
    NSPredicate     *predicate;
    NSUInteger      unreads = 0;
    
    predicate       = [NSPredicate predicateWithFormat:@"(identifier == %@)", connection.URLIdentifier];
    conversations   = [self.managedObjectContext fetchEntitiesNammed:@"Conversation" withPredicate:predicate error:nil];
    
    for(WDConversation *conversation in conversations) {
        unreads += [conversation numberOfUnreadMessages];
    }
    
	return unreads;
}



#pragma mark -

- (void)broadcastSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WIP7Message				*message;
	WCServerConnection		*connection = contextInfo;
	
	if(returnCode == NSAlertDefaultReturn) {
		message = [WIP7Message messageWithName:@"wired.message.send_broadcast" spec:WCP7Spec];
		[message setString:[self _stringForMessageString:[_broadcastTextView string]] forName:@"wired.message.broadcast"];
		[connection sendMessage:message];
	}
    
	[_broadcastPanel close];
	[_broadcastTextView setString:@""];
}


- (IBAction)saveDocument:(id)sender {
    [self saveConversation:sender];
}


- (IBAction)saveConversation:(id)sender {
    __block NSSavePanel				*savePanel;
	__block WDConversation			*conversation;
	
	conversation = [self _selectedConversation];
	
	if(!conversation)
		return;
    
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"webarchive"]];
	[savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldStringValue:[[conversation nick] stringByAppendingPathExtension:@"webarchive"]];
    
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        WebResource				*dataSource;
        WebArchive				*archive;
        
        if(result == NSModalResponseOK) {
            dataSource = [[[[[_conversationController conversationWebView] mainFrame] DOMDocument] webArchive] mainResource];
            
            archive = [[WebArchive alloc]
                       initWithMainResource:dataSource
                       subresources:nil
                       subframeArchives:nil];
            
            [[archive data] writeToFile:[[savePanel URL] path] atomically:YES];
        }
    }];
}




- (IBAction)revealInUserList:(id)sender {
	WCUser				*user;
	WCError				*error;
	WDConversation		*conversation;
	
	conversation = [self _selectedConversation];
	
	if(!conversation)
		return;
	
	user = [conversation user];
	
	if(user) {
		[[WCPublicChat publicChat] selectChatController:[[conversation connection] chatController]];
		[[[conversation connection] chatController] selectUser:user];
		[[WCPublicChat publicChat] showWindow:self];
	} else {
		error = [WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientUserNotFound];
		[[conversation connection] triggerEvent:WCEventsError info1:error];
		[[error alert] beginSheetModalForWindow:[self window]];
	}
}


- (IBAction)markAsRead:(id)sender {
    WDMessagesNode      *selectedNode;
    WDConversation      *conversation;
    
    selectedNode = [self _selectedNode];
    
    if([selectedNode isKindOfClass:[WDConversation class]]) {
        conversation = (WDConversation *)selectedNode;
        
        if([conversation isUnread]) {
            [conversation setNumberOfUnreadsValue:0];
        } else {
            NSUInteger unreads = [[conversation messages] count];
            [conversation setNumberOfUnreadsValue:unreads];
        }
    }
    
    [[WCDatabaseController sharedController] save];
    [[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification object:self];
}




- (IBAction)deleteConversation:(id)sender {
	NSAlert				*alert;
	WDConversation		*conversation;
	
	conversation = [self _selectedConversation];
	
	if(!conversation)
		return;
	
	alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:[NSSWF:NSLS(@"Are you sure you want to delete the conversation with \u201c%@\u201d?", @"Delete conversation dialog title"), [conversation nick]]];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete conversation dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete board button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete board button title")];
	
    
    [alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteConversationAlertDidEnd:returnCode:contextInfo:)
						contextInfo:[conversation retain]];
    
    
    
}



- (void)deleteConversationAlertDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WDConversation		*conversation = contextInfo;
	
	if(returnCode == NSAlertFirstButtonReturn) {
		
        [[WCDatabaseController context] deleteObject:conversation];
        [[WCDatabaseController sharedController] save];
        
		[_conversationsOutlineView reloadData];
		
		[self _updateSelectedConversation];
		[self _validate];
        
        [_conversationController reloadData];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
	}
	
	[conversation release];
}



- (IBAction)deleteMessage:(id)sender {
	NSAlert				*alert;
	WDMessage           *message;
	
	message = [self _selectedMessage];
	
	if(!message)
		return;
    
	alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:NSLS(@"Are you sure you want to delete this message?", @"Delete message dialog title")];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete message dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete message button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete message button title")];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteMessageAlertDidEnd:returnCode:contextInfo:)
						contextInfo:[message retain]];}


- (void)deleteMessageAlertDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WDMessage		*message = contextInfo;
	
	if(returnCode == NSAlertFirstButtonReturn) {
		
        [[WCDatabaseController context] deleteObject:message];
        [[WCDatabaseController sharedController] save];
        
		[_conversationsOutlineView reloadData];
		
		[self _updateSelectedConversation];
		[self _validate];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
	}
	
	[message release];
}


- (IBAction)conversationsFilters:(id)sender {
    [self _filterConversations];
}



- (IBAction)conversationsSearch:(id)sender {
    [self _filterConversations];
}




#pragma mark -

- (void)menuNeedsUpdate:(NSMenu *)menu {
    WDMessagesNode      *node;
    WDConversation      *conversation;
    WDMessage           *message;
    NSMenuItem          *item;
    
    if(menu == [_conversationPopUpButton menu]) {
        node = [self _selectedNode];
        
        [menu removeAllItems];
        
        [menu addItem:[NSMenuItem itemWithTitle:@"" image:[NSImage imageNamed:@"NSActionTemplate"]]];
        
        if([node isKindOfClass:[WDConversation class]]) {
            conversation = (WDConversation *)node;
            
            if([conversation isUnread]) {
                item = [menu addItemWithTitle:NSLS(@"Mark As Read", @"Mark as read menu item") action:@selector(markAsRead:) keyEquivalent:@""];
            } else {
                item = [menu addItemWithTitle:NSLS(@"Mark As Unread", @"Mark as unread menu item") action:@selector(markAsRead:) keyEquivalent:@""];
            }
            
            [menu addItem:[NSMenuItem separatorItem]];
            
            item = [menu addItemWithTitle:NSLS(@"Delete Conversation", @"Delete Conversation menu item") action:@selector(deleteConversation:) keyEquivalent:@""];
            [item setTarget:self];
            
            [menu addItem:[NSMenuItem separatorItem]];
            
            item = [menu addItemWithTitle:NSLS(@"Reveal In User List", @"Reveal In User List menu item") action:@selector(revealInUserList:) keyEquivalent:@""];
            [item setTarget:self];
        }
        else if([node isKindOfClass:[WDMessage class]]) {
            message = (WDMessage *)node;
            
            if([message unreadValue]) {
                item = [menu addItemWithTitle:NSLS(@"Mark As Read", @"Mark as read menu item") action:@selector(markAsRead:) keyEquivalent:@""];
                [item setTarget:self];
            } else {
                item = [menu addItemWithTitle:NSLS(@"Mark As Unread", @"Mark as unread menu item") action:@selector(markAsRead:) keyEquivalent:@""];
                [item setTarget:self];
            }
            [item setTarget:self];
            
            [menu addItem:[NSMenuItem separatorItem]];
            
            item = [menu addItemWithTitle:NSLS(@"Delete Message", @"Delete message menu item") action:@selector(deleteMessage:) keyEquivalent:@""];
            [item setTarget:self];
        }
    }
}


- (IBAction)showEmoticons:(id)sender {
    [[WCEmoticonViewController emoticonController] setDelegate:self];
    [[WCEmoticonViewController emoticonController] popoverWithSender:sender
                                                            textField:_messageTextField];
}




#pragma mark -

- (void)emoticonViewController:(WCEmoticonViewController *)controller didInsertEmoticon:(WIEmoticon *)emoticon inControl:(NSControl *)control {
    if(control == _messageTextField) {
        NSLog(@"didInsertEmoticon");
        [self _adjustMessageTextFieldHeight];
    }
}







#pragma mark -

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView     *view;
    NSTreeNode          *node = item;
    
    if(outlineView == _conversationsOutlineView) {
        if([node.representedObject isKindOfClass:[WDConversation class]]) {
            view = [outlineView makeViewWithIdentifier:@"ConversationCell" owner:outlineView];
        }
        else if([node.representedObject isKindOfClass:[WDMessage class]]) {
            view = [outlineView makeViewWithIdentifier:@"MessageCell" owner:outlineView];
        }
    }
    
    return view;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    NSTreeNode          *node = item;
    
    if(outlineView == _conversationsOutlineView) {
        if([node.representedObject isKindOfClass:[WDConversation class]]) {
            return 47.0f;
        } else if([node.representedObject isKindOfClass:[WDMessage class]]) {
            return 28.0f;
        }
    }
    return [outlineView rowHeight];
}


- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if([self _selectedConversation] == [self _selectedNode])
        return;
    
    [self _updateSelectedConversation];
    [self _adjustMessageTextFieldHeight];
    
    if(!_sorting) {
        [_conversationController reloadData];
    }
    
	[self _validate];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return NO;
}





#pragma mark -

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    
    if(splitView == _conversationsSplitView) {
        if(view == [[_conversationsSplitView subviews] objectAtIndex:0])
            return NO;
    }
    else if(splitView == _messagesSplitView) {
        if(view == [[_messagesSplitView subviews] objectAtIndex:1])
            return NO;
    }
    
    return YES;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
	if(splitView == _conversationsSplitView)
		return proposedMax - 140.0;
	else if(splitView == _messagesSplitView)
		return proposedMax - 31.0;
	
	return proposedMax;
}



- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
	if(splitView == _conversationsSplitView)
		return proposedMin + 140.0;
	else if(splitView == _messagesSplitView)
		return proposedMin + 31.0;
	
	return proposedMin;
}



- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
	return NO;
}





#pragma mark -

-(void)controlTextDidChange:(NSNotification *)obj {
    [self _adjustMessageTextFieldHeight];
}


- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)selector {
    if(control == _messageTextField) {
		if(selector == @selector(insertNewline:)) {
			if([[_messageTextField stringValue] length] > 0)
				[self _sendMessage];
            
			 [self _adjustMessageTextFieldHeight];
            
            return YES;
		}
		else if(selector == @selector(insertNewlineIgnoringFieldEditor:)) {
			[fieldEditor insertNewline:self];
            [self _adjustMessageTextFieldHeight];
            
			return YES;
		}
		else if(selector == @selector(moveToBeginningOfDocument:) ||
				selector == @selector(moveToEndOfDocument:) ||
				selector == @selector(scrollToBeginningOfDocument:) ||
				selector == @selector(scrollToEndOfDocument:) ||
				selector == @selector(scrollPageUp:) ||
				selector == @selector(scrollPageDown:)) {
			[[_conversationController conversationWebView] performSelector:selector withObject:self];
			
			return YES;
		}
	}
    return NO;
}


- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
	if(textView == _broadcastTextView) {
		if(selector == @selector(insertNewline:)) {
			if([[NSApp currentEvent] character] == NSEnterCharacter) {
				[self submitSheet:textView];
                
				return YES;
			}
		}
	}
    
	return NO;
}






#pragma mark -

- (NSManagedObjectContext *)managedObjectContext {
    return [WCDatabaseController context];
}


@end
