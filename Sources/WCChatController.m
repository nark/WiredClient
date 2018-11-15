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

#import "WCAccount.h"
#import "WCAccountsController.h"
#import "WCApplicationController.h"
#import "WCChatController.h"
#import "WCChatWindow.h"
#import "WCErrorQueue.h"
#import "WCMessages.h"
#import "WCPreferences.h"
#import "WCStats.h"
#import "WCTopic.h"
#import "WCUser.h"
#import "WCUserCell.h"
#import "WCUserInfo.h"
#import "WCFiles.h"
#import "WCFile.h"
#import "WCTransfers.h"
#import "WCBoards.h"
#import "WCBoard.h"
#import "WCPublicChat.h"
#import "WCUserTableCellView.h"
#import "WCEmoticonViewController.h"
#import "WCEmoticonPreferences.h"
#import "iTunes.h"


#define WCPublicChatID											1

#define WCLastChatFormat										@"WCLastChatFormat"
#define WCLastChatEncoding										@"WCLastChatEncoding"

#define WCChatPrepend											13
#define WCChatLimit												4096


NSString * const WCChatUserAppearedNotification					= @"WCChatUserAppearedNotification";
NSString * const WCChatUserDisappearedNotification				= @"WCChatUserDisappearedNotification";
NSString * const WCChatUserNickDidChangeNotification			= @"WCChatUserNickDidChangeNotification";
NSString * const WCChatSelfWasKickedFromPublicChatNotification	= @"WCChatSelfWasKickedFromPublicChatNotification";
NSString * const WCChatSelfWasBannedNotification				= @"WCChatSelfWasBannedNotification";
NSString * const WCChatSelfWasDisconnectedNotification			= @"WCChatSelfWasDisconnectedNotification";
NSString * const WCChatRegularChatDidAppearNotification			= @"WCChatRegularChatDidAppearNotification";
NSString * const WCChatHighlightedChatDidAppearNotification		= @"WCChatHighlightedChatDidAppearNotification";
NSString * const WCChatEventDidAppearNotification				= @"WCChatEventDidAppearNotification";

NSString * const WCChatHighlightColorKey						= @"WCChatHighlightColorKey";

NSString * const WCUserPboardType								= @"WCUserPboardType";

enum _WCChatFormat {
	WCChatPlainText,
	WCChatRTF,
	WCChatRTFD,
};
typedef enum _WCChatFormat					WCChatFormat;


@interface WCChatController(Private)

- (void)_updatePreferences;
- (void)_updateSaveChatForPanel:(NSSavePanel *)savePanel;
- (void)_adjustChatInputTextFieldHeight;

- (void)_setTopic:(WCTopic *)topic;

- (void)_printTimestamp;
- (void)_printTopic;
- (void)_printUserJoin:(WCUser *)user;
- (void)_printUserLeave:(WCUser *)user;
- (void)_printUserChange:(WCUser *)user nick:(NSString *)nick;
- (void)_printUserChange:(WCUser *)user status:(NSString *)status;
- (void)_printUserKick:(WCUser *)victim by:(WCUser *)killer message:(NSString *)message;
- (void)_printUserBan:(WCUser *)victim message:(NSString *)message;
- (void)_printUserBanned:(WCUser *)victim expirationDate:(NSDate *)date;
- (void)_printUserDisconnect:(WCUser *)victim message:(NSString *)message;
- (void)_printChat:(NSString *)chat by:(WCUser *)user;
- (void)_printActionChat:(NSString *)chat by:(WCUser *)user;
- (void)_printHTML:(NSString *)html by:(WCUser *)user;

- (void)_sendImage:(NSURL *)url;
- (void)_sendYouTube:(NSURL *)url;
- (void)_sendiTunes;

- (NSArray *)_commands;
- (BOOL)_runCommand:(NSString *)command;

- (NSString *)_stringByCompletingString:(NSString *)string;
- (void)_applyChatAttributesToAttributedString:(NSMutableAttributedString *)attributedString;
- (void)_applyHTMLTagsForHighlightsToMutableString:(NSMutableString *)mutableString;
- (NSColor *)_highlightColorForChat:(NSString *)chat;

- (NSDictionary *)_currentTheme;
- (void)_loadTheme:(NSDictionary *)theme withTemplate:(WITemplateBundle *)template;

@end


@implementation WCChatController(Private)

- (void)_updatePreferences {
	NSMutableArray		*highlightPatterns, *highlightColors;
	NSEnumerator		*enumerator;
	NSDictionary		*highlight;
	
	highlightPatterns	= [NSMutableArray array];
	highlightColors		= [NSMutableArray array];
	
	enumerator = [[[WCSettings settings] objectForKey:WCHighlights] objectEnumerator];
	
	while((highlight = [enumerator nextObject])) {
		[highlightPatterns addObject:[highlight objectForKey:WCHighlightsPattern]];
		[highlightColors addObject:WIColorFromString([highlight objectForKey:WCHighlightsColor])];
	}
	
	if(![highlightPatterns isEqualToArray:_highlightPatterns] || ![highlightColors isEqualToArray:_highlightColors]) {
		[_highlightPatterns setArray:highlightPatterns];
		[_highlightColors setArray:highlightColors];
	}
	
	WebPreferences *pref = [WebPreferences standardPreferences];
	[pref setAllowsAnimatedImages:[[WCSettings settings] boolForKey:WCChatAnimatedImagesEnabled]];
	[pref setAllowsAnimatedImageLooping:[[WCSettings settings] boolForKey:WCChatAnimatedImagesEnabled]];
	[_chatOutputWebView setPreferences:pref];
}



- (void)_updateSaveChatForPanel:(NSSavePanel *)savePanel {
	WIChatLogType		type;
	
	type = [_saveChatFileFormatPopUpButton indexOfSelectedItem];
    
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:[[WIChatLogController typeExtentions] objectAtIndex:type]]];
}


- (void)_adjustChatInputTextFieldHeight {
    [_chatInputTextField adjustHeightForTopView:_chatOutputWebView bottomView:[_chatInputTextField superview]];
    [_chatOutputWebView scrollToBottom];
}




#pragma mark -

- (void)_setTopic:(WCTopic *)topic {
	[topic retain];
	[_topic release];
	
	_topic = topic;
	
	if([[_topic topic] length] > 0) {
        
        NSString *topicString = [NSSWF:@"%@ - by %@ - %@", [_topic topic], [_topic nick], [_topicDateFormatter stringFromDate:[_topic date]]];
        
		[_topicTextField setToolTip:topicString];
		[_topicTextField setStringValue:topicString];
	} else {
		[_topicTextField setToolTip:NULL];
		[_topicTextField setStringValue:@""];
	}
}





#pragma mark -

- (void)_printTimestamp {
	NSDate			*date;
	NSTimeInterval	interval;
	
	if(!_timestamp)
		_timestamp = [[NSDate date] retain];
	
	interval = [[[WCSettings settings] objectForKey:WCChatTimestampChatInterval] doubleValue];
	date = [NSDate dateWithTimeIntervalSinceNow:-interval];
	
	if([date compare:_timestamp] == NSOrderedDescending) {
		[self printEvent:[_timestampDateFormatter stringFromDate:[NSDate date]]];
		
		[_timestamp release];
		_timestamp = [[NSDate date] retain];
	}
}




- (void)_printTopic {
	[self printEvent:[NSSWF: NSLS(@"%@ changed topic to %@", @"Topic changed (nick, topic)"),
                      [_topic nick], [_topic topic]]];
}



- (void)_printUserJoin:(WCUser *)user {
	[self printEvent:[NSSWF:NSLS(@"%@ has joined", @"User has joined message (nick)"),
                      [user nick]]];
}



- (void)_printUserLeave:(WCUser *)user {
	[self printEvent:[NSSWF:NSLS(@"%@ has left", @"User has left message (nick)"),
                      [user nick]]];
}



- (void)_printUserChange:(WCUser *)user nick:(NSString *)nick {
	[self printEvent:[NSSWF:NSLS(@"%@ is now known as %@", @"User rename message (oldnick, newnick)"),
                      [user nick], nick]];
}



- (void)_printUserChange:(WCUser *)user status:(NSString *)status {
	[self printEvent:[NSSWF:NSLS(@"%@ changed status to %@", @"User status changed message (nick, status)"),
                      [user nick], status]];
}



- (void)_printUserKick:(WCUser *)victim by:(WCUser *)killer message:(NSString *)message {
	if([message length] > 0) {
		[self printEvent:[NSSWF:NSLS(@"%@ was kicked by %@ (%@)", @"User kicked message (victim, killer, message)"),
                          [victim nick], [killer nick], message]];
	} else {
		[self printEvent:[NSSWF:NSLS(@"%@ was kicked by %@", @"User kicked message (victim, killer)"),
                          [victim nick], [killer nick]]];
	}
}



- (void)_printUserBan:(WCUser *)victim message:(NSString *)message {
	if([message length] > 0) {
		[self printEvent:[NSSWF:NSLS(@"%@ was banned (%@)", @"User banned message (victim, message)"),
                          [victim nick], message]];
	} else {
		[self printEvent:[NSSWF:NSLS(@"%@ was banned", @"User banned message (victim)"),
                          [victim nick]]];
	}
}


- (void)_printUserBanned:(WCUser *)victim expirationDate:(NSDate *)date {
    if(date) {
        [self printEvent:[NSSWF:NSLS(@"Your are banned from this server until %@", @"User banned message (expiration date)"), date]];
    } else {
        [self printEvent:[NSSWF:NSLS(@"Your are indefinitely banned from this server", @"User banned message")]];
    }
}


- (void)_printUserDisconnect:(WCUser *)victim message:(NSString *)message {
	if([message length] > 0) {
		[self printEvent:[NSSWF:NSLS(@"%@ was disconnected (%@)", @"User disconnected message (victim, message)"),
                          [victim nick], message]];
	} else {
		[self printEvent:[NSSWF:NSLS(@"%@ was disconnected", @"User disconnected message (victim)"),
                          [victim nick]]];
	}
}



- (void)_printChat:(NSString *)chat by:(WCUser *)user {
    WIChatLogController     *logController;
	NSBundle                *template;
	NSString                *nick, *formattedDate, *formattedLogs;
	NSMutableString         *mutableOutput;
    NSDictionary            *jsonProxy;
	BOOL                    timestamp;
	
    chat            = [[chat componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@"\n"];
	mutableOutput   = [NSMutableString stringWithString:chat];
    logController   = [[WCApplicationController sharedController] logController];
	timestamp		= [[[self connection] theme] boolForKey:WCThemesChatTimestampEveryLine];
	nick			= [user nick];
	template		= [[WCSettings settings] templateBundleWithIdentifier:[[[self connection] theme] objectForKey:WCThemesTemplate]];
	formattedDate	= (timestamp) ? [_timestampEveryLineDateFormatter stringFromDate:[NSDate date]] : @"";
	formattedLogs   = [NSSWF:@"[%@]\t%@: %@\n", [_timestampEveryLineDateFormatter stringFromDate:[NSDate date]], nick, chat];
    
    [[self class] applyHTMLEscapingToMutableString:mutableOutput];
    
    [self _applyHTMLTagsForHighlightsToMutableString:mutableOutput];

	if([[[self connection] theme] boolForKey:WCThemesShowSmileys])
		[[self class] applyHTMLTagsForSmileysToMutableString:mutableOutput];
    
    [[self class] applyHTMLTagsForURLToMutableString:mutableOutput];
    
    jsonProxy = [NSDictionary dictionaryWithObjectsAndKeys:
                 formattedDate, @"timestamp",
                 nick,          @"nick",
                 mutableOutput, @"message", nil];
    
    [_chatOutputWebView stringByEvaluatingJavaScriptFromString:
        [NSSWF:@"printMessage(%@);", [_jsonWriter stringWithObject:jsonProxy]]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsPlainTextEnabled])
		[logController appendChatLogAsPlainText:formattedLogs
                              forConnectionName:[[self connection] name]];
}



- (void)_printActionChat:(NSString *)chat by:(WCUser *)user {
    WIChatLogController     *logController;
	NSBundle                *template;
	NSString                *formattedDate, *formattedNick, *formattedLogs;
	NSMutableString         *mutableOutput;
    NSDictionary            *jsonProxy;
	BOOL                    timestamp;
	
    chat            = [[chat componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@"\n"];
    mutableOutput	= [NSMutableString stringWithString:chat];
    logController   = [[WCApplicationController sharedController] logController];
	template		= [[WCSettings settings] templateBundleWithIdentifier:[[[self connection] theme] objectForKey:WCThemesTemplate]];
	timestamp		= [[[self connection] theme] boolForKey:WCThemesChatTimestampEveryLine];
	formattedDate	= (timestamp) ? [_timestampEveryLineDateFormatter stringFromDate:[NSDate date]] : @"";
    formattedNick   = [NSSWF:@" *** %@", [user nick]];
	formattedLogs   = [NSSWF:@"[%@]\t*** %@ %@\n", [_timestampEveryLineDateFormatter stringFromDate:[NSDate date]], [user nick], chat];
	
	if([[[self connection] theme] boolForKey:WCThemesShowSmileys])
		[[self class] applyHTMLTagsForSmileysToMutableString:mutableOutput];
	
    [self _applyHTMLTagsForHighlightsToMutableString:mutableOutput];
    [[self class] applyHTMLTagsForURLToMutableString:mutableOutput];
    
    jsonProxy = [NSDictionary dictionaryWithObjectsAndKeys:
                 @"true", @"action",
                 formattedDate, @"timestamp",
                 formattedNick, @"nick",
                 mutableOutput, @"message", nil];
    
    [_chatOutputWebView stringByEvaluatingJavaScriptFromString:
        [NSSWF:@"printMessage(%@);", [_jsonWriter stringWithObject:jsonProxy]]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsPlainTextEnabled])
		[logController appendChatLogAsPlainText:formattedLogs forConnectionName:[[self connection] name]];
}





- (void)_printHTML:(NSString *)html by:(WCUser *)user {
    WIChatLogController     *logController;
	NSBundle                *template;
	NSString                *nick, *formattedDate, *formattedLogs;
    NSDictionary            *jsonProxy;
	BOOL                    timestamp;

    logController   = [[WCApplicationController sharedController] logController];
    timestamp		= [[[self connection] theme] boolForKey:WCThemesChatTimestampEveryLine];
	nick			= [user nick];
	template		= [[WCSettings settings] templateBundleWithIdentifier:[[[self connection] theme] objectForKey:WCThemesTemplate]];
	formattedDate	= (timestamp) ? [_timestampEveryLineDateFormatter stringFromDate:[NSDate date]] : @"";
	formattedLogs   = [NSSWF:@"[%@]\t*** %@ %@\n", [_timestampEveryLineDateFormatter stringFromDate:[NSDate date]], [user nick], html];
    
    jsonProxy = [NSDictionary dictionaryWithObjectsAndKeys:
                 formattedDate, @"timestamp",
                 nick, @"nick",
                 html, @"message", nil];
    
    [_chatOutputWebView stringByEvaluatingJavaScriptFromString:
     [NSSWF:@"printMessage(%@);", [_jsonWriter stringWithObject:jsonProxy]]];
    
    if([[WCSettings settings] boolForKey:WCChatLogsPlainTextEnabled])
        [logController appendChatLogAsPlainText:[NSSWF:@"[%@]\t%@: %@\n", formattedDate, nick, html]
                              forConnectionName:[[self connection] name]];
}






#pragma mark -



- (void)_sendiTunes {
	iTunesApplication	*iTunes;
	WIP7Message			*message;
	WCUser				*user;
	NSString			*chat, *name, *artist, *album;
	
	user	= [self userWithUserID:[[self connection] userID]];
	iTunes	= [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	
	if([iTunes isRunning] && [iTunes currentTrack]) {
		
		name		= [[iTunes currentTrack] name];
		artist		= [[iTunes currentTrack] artist];
		album		= [[iTunes currentTrack] album];
		
        if(!name || [name length] <= 0)
			name	= NSLS(@"Unknow Track", @"Unknow Track");
		
		if(!artist || [artist length] <= 0)
			artist	= NSLS(@"Unknow Artist", @"Unknow Artist");
		
		if(!album || [album length] <= 0)
			album	= NSLS(@"Unknow Album", @"Unknow Album");
		
		chat = [NSSWF:NSLS(@"is listening to %@ performed by %@ in album %@.", @"Now playing message"),
				name,
				artist,
				album];
		
		if(chat && [chat length] > 0) {
			message = [WIP7Message messageWithName:@"wired.chat.send_me" spec:WCP7Spec];
			[message setUInt32:[self chatID] forName:@"wired.chat.id"];
			[message setString:chat forName:@"wired.chat.me"];
			[[self connection] sendMessage:message];
		}
	}
}



- (void)_sendImage:(NSURL *)url {
	NSString		*html;
	WIP7Message		*message;
    
	if([[url scheme] containsSubstring:@"http"]) {
		html = [NSSWF:@"<a class='chat-media-frame' href='%@'><img src='%@' alt='' /></a>", [url absoluteString], [url absoluteString]];
	} else {
		html = nil;
	}
    
	if(html && [html length] > 0) {
		message = [WIP7Message messageWithName:@"wired.chat.send_say" spec:WCP7Spec];
		[message setUInt32:[self chatID] forName:@"wired.chat.id"];
		[message setString:html forName:@"wired.chat.say"];
		[[self connection] sendMessage:message];
	}
}
    
    
- (void)_sendLocalImage:(NSURL *)url {
    NSString            *html;
    NSString            *base64ImageString;
    NSData              *imageData;
    
    imageData = [NSData dataWithContentsOfURL:url];
    base64ImageString = [imageData base64EncodedString];
    
    html = [NSSWF:@"<img src='data:image/png;base64, %@'/>", base64ImageString];
    
    if(html && [html length] > 0) {
        [self sendChat:html];
    }
}


- (void)_sendYouTube:(NSURL *)url {
	NSString		*html = nil, *videoID;
	NSArray			*parameters;
	WIP7Message		*message;
	   
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
		
		//NSLog(@"videoID : %@", videoID);
		
		if(videoID)
			html = [NSSWF:@"<div class='chat-media-frame'><iframe width='300' height='233' src='http://www.youtube.com/embed/%@' frameborder='0' allowfullscreen></iframe></div>", videoID];
	} else {
		html = nil;
	}
	
	if(html && [html length] > 0) {
		message = [WIP7Message messageWithName:@"wired.chat.send_me" spec:WCP7Spec];
		[message setUInt32:[self chatID] forName:@"wired.chat.id"];
		[message setString:html forName:@"wired.chat.me"];
		[[self connection] sendMessage:message];
	}
}







#pragma mark -

- (NSArray *)_commands {
	return [NSArray arrayWithObjects:
            @"/help",
            @"/me",
            @"/exec",
            @"/nick",
            @"/status",
            @"/stats",
            @"/clear",
            @"/topic",
            @"/broadcast",
            @"/ping",
            @"/afk",
            @"/img",
            @"/html",
            @"/itunes",
            @"/youtube",
            @"/utube",
            NULL];
}


- (BOOL)_runCommand:(NSString *)string {
	NSString		*command, *argument;
	WIP7Message		*message;
	NSRange			range;
	NSUInteger		transaction;
	
	range = [string rangeOfString:@" "];
	
	if(range.location == NSNotFound) {
		command = string;
		argument = @"";
	} else {
		command = [string substringToIndex:range.location];
		argument = [string substringFromIndex:range.location + 1];
	}
	
	if([command isEqualToString:@"/me"] && [argument length] > 0) {
		if([argument length] > WCChatLimit)
			argument = [argument substringToIndex:WCChatLimit];
		
		message = [WIP7Message messageWithName:@"wired.chat.send_me" spec:WCP7Spec];
		[message setUInt32:[self chatID] forName:@"wired.chat.id"];
		[message setString:argument forName:@"wired.chat.me"];
		[[self connection] sendMessage:message];
		
		[[WCStats stats] addUnsignedLongLong:[argument length] forKey:WCStatsChat];
		
		return YES;
	}
	else if([command isEqualToString:@"/exec"] && [argument length] > 0) {
		NSString			*output;
		
		output = [[self class] outputForShellCommand:argument];
		
		if(output && [output length] > 0) {
			if([output length] > WCChatLimit)
				output = [output substringToIndex:WCChatLimit];
			
			message = [WIP7Message messageWithName:@"wired.chat.send_say" spec:WCP7Spec];
			[message setUInt32:[self chatID] forName:@"wired.chat.id"];
			[message setString:output forName:@"wired.chat.say"];
			[[self connection] sendMessage:message];
		}
		
		return YES;
	}
	else if(([command isEqualToString:@"/nick"] ||
			 [command isEqualToString:@"/n"]) && [argument length] > 0) {
		message = [WIP7Message messageWithName:@"wired.user.set_nick" spec:WCP7Spec];
		[message setString:argument forName:@"wired.user.nick"];
		[[self connection] sendMessage:message];
		
		return YES;
	}
	else if([command isEqualToString:@"/status"] || [command isEqualToString:@"/s"]){
		message = [WIP7Message messageWithName:@"wired.user.set_status" spec:WCP7Spec];
		[message setString:argument forName:@"wired.user.status"];
		[[self connection] sendMessage:message];
		
		return YES;
	}
	else if([command isEqualToString:@"/stats"]) {
		[self stats:self];
		
		return YES;
	}
	else if([command isEqualToString:@"/clear"]) {
		[self clearChat];
		
		return YES;
	}
	else if([command isEqualToString:@"/topic"]) {
		message = [WIP7Message messageWithName:@"wired.chat.set_topic" spec:WCP7Spec];
		[message setUInt32:[self chatID] forName:@"wired.chat.id"];
		[message setString:argument forName:@"wired.chat.topic.topic"];
		[[self connection] sendMessage:message];
		
		return YES;
	}
	else if([command isEqualToString:@"/broadcast"] && [argument length] > 0) {
		message = [WIP7Message messageWithName:@"wired.message.send_broadcast" spec:WCP7Spec];
		[message setString:argument forName:@"wired.message.broadcast"];
		[[self connection] sendMessage:message];
		
		return YES;
	}
	else if([command isEqualToString:@"/ping"]) {
		message = [WIP7Message messageWithName:@"wired.send_ping" spec:WCP7Spec];
		transaction = [[self connection] sendMessage:message fromObserver:self selector:@selector(wiredSendPingReply:)];
		
		[_pings setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]]
				   forKey:[NSNumber numberWithUnsignedInt:transaction]];
		
		return YES;
	}
	else if([command isEqualToString:@"/afk"]) {
		message = [WIP7Message messageWithName:@"wired.user.set_idle" spec:WCP7Spec];
		[message setBool:YES forName:@"wired.user.idle"];
		[[self connection] sendMessage:message];
		
		return YES;
	}
	else if([command isEqualToString:@"/img"]) {
		if(argument && [argument length] > 0) {
			NSURL *url = [NSURL URLWithString:argument];
			
			if(url)
				[self _sendImage:url];
		}
		
		return YES;
	}
	else if([command isEqualToString:@"/html"]) {
		if(argument && [argument length] > 0) {
			if([[self class] checkHTMLRestrictionsForString:argument]) {
				message = [WIP7Message messageWithName:@"wired.chat.send_say" spec:WCP7Spec];
				[message setUInt32:[self chatID] forName:@"wired.chat.id"];
				[message setString:argument forName:@"wired.chat.say"];
				[[self connection] sendMessage:message];
			}
		}
		return YES;
	}
	else if([command isEqualToString:@"/itunes"]) {
		[self _sendiTunes];
		
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

- (NSString *)_stringByCompletingString:(NSString *)string {
	NSEnumerator	*enumerator, *setEnumerator;
	NSArray			*nicks, *commands, *set, *matchingSet = NULL;
	NSString		*match, *prefix = NULL;
	NSUInteger		matches = 0;
	
	nicks		= [self nicks];
	commands	= [self _commands];
	enumerator	= [[NSArray arrayWithObjects:nicks, commands, NULL] objectEnumerator];
	
	while((set = [enumerator nextObject])) {
		setEnumerator = [set objectEnumerator];
		
		while((match = [setEnumerator nextObject])) {
			if([match rangeOfString:string options:NSCaseInsensitiveSearch].location == 0) {
				if(matches == 0) {
					prefix = match;
					matches = 1;
				} else {
					prefix = [prefix commonPrefixWithString:match options:NSCaseInsensitiveSearch];
					
					if([prefix length] < [match length])
						matches++;
				}
				
				matchingSet = set;
			}
		}
	}
	
	if(matches > 1)
		return prefix;
	
	if(matches == 1) {
		if(matchingSet == nicks)
			return [prefix stringByAppendingString:[[WCSettings settings] objectForKey:WCChatTabCompleteNicksString]];
		else if(matchingSet == commands)
			return [prefix stringByAppendingString:@" "];
	}
	
	return string;
}



- (void)_applyChatAttributesToAttributedString:(NSMutableAttributedString *)attributedString {
	static NSCharacterSet		*whitespaceSet, *nonWhitespaceSet, *nonTimestampSet, *nonHighlightSet;
	NSMutableCharacterSet		*characterSet;
	NSScanner					*scanner;
	NSString					*word, *chat;
	NSColor						*color;
	NSRange						range, nickRange;
    
	if(!whitespaceSet) {
		whitespaceSet		= [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
		nonWhitespaceSet	= [[whitespaceSet invertedSet] retain];
		
		characterSet		= [[NSMutableCharacterSet decimalDigitCharacterSet] mutableCopy];
		[characterSet addCharactersInString:@":."];
		[characterSet invert];
		nonTimestampSet		= [characterSet copy];
		[characterSet release];
		
		nonHighlightSet		= [[NSCharacterSet alphanumericCharacterSet] retain];
	}
	
	range = NSMakeRange(0, [attributedString length]);
	
	[attributedString addAttribute:NSForegroundColorAttributeName value:_chatColor range:range];
	[attributedString addAttribute:NSFontAttributeName value:_chatFont range:range];
	
	scanner = [NSScanner scannerWithString:[attributedString string]];
	[scanner setCharactersToBeSkipped:NULL];
    
	while(![scanner isAtEnd]) {
		[scanner skipUpToCharactersFromSet:nonWhitespaceSet];
		range.location = [scanner scanLocation];
		
		if(![scanner scanUpToCharactersFromSet:whitespaceSet intoString:&word])
			break;
		
		range.length = [scanner scanLocation] - range.location;
		
		if([word rangeOfCharacterFromSet:nonTimestampSet].location == NSNotFound ||
		   [word isEqualToString:@"PM"] || [word isEqualToString:@"AM"]) {
			[attributedString addAttribute:NSForegroundColorAttributeName value:_timestampEveryLineColor range:range];
			
			continue;
		}
		
		if([word isEqualToString:@"<<<"]) {
			if([scanner scanUpToString:@">>>" intoString:NULL]) {
				range.length = [scanner scanLocation] - range.location + 3;
                
				[attributedString addAttribute:NSForegroundColorAttributeName value:_eventsColor range:range];
				
				[scanner scanUpToString:@"\n" intoString:NULL];
                
				continue;
			}
		}
		
		if([word isEqualToString:@"*"] || [word isEqualToString:@"***"]) {
			[scanner scanUpToString:@"\n" intoString:NULL];
            
			continue;
		}
		
		nickRange = range;
        
		if([word hasSuffix:@":"]) {
			nickRange.length--;
            
			if(![scanner isAtEnd])
				[scanner setScanLocation:[scanner scanLocation] + 1];
		} else {
			[scanner scanUpToString:@":" intoString:NULL];
			
			nickRange.length = [scanner scanLocation] - range.location;
            
			if(![scanner isAtEnd])
                [scanner setScanLocation:[scanner scanLocation] + 1];
		}
		
		if([scanner scanUpToString:@"\n" intoString:&chat]) {
			color = [self _highlightColorForChat:chat];
			
			if(color != NULL)
				[attributedString addAttribute:NSForegroundColorAttributeName value:color range:nickRange];
		}
	}
}


- (void)_applyHTMLTagsForHighlightsToMutableString:(NSMutableString *)mutableString; {
	NSColor		*color;
	NSString	*string, *highlightString;
	NSRange		range;
	
	color		= [self _highlightColorForChat:mutableString];
	
	if(!color)
		return;
	
	for(NSString *pattern in _highlightPatterns) {
		range	= [mutableString rangeOfString:pattern options:NSCaseInsensitiveSearch];
		
		if(range.location == NSNotFound)
			return;
		
		string	= [mutableString substringWithRange:range];
        
		if(string) {
			highlightString	= [NSSWF:@"<span style='color:%@;'>%@</span>", [NSSWF:@"#%.6lx", (unsigned long)[color HTMLValue]], string];
			[mutableString replaceOccurrencesOfString:string withString:highlightString];
		}
	}
}



#pragma mark -

- (NSColor *)_highlightColorForChat:(NSString *)chat {
	NSCharacterSet		*alphanumericCharacterSet;
	NSRange				range;
	NSUInteger			i, count, length, index;
	
	alphanumericCharacterSet	= [NSCharacterSet alphanumericCharacterSet];
	length						= [chat length];
	count						= [_highlightPatterns count];
	
	for(i = 0; i < count; i++) {
		range = [chat rangeOfString:[_highlightPatterns objectAtIndex:i] options:NSCaseInsensitiveSearch];
        
		if(range.location != NSNotFound) {
			index = range.location + range.length;
			
			if(index == length || ![alphanumericCharacterSet characterIsMember:[chat characterAtIndex:index]])
				return [_highlightColors objectAtIndex:i];
		}
	}
	
	return NULL;
}


#pragma mark -

- (NSDictionary *)_currentTheme {
    return ([[self connection] theme] ?
            [[self connection] theme] :
            [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]]);
}

- (void)_loadTheme:(NSDictionary *)theme withTemplate:(WITemplateBundle *)template {
    NSString			*htmlPath;

	htmlPath	= [template htmlPathForType:WITemplateTypeChat];
    
	[[_chatOutputWebView preferences] setAutosaves:YES];
    [[_chatOutputWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
    
    [self themeDidChange:theme];
}

@end



@implementation WCChatController

+ (NSString *)outputForShellCommand:(NSString *)command {
	NSTask				*task;
	NSPipe				*pipe;
	NSFileHandle		*fileHandle;
	NSDictionary		*environment;
	NSData				*data;
	double				timeout = 5.0;
	
	pipe = [NSPipe pipe];
	fileHandle = [pipe fileHandleForReading];
	
	environment	= [NSDictionary dictionaryWithObject:@"/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin" forKey:@"PATH"];
	
	task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/bin/sh"];
	[task setArguments:[NSArray arrayWithObjects:@"-c", command, NULL]];
	[task setStandardOutput:pipe];
	[task setStandardError:pipe];
	[task setEnvironment:environment];
	[task launch];
	
	while([task isRunning]) {
		usleep(100000);
		timeout -= 0.1;
		
		if(timeout <= 0.0) {
			[task terminate];
			
			break;
		}
	}
	
	data = [fileHandle readDataToEndOfFile];
	
	return [NSString stringWithData:data encoding:NSUTF8StringEncoding];
}






+ (void)applyHTMLTagsForURLToMutableString:(NSMutableString *)mutableString {
	NSString			*substring;
	NSRange				range;
	
	/* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
	do {
		range = [mutableString rangeOfRegex:[NSSWF:@"(?:^|\\s)(%@)(?:\\.|,|:|\\?|!)?(?:\\s|$)", [NSString URLRegex]]
                                    options:RKLCaseless
                                    capture:1];
		
		if(range.location != NSNotFound) {
			substring = [mutableString substringWithRange:range];
			[mutableString replaceCharactersInRange:range withString:[NSSWF:@"<a href=\"%@\">%@</a>", substring, substring]];
		}
	} while(range.location != NSNotFound);
    
    /* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
	do {
		range = [mutableString rangeOfRegex:[NSSWF:@"(?:^|\\s)(%@)(?:\\.|,|:|\\?|!)?(?:\\s|$)", [NSString fileURLRegex]]
                                    options:RKLCaseless
                                    capture:1];
		
		if(range.location != NSNotFound) {
			substring = [mutableString substringWithRange:range];
			
			[mutableString replaceCharactersInRange:range withString:[NSSWF:@"<a href=\"%@\">%@</a>", substring, substring]];
		}
	} while(range.location != NSNotFound);
	
	/* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
	do {
		range = [mutableString rangeOfRegex:[NSSWF:@"(?:^|\\s)(%@)(?:\\.|,|:|\\?|!)?(?:\\s|$)", [NSString schemelessURLRegex]]
                                    options:RKLCaseless
                                    capture:1];
		
		if(range.location != NSNotFound) {
			substring = [mutableString substringWithRange:range];
			
			[mutableString replaceCharactersInRange:range withString:[NSSWF:@"<a href=\"http://%@\">%@</a>", substring, substring]];
		}
	} while(range.location != NSNotFound);
	
	/* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
	do {
		range = [mutableString rangeOfRegex:[NSSWF:@"(?:^|\\s)(%@)(?:\\.|,|:|\\?|!)?(?:\\s|$)", [NSString mailtoURLRegex]]
                                    options:RKLCaseless
                                    capture:1];
		
		if(range.location != NSNotFound) {
			substring = [mutableString substringWithRange:range];
			
			[mutableString replaceCharactersInRange:range withString:[NSSWF:@"<a href=\"mailto:%@\">%@</a>", substring, substring]];
		}
	} while(range.location != NSNotFound);
}



+ (void)applyHTMLTagsForSmileysToMutableString:(NSMutableString *)mutableString {
    __block WIEmoticon          *emoticon;
    __block NSArray             *textEquivalents;
    __block NSString            *html;
    
    textEquivalents = [[[WCPreferences preferences] emoticonPreferences] emoticonEquivalents];
    
    [textEquivalents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableString     *equivalent;
        NSRange             range;
        BOOL                match;
        
        match               = NO;
        equivalent          = [NSMutableString stringWithString:obj];
        
        [[self class] applyHTMLEscapingToMutableString:equivalent];
        
        do {
            range = [mutableString rangeOfString:equivalent options:NSCaseInsensitiveSearch];
            
            if(range.location != NSNotFound) {
                
                // is exact string
                if(range.location == 0 && range.length == mutableString.length) {
                    match = YES;
                }
                
                // has a space before
                if(!match && (mutableString.length >= range.location-1) && ([mutableString characterAtIndex:range.location-1] == ' ')) {
                    match = YES;
                }
                
                // has a return line before
                if(!match && (mutableString.length >= range.location-1) && ([mutableString characterAtIndex:range.location-1] == '\n')) {
                    match = YES;
                }
                
                // has a space after
                if(!match && (range.length < mutableString.length && range.location == 0) && ([mutableString characterAtIndex:range.location+range.length] == ' ')) {
                    match = YES;
                }
                
                if(match) {
                    emoticon = [[[WCPreferences preferences] emoticonPreferences] emoticonForEquivalent:obj];
                    
                    if(emoticon) {
                        html = [NSSWF:@"<img src=\"%@\" alt=\"%@\" />", [emoticon path], [emoticon name]];
                        [mutableString replaceCharactersInRange:range withString:html];
                    }
                }
                else {
                    stop = (BOOL*)YES;
                    return;
                }
            }
        } while(range.location != NSNotFound);
    }];
}



+ (void)applyHTMLEscapingToMutableString:(NSMutableString *)mutableString {
	[mutableString replaceOccurrencesOfString:@"&" withString:@"&#38;"];
	[mutableString replaceOccurrencesOfString:@"<" withString:@"&#60;"];
	[mutableString replaceOccurrencesOfString:@">" withString:@"&#62;"];
	[mutableString replaceOccurrencesOfString:@"\"" withString:@"&#34;"];
	[mutableString replaceOccurrencesOfString:@"\'" withString:@"&#39;"];
    [mutableString replaceOccurrencesOfString:@"\n" withString:@"<br />"];
}




+ (BOOL)checkHTMLRestrictionsForString:(NSString *)string {
	NSRange range;
	
	range = [string rangeOfString:@"<iframe" options:NSCaseInsensitiveSearch];
	
	if(range.location != NSNotFound)
		return NO;
	
	range = [string rangeOfString:@"<embed" options:NSCaseInsensitiveSearch];
	
	if(range.location != NSNotFound)
		return NO;
	
	return YES;
}


+ (NSString *)stringByDecomposingSmileyAttributesInAttributedString:(NSAttributedString *)attributedString {
	if(![attributedString containsAttachments])
		return [[[attributedString string] copy] autorelease];
	
	return [[attributedString attributedStringByReplacingAttachmentsWithStrings] string];
}





+ (BOOL)isHTMLString:(NSString *)string {
	return ([string length] > 0 && [string characterAtIndex:0] == '<' && [string characterAtIndex:[string length]-1] == '>');
}





#pragma mark -

- (id)init {
	self = [super init];
	
	_commandHistory			= [[NSMutableArray alloc] init];
	_users					= [[NSMutableDictionary alloc] init];
	_allUsers				= [[NSMutableArray alloc] init];
	_shownUsers				= [[NSMutableArray alloc] init];
	_pings					= [[NSMutableDictionary alloc] init];
	_highlightPatterns		= [[NSMutableArray alloc] init];
	_highlightColors		= [[NSMutableArray alloc] init];
    
    _jsonWriter             = [[SBJson4Writer alloc] init];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(dateDidChange:)
     name:WCDateDidChangeNotification];
    
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(preferencesDidChange:)
     name:WCPreferencesDidChangeNotification];
    
	return self;
}



- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_connection removeObserver:self];
	
	[_errorQueue release];
	
	if(_loadedNib) {
		[_userListMenu release];
		[_setTopicPanel release];
		[_kickMessagePanel release];
	}
	
	[_saveChatView release];
	
	[_connection release];
	
	[_users release];
	[_allUsers release];
	[_shownUsers release];
	
	[_commandHistory release];
	
	[_chatColor release];
	[_eventsColor release];
	[_timestampEveryLineColor release];
	[_highlightPatterns release];
	[_highlightColors release];
	
	[_timestamp release];
	[_topic release];
	
	[_timestampDateFormatter release];
	[_timestampEveryLineDateFormatter release];
	[_topicDateFormatter release];
    
	[_pings release];
    [_jsonWriter release];
    
	[super dealloc];
}



#pragma mark -

- (void)awakeFromNib {
	NSDictionary		*theme;
	WITemplateBundle	*template;
	
	[_userListTableView setTarget:self];
	[_userListTableView setDoubleAction:@selector(sendPrivateMessage:)];
	
	_timestampDateFormatter = [[WIDateFormatter alloc] init];
	[_timestampDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_timestampDateFormatter setDateStyle:NSDateFormatterShortStyle];
	
	_timestampEveryLineDateFormatter = [[WIDateFormatter alloc] init];
	[_timestampEveryLineDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	_topicDateFormatter = [[WIDateFormatter alloc] init];
	[_topicDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_topicDateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_topicDateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	[_chatOutputWebView setUIDelegate:(id)self];
    [_chatOutputWebView setFrameLoadDelegate:(id)self];
	[_chatOutputWebView setResourceLoadDelegate:(id)self];
    [_chatOutputWebView setPolicyDelegate:(id)self];
    [_chatOutputWebView registerForDraggedTypes:@[NSFilenamesPboardType]];
	
	[[_topicTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	theme		= [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	template	= [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];

    [self _loadTheme:theme withTemplate:template];
    
    if([[WCSettings settings] boolForKey:WCHideUserList])
        [self hideUserList:self];
	
	[self _updatePreferences];
}

    



#pragma mark -

- (void)themeDidChange:(NSDictionary *)theme {
	WITemplateBundle		*templateBundle;
	NSColor					*textColor, *backgroundColor, *timestampColor, *eventColor, *urlColor;
	NSFont					*font;
	BOOL					reload = NO;
	
	font					= WIFontFromString([theme objectForKey:WCThemesChatFont]);
	textColor				= WIColorFromString([theme objectForKey:WCThemesChatTextColor]);
	urlColor				= WIColorFromString([theme objectForKey:WCThemesChatURLsColor]);
	backgroundColor			= WIColorFromString([theme objectForKey:WCThemesChatBackgroundColor]);
	timestampColor			= WIColorFromString([theme objectForKey:WCThemesChatTimestampEveryLineColor]);
	eventColor				= WIColorFromString([theme objectForKey:WCThemesChatEventsColor]);
	
	// Cocoa UI reload
//	if(![[_setTopicTextView font] isEqualTo:font]) {
//		[_chatInputTextView setFont:font];
//		[_setTopicTextView setFont:font];
//		
//		[_chatFont release];
//		_chatFont = [font retain];
//	}
//	
//	if(![[_chatInputTextView backgroundColor] isEqualTo:backgroundColor]) {
//		[_chatInputTextView setBackgroundColor:backgroundColor];
//		[_setTopicTextView setBackgroundColor:backgroundColor];
//	}
//    
//	if(![textColor isEqualTo:_chatColor]) {
//		[_chatInputTextView setTextColor:textColor];
//		[_chatInputTextView setInsertionPointColor:textColor];
//		[_setTopicTextView setTextColor:textColor];
//		[_setTopicTextView setInsertionPointColor:textColor];
//        
//		[_chatColor release];
//		_chatColor = [textColor retain];
//        
//		reload = YES;
//	}
    
	if(![eventColor isEqualTo:_eventsColor]) {
		[_eventsColor release];
		_eventsColor = [eventColor retain];
        
		reload = YES;
	}
    
	if(![timestampColor isEqualTo:_timestampEveryLineColor]) {
		[_timestampEveryLineColor release];
		_timestampEveryLineColor = [timestampColor retain];
		
		reload = YES;
	}
    
    if([[theme objectForKey:WCThemesUserListAlternateRows] boolValue]) {
        [_userListTableView setUsesAlternatingRowBackgroundColors:YES];
        [_userListTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
    } else {
        [_userListTableView setUsesAlternatingRowBackgroundColors:NO];
        [_userListTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
    }
    	
	switch([[theme objectForKey:WCThemesUserListIconSize] integerValue]) {
		case WCThemesUserListIconSizeLarge:
			[_userListTableView setRowHeight:35.0];
			break;
            
		case WCThemesUserListIconSizeSmall:
			[_userListTableView setRowHeight:17.0];
			break;
	}
	
	[_userListTableView sizeLastColumnToFit];
    
    if(_receivedUserList) {
        [_userListTableView setNeedsDisplay:YES];
        [_userListTableView reloadData];
    }
    
	// HTML/ CSS template reload
	templateBundle  = [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];
    
	[templateBundle setCSSValue:[font fontName]
                    toAttribute:WITemplateAttributesFontName
                         ofType:WITemplateTypeChat];
    
	[templateBundle setCSSValue:[NSSWF:@"%.0fpx", [font pointSize]]
                    toAttribute:WITemplateAttributesFontSize
                         ofType:WITemplateTypeChat];
    
	[templateBundle setCSSValue:[NSSWF:@"#%.6lx", (unsigned long)[textColor HTMLValue]]
                    toAttribute:WITemplateAttributesFontColor
                         ofType:WITemplateTypeChat];
    
	[templateBundle setCSSValue:[NSSWF:@"#%.6lx", (unsigned long)[backgroundColor HTMLValue]]
                    toAttribute:WITemplateAttributesBackgroundColor
                         ofType:WITemplateTypeChat];
    
	[templateBundle setCSSValue:[NSSWF:@"#%.6lx", (unsigned long)[timestampColor HTMLValue]]
                    toAttribute:WITemplateAttributesTimestampColor
                         ofType:WITemplateTypeChat];
    
	[templateBundle setCSSValue:[NSSWF:@"#%.6lx", (unsigned long)[eventColor HTMLValue]]
                    toAttribute:WITemplateAttributesEventColor
                         ofType:WITemplateTypeChat];
    
	[templateBundle setCSSValue:[NSSWF:@"#%.6lx", (unsigned long)[urlColor HTMLValue]]
                    toAttribute:WITemplateAttributesURLTextColor
                         ofType:WITemplateTypeChat];
	
	[templateBundle saveChangesForType:WITemplateTypeChat];
	
	[_chatOutputWebView reloadStylesheetWithID:@"wc-stylesheet"
								  withTemplate:templateBundle
										  type:WITemplateTypeChat];
    
    [_chatOutputWebView scrollToBottom];
}



- (void)preferencesDidChange:(NSNotification *)notification {
	[self _updatePreferences];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	[_users removeAllObjects];
	[_shownUsers removeAllObjects];
    
	[_userListTableView reloadData];
}



- (void)serverConnectionThemeDidChange:(NSNotification *)notification {
	[self themeDidChange:[_connection theme]];
}



- (void)wiredSendPingReply:(WIP7Message *)message {
	NSNumber			*number;
	NSTimeInterval		interval;
	NSUInteger			transaction;
	
	[message getUInt32:(WIP7UInt32 *)&transaction forName:@"wired.transaction"];
	
	number = [_pings objectForKey:[NSNumber numberWithUnsignedInt:transaction]];
	
	if(number) {
		interval = [NSDate timeIntervalSinceReferenceDate] - [number doubleValue];
		
		[self printEvent:[NSSWF:
                          NSLS(@"Received ping reply after %.2fms", @"Ping received message (interval)"),
                          interval * 1000.0]];
		
		[_pings removeObjectForKey:number];
	}
}



- (void)dateDidChange:(NSNotification *)notification {
	[self _setTopic:_topic];
}



- (void)chatUsersDidChange:(NSNotification *)notification {
	[_userListTableView reloadData];
}



- (void)wiredChatJoinChatReply:(WIP7Message *)message {
	WCUser			*user;
	WCTopic			*topic;
	NSUInteger		i, count;
	
	if([[message name] isEqualToString:@"wired.chat.user_list"]) {
		user = [WCUser userWithMessage:message connection:[self connection]];
		
		[_allUsers addObject:user];
		[_users setObject:user forKey:[NSNumber numberWithUnsignedInt:[user userID]]];
	}
	else if([[message name] isEqualToString:@"wired.chat.user_list.done"]) {
		[_shownUsers addObjectsFromArray:_allUsers];
		[_allUsers removeAllObjects];
		
		count = [_shownUsers count];
		
		for(i = 0; i < count; i++)
			[[self connection] postNotificationName:WCChatUserAppearedNotification object:[_shownUsers objectAtIndex:i]];
		
		_receivedUserList = YES;
        [_userListTableView reloadData];
	}
	else if([[message name] isEqualToString:@"wired.chat.topic"]) {
		topic = [WCTopic topicWithMessage:message];
		
		[self _setTopic:topic];
		
		[[self connection] removeObserver:self message:message];
	}
}



- (void)wiredUserGetInfoReply:(WIP7Message *)message {
	WCUser		*user;
	
	if([[message name] isEqualToString:@"wired.user.info"]) {
		user = [WCUser userWithMessage:message connection:[self connection]];
        
		[[[[self connection] administration] accountsController] editUserAccountWithName:[user login]];
		
		[[self connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[[self connection] removeObserver:self message:message];
	}
}



- (void)wiredChatKickUserReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.okay"]) {
		[[self connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[[self connection] removeObserver:self message:message];
	}
}



- (void)wiredChatUserJoin:(WIP7Message *)message {
	WCUser			*user;
	WIP7UInt32		cid;
	
	if(!_receivedUserList)
		return;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != [self chatID])
		return;
	
	user = [WCUser userWithMessage:message connection:[self connection]];
	
	[_shownUsers addObject:user];
	[_users setObject:user forKey:[NSNumber numberWithUnsignedInt:[user userID]]];

	[_userListTableView reloadData];
    
	if([[[WCSettings settings] eventWithTag:WCEventsUserJoined] boolForKey:WCEventsPostInChat])
		[self _printUserJoin:user];
	
	[[self connection] postNotificationName:WCChatUserAppearedNotification object:user];
	
	[[self connection] triggerEvent:WCEventsUserJoined info1:user];
}



- (void)wiredChatUserLeave:(WIP7Message *)message {
	WCUser			*user;
	WIP7UInt32		cid, uid;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != WCPublicChatID && cid != [self chatID])
		return;
	
	[message getUInt32:&uid forName:@"wired.user.id"];
	
	user = [self userWithUserID:uid];
	
	if(!user)
		return;
	
	if([[[WCSettings settings] eventWithTag:WCEventsUserLeft] boolForKey:WCEventsPostInChat])
		[self _printUserLeave:user];
	
	[[self connection] triggerEvent:WCEventsUserLeft info1:user];
	[[self connection] postNotificationName:WCChatUserDisappearedNotification object:user];
	
	[_shownUsers removeObject:user];
	[_users removeObjectForKey:[NSNumber numberWithUnsignedInt:[user userID]]];

	[_userListTableView reloadData];
}



- (void)wiredChatTopic:(WIP7Message *)message {
	WCTopic		*topic;
	
	topic = [WCTopic topicWithMessage:message];
	
	if([topic chatID] != [self chatID])
		return;
	
	[self _setTopic:topic];
	
	if([[_topic topic] length] > 0)
		[self _printTopic];
}



- (void)wiredChatSayOrMe:(WIP7Message *)message {
	NSString		*name, *chat;
	NSMutableString *mutableChat;
	NSColor			*color;
	WCUser			*user;
	WIP7UInt32		cid, uid;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	[message getUInt32:&uid forName:@"wired.user.id"];
	
	if(cid != [self chatID])
		return;
	
	user = [self userWithUserID:uid];
	
	if(!user || [user isIgnored])
		return;
	
	if([[WCSettings settings] boolForKey:WCChatTimestampChat])
		[self _printTimestamp];
	
	name		= [message name];
	chat		= [message stringForName:name];
	mutableChat = [NSMutableString stringWithString:chat];
	color		= [self _highlightColorForChat:chat];
    
	if([[WCSettings settings] boolForKey:WCChatEmbedHTMLInChatEnabled] && [[self class] isHTMLString:chat] ) {
		[self _printHTML:chat by:user];
		
	} else {
		if([name isEqualToString:@"wired.chat.say"])
			[self _printChat:mutableChat by:user];
		else
			[self _printActionChat:mutableChat by:user];
	}
	
	if(color != NULL) {
		[[self connection] postNotificationName:WCChatHighlightedChatDidAppearNotification
										 object:[self connection]
									   userInfo:[NSDictionary dictionaryWithObject:color forKey:WCChatHighlightColorKey]];
        
		[[self connection] triggerEvent:WCEventsHighlightedChatReceived info1:user info2:chat];
	} else {
		[[self connection] postNotificationName:WCChatRegularChatDidAppearNotification object:[self connection]];
		
        if([user userID] != [[self connection] userID])
            [[self connection] triggerEvent:WCEventsChatReceived info1:user info2:chat];
		else
			[[self connection] triggerEvent:WCEventsChatSent info1:user info2:chat];
	}
}



- (void)wiredChatUserKick:(WIP7Message *)message {
	NSString		*disconnectMessage;
	WIP7UInt32		killerUserID, victimUserID;
	WCUser			*killer, *victim;
	WIP7UInt32		cid;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != [self chatID])
		return;
	
	[message getUInt32:&killerUserID forName:@"wired.user.id"];
	[message getUInt32:&victimUserID forName:@"wired.user.disconnected_id"];
	
	killer = [self userWithUserID:killerUserID];
	victim = [self userWithUserID:victimUserID];
	
	if(!killer || !victim)
		return;
	
	disconnectMessage = [message stringForName:@"wired.user.disconnect_message"];
	
	[self _printUserKick:victim by:killer message:disconnectMessage];
	
	if(cid == WCPublicChatID && [victim userID] == [[self connection] userID])
		[[self connection] postNotificationName:WCChatSelfWasKickedFromPublicChatNotification object:[self connection]];
	
	[[self connection] postNotificationName:WCChatUserDisappearedNotification object:victim];
	
	[_shownUsers removeObject:victim];
	[_users removeObjectForKey:[NSNumber numberWithInt:victimUserID]];

	[_userListTableView reloadData];
}



- (void)wiredChatUserDisconnect:(WIP7Message *)message {
	NSString		*disconnectMessage;
	WIP7UInt32		victimUserID;
	WCUser			*victim;
	WIP7UInt32		cid;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != [self chatID])
		return;
	
	[message getUInt32:&victimUserID forName:@"wired.user.disconnected_id"];
	
	victim = [self userWithUserID:victimUserID];
	
	if(!victim)
		return;
	
	disconnectMessage = [message stringForName:@"wired.user.disconnect_message"];
	
	[self _printUserDisconnect:victim message:disconnectMessage];
	
	if(cid == WCPublicChatID && [victim userID] == [[self connection] userID])
		[[self connection] postNotificationName:WCChatSelfWasDisconnectedNotification object:[self connection]];
	
	[[self connection] postNotificationName:WCChatUserDisappearedNotification object:victim];
	
	[_shownUsers removeObject:victim];
	[_users removeObjectForKey:[NSNumber numberWithInt:victimUserID]];

	[_userListTableView reloadData];
}



- (void)wiredChatUserBan:(WIP7Message *)message {
	NSString		*disconnectMessage;
    NSDate          *expirationDate;
	WIP7UInt32		victimUserID;
	WCUser			*victim;
	WIP7UInt32		cid;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != [self chatID])
		return;
	
	[message getUInt32:&victimUserID forName:@"wired.user.disconnected_id"];
	
	victim = [self userWithUserID:victimUserID];
	
	if(!victim)
		return;
	
	disconnectMessage = [message stringForName:@"wired.user.disconnect_message"];
	
	[self _printUserBan:victim message:disconnectMessage];
	
	if(cid == WCPublicChatID && [victim userID] == [[self connection] userID]) {
        expirationDate = [message dateForName:@"wired.banlist.expiration_date"];
        [self _printUserBanned:victim expirationDate:expirationDate];
        
		[[self connection] postNotificationName:WCChatSelfWasBannedNotification object:[self connection]];
    }
    
	[[self connection] postNotificationName:WCChatUserDisappearedNotification object:victim];
	
	[_shownUsers removeObject:victim];
	[_users removeObjectForKey:[NSNumber numberWithInt:victimUserID]];

	[_userListTableView reloadData];
}



- (void)wiredChatUserStatus:(WIP7Message *)message {
    NSIndexSet      *indexSet;
	NSString		*nick, *status;
	WCUser			*user;
	WIP7UInt32		cid, uid;
	WIP7Enum		color;
	WIP7Bool		idle;
    NSInteger       index;
	BOOL			nickChanged = NO;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != [self chatID])
		return;
    
	[message getUInt32:&uid forName:@"wired.user.id"];
	
	user = [self userWithUserID:uid];
	
	if(!user)
		return;
	
	nick = [message stringForName:@"wired.user.nick"];
	
	if(![nick isEqualToString:[user nick]]) {
		if([[[WCSettings settings] eventWithTag:WCEventsUserChangedNick] boolForKey:WCEventsPostInChat])
			[self _printUserChange:user nick:nick];
		
		[[self connection] triggerEvent:WCEventsUserChangedNick info1:user info2:nick];
        
		[user setNick:nick];
		
		nickChanged = YES;
	}
	
	status = [message stringForName:@"wired.user.status"];
	
	if(![status isEqualToString:[user status]]) {
		if([[[WCSettings settings] eventWithTag:WCEventsUserChangedStatus] boolForKey:WCEventsPostInChat])
			[self _printUserChange:user status:status];
		
		[[self connection] triggerEvent:WCEventsUserChangedStatus info1:user info2:status];
        
		[user setStatus:status];
    }
	
	[message getBool:&idle forName:@"wired.user.idle"];
	
	[user setIdle:idle];
	
	if([message getEnum:&color forName:@"wired.account.color"])
		[user setColor:color];
	
    index = [_shownUsers indexOfObject:user];
    
    if(index != -1) {
        indexSet = [NSIndexSet indexSetWithIndex:index];
        [_userListTableView reloadDataForRowIndexes:indexSet
                                      columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
	
	if(nickChanged)
		[[self connection] postNotificationName:WCChatUserNickDidChangeNotification object:user];
}



- (void)wiredChatUserIcon:(WIP7Message *)message {
    NSIndexSet      *indexSet;
	NSImage			*image;
	WCUser			*user;
	WIP7UInt32		cid, uid;
	
	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != [self chatID])
		return;
	
	[message getUInt32:&uid forName:@"wired.user.id"];
	
	user = [self userWithUserID:uid];
	
	if(!user)
		return;
	
	image = [[NSImage alloc] initWithData:[message dataForName:@"wired.user.icon"]];
	[user setIcon:image];
	[image release];
	
    indexSet = [NSIndexSet indexSetWithIndex:[_shownUsers indexOfObject:user]];

	[_userListTableView reloadDataForRowIndexes:indexSet columnIndexes:[NSIndexSet indexSetWithIndex:0]];
	[_userListTableView setNeedsDisplay:YES];
}








#pragma mark -

- (void)menuNeedsUpdate:(NSMenu *)menu {
	if(menu == _userListMenu) {
		if([[self selectedUser] isIgnored]) {
			[_ignoreMenuItem setTitle:NSLS(@"Unignore", "User list menu title")];
			[_ignoreMenuItem setAction:@selector(unignore:)];
		} else {
			[_ignoreMenuItem setTitle:NSLS(@"Ignore", "User list menu title")];
			[_ignoreMenuItem setAction:@selector(ignore:)];
		}
	}
}




#pragma mark -

- (void)controlTextDidChange:(NSNotification *)obj {
    if([obj object] == _chatInputTextField)
        [self _adjustChatInputTextFieldHeight];
}


- (BOOL)topicTextView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
	if(selector == @selector(insertNewline:)) {
		if([[NSApp currentEvent] character] == NSEnterCharacter) {
			[self submitSheet:textView];
			
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)selector {
    WIP7Message		*message;
	NSInteger		historyModifier;
	BOOL			commandKey, optionKey, controlKey, historyScrollback;
	
	commandKey	= [[NSApp currentEvent] commandKeyModifier];
	optionKey	= [[NSApp currentEvent] alternateKeyModifier];
	controlKey	= [[NSApp currentEvent] controlKeyModifier];
	   
	historyScrollback = [[WCSettings settings] boolForKey:WCChatHistoryScrollback];
	historyModifier = [[WCSettings settings] integerForKey:WCChatHistoryScrollbackModifier];
	
	if(selector == @selector(insertLineBreak:)) {
        [self _adjustChatInputTextFieldHeight];
        
    } else if(selector == @selector(insertNewline:) ||
              selector == @selector(insertNewlineIgnoringFieldEditor:)) {
		NSString		*string;
		NSUInteger		length;
        
		string = [[self class] stringByDecomposingSmileyAttributesInAttributedString:[_chatInputTextField attributedStringValue]];
		length = [string length];
        
		if(length == 0) {
            [self _adjustChatInputTextFieldHeight];
            return YES;
		}
		if(length > WCChatLimit)
			string = [string substringToIndex:WCChatLimit];
		
		[_commandHistory addObject:[[string copy] autorelease]];
		_currentCommand = [_commandHistory count];
		
		if(![string hasPrefix:@"/"] || ![self _runCommand:string]) {
			if(selector == @selector(insertNewlineIgnoringFieldEditor:) ||
			   (selector == @selector(insertNewline:) && optionKey)) {
				message = [WIP7Message messageWithName:@"wired.chat.send_me" spec:WCP7Spec];
				[message setString:string forName:@"wired.chat.me"];
			} else {
				message = [WIP7Message messageWithName:@"wired.chat.send_say" spec:WCP7Spec];
				[message setString:string forName:@"wired.chat.say"];
			}
			
			[message setUInt32:[self chatID] forName:@"wired.chat.id"];
			[[self connection] sendMessage:message];
			
			[[WCStats stats] addUnsignedLongLong:[string UTF8StringLength] forKey:WCStatsChat];
		}
		
		[_chatInputTextField setStringValue:@""];
        [self _adjustChatInputTextFieldHeight];
		return YES;
	}
	else if(selector == @selector(insertTab:)) {
		if([[WCSettings settings] boolForKey:WCChatTabCompleteNicks]) {
			[_chatInputTextField setStringValue:[self _stringByCompletingString:[_chatInputTextField stringValue]]];
			
			return YES;
		}
	}
	else if(selector == @selector(cancelOperation:)) {
		[_chatInputTextField setStringValue:@""];
		
		return YES;
	}
	else if(historyScrollback &&
			((selector == @selector(moveUp:) &&
			  historyModifier == WCChatHistoryScrollbackModifierNone) ||
			 (selector == @selector(moveToBeginningOfDocument:) &&
			  historyModifier == WCChatHistoryScrollbackModifierCommand &&
			  commandKey) ||
			 (selector == @selector(moveToBeginningOfParagraph:) &&
			  historyModifier == WCChatHistoryScrollbackModifierOption &&
			  optionKey) ||
			 (selector == @selector(scrollPageUp:) &&
			  historyModifier == WCChatHistoryScrollbackModifierControl &&
			  controlKey))) {
                 if(_currentCommand > 0) {
                     if(_currentCommand == [_commandHistory count]) {
                         [_currentString release];
                         
                         _currentString = [[_chatInputTextField stringValue] copy];
                     }
                     
                     [_chatInputTextField setStringValue:[_commandHistory objectAtIndex:--_currentCommand]];
                     
                     return YES;
                 }
             }
	else if(historyScrollback &&
			((selector == @selector(moveDown:) &&
			  historyModifier == WCChatHistoryScrollbackModifierNone) ||
			 (selector == @selector(moveToEndOfDocument:) &&
			  historyModifier == WCChatHistoryScrollbackModifierCommand &&
			  commandKey) ||
			 (selector == @selector(moveToEndOfParagraph:) &&
			  historyModifier == WCChatHistoryScrollbackModifierOption &&
			  optionKey) ||
			 (selector == @selector(scrollPageDown:) &&
			  historyModifier == WCChatHistoryScrollbackModifierControl &&
			  controlKey))) {
                 if(_currentCommand + 1 < [_commandHistory count]) {
                     [_chatInputTextField setStringValue:[_commandHistory objectAtIndex:++_currentCommand]];
                     
                     return YES;
                 }
                 else if(_currentCommand + 1 == [_commandHistory count]) {
                     _currentCommand++;
                     [_chatInputTextField setStringValue:_currentString];
                     [_currentString release];
                     _currentString = NULL;
                     
                     return YES;
                 }
             }
	else if(selector == @selector(moveToBeginningOfDocument:) ||
			selector == @selector(moveToEndOfDocument:) ||
			selector == @selector(scrollToBeginningOfDocument:) ||
			selector == @selector(scrollToEndOfDocument:) ||
			selector == @selector(scrollPageUp:) ||
			selector == @selector(scrollPageDown:)) {
		
		
		return YES;
	}
    
	return NO;
}




//- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
//	BOOL	value = NO;
//	
//	if(textView == _setTopicTextView) {
//		value = [self topicTextView:textView doCommandBySelector:selector];
//		
//		[_setTopicTextView setFont:WIFontFromString([[[self connection] theme] objectForKey:WCThemesChatFont])];
//	}
//	else if(textView == _chatInputTextField) {
//		value = [self chatTextView:textView doCommandBySelector:selector];
//		
//		[_chatInputTextView setFont:WIFontFromString([[[self connection] theme] objectForKey:WCThemesChatFont])];
//	}
//	
//	return value;
//}




#pragma mark -

- (NSString *)saveDocumentMenuItemTitle {
	return NSLS(@"Save Chat", @"Save menu item");
}



#pragma mark -

- (void)validate {
	BOOL	connected;
	
	connected = [[self connection] isConnected];
	
    [_showEmoticonsButtons setEnabled:connected];
    [_chatInputTextField setEditable:connected];
    
	if([_userListTableView selectedRow] < 0) {
		[_infoButton setEnabled:NO];
		[_privateMessageButton setEnabled:NO];
		[_kickButton setEnabled:NO];
	} else {
        if([self selectedUser]) {
            [_infoButton setEnabled:([[[self connection] account] userGetInfo] && connected)];
            [_privateMessageButton setEnabled:connected];
            [_kickButton setEnabled:(([self chatID] != WCPublicChatID || [[[self connection] account] chatKickUsers]) && connected)];
        }
	}
}



- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;
	BOOL	connected;
    BOOL    selected;
	
	selector    = [item action];
	connected   = [[self connection] isConnected];
    selected    = [self selectedUser] ? YES : NO;
	
	if(selector == @selector(sendPrivateMessage:))
		return ([[[self connection] account] messageSendMessages] && selected && connected);
    
    else if(selector == @selector(ignore:))
		return (selected && connected);
    
	else if(selector == @selector(getInfo:))
		return ([[[self connection] account] userGetInfo] && selected && connected);
    
	else if(selector == @selector(kick:))
		return (([self chatID] != WCPublicChatID || [[[self connection] account] chatKickUsers]) && selected && connected);
    
	else if(selector == @selector(editAccount:))
		return ([[[self connection] account] userGetInfo] && [[[self connection] account] accountEditUsers] && selected && connected);
    
	return YES;
}



#pragma mark -

- (void)setConnection:(WCServerConnection *)connection {
	[connection retain];
	[_connection release];
	
	_connection = connection;
	
	[_connection addObserver:self
					selector:@selector(linkConnectionLoggedIn:)
						name:WCLinkConnectionLoggedInNotification];
    
	[_connection addObserver:self
					selector:@selector(serverConnectionThemeDidChange:)
						name:WCServerConnectionThemeDidChangeNotification];
    
	[_connection addObserver:self selector:@selector(wiredChatUserJoin:) messageName:@"wired.chat.user_join"];
	[_connection addObserver:self selector:@selector(wiredChatUserLeave:) messageName:@"wired.chat.user_leave"];
	[_connection addObserver:self selector:@selector(wiredChatTopic:) messageName:@"wired.chat.topic"];
	[_connection addObserver:self selector:@selector(wiredChatSayOrMe:) messageName:@"wired.chat.say"];
	[_connection addObserver:self selector:@selector(wiredChatSayOrMe:) messageName:@"wired.chat.me"];
	[_connection addObserver:self selector:@selector(wiredChatUserKick:) messageName:@"wired.chat.user_kick"];
	[_connection addObserver:self selector:@selector(wiredChatUserDisconnect:) messageName:@"wired.chat.user_disconnect"];
	[_connection addObserver:self selector:@selector(wiredChatUserBan:) messageName:@"wired.chat.user_ban"];
	[_connection addObserver:self selector:@selector(wiredChatUserStatus:) messageName:@"wired.chat.user_status"];
	[_connection addObserver:self selector:@selector(wiredChatUserIcon:) messageName:@"wired.chat.user_icon"];
	
	[self themeDidChange:[_connection theme]];
}



- (WCServerConnection *)connection {
	return _connection;
}



#pragma mark -

- (NSView *)view {
	return _userListSplitView;
}

- (WebView *)webView {
	return _chatOutputWebView;
}


- (void)awakeInWindow:(NSWindow *)window {
	[_errorQueue release];
	_errorQueue = [[WCErrorQueue alloc] initWithWindow:window];
}



- (void)loadWindowProperties {
	[_userListSplitView setPropertiesFromDictionary:
     [[[WCSettings settings] objectForKey:WCWindowProperties] objectForKey:@"WCChatControllerUserListSplitView"]];
}



- (void)saveWindowProperties {
	[[WCSettings settings] setObject:[_userListSplitView propertiesDictionary]
							  forKey:@"WCChatControllerUserListSplitView"
				  inDictionaryForKey:WCWindowProperties];
}



#pragma mark -

- (WCUser *)selectedUser {
	NSInteger		row;
	
	row = [_userListTableView selectedRow];
	
	if(row < 0)
		return NULL;
	
	return [_shownUsers objectAtIndex:row];
}



- (NSArray *)selectedUsers {
	return [NSArray arrayWithObject:[self selectedUser]];
}



- (NSArray *)users {
	return _shownUsers;
}



- (NSArray *)nicks {
	NSEnumerator	*enumerator;
	NSMutableArray	*nicks;
	WCUser			*user;
	
	nicks = [NSMutableArray array];
	enumerator = [_shownUsers objectEnumerator];
	
	while((user = [enumerator nextObject]))
		[nicks addObject:[user nick]];
	
	return nicks;
}



- (WCUser *)userAtIndex:(NSUInteger)index {
	return [_shownUsers objectAtIndex:index];
}



- (WCUser *)userWithUserID:(NSUInteger)uid {
	return [_users objectForKey:[NSNumber numberWithInt:uid]];
}



- (void)selectUser:(WCUser *)user {
	NSUInteger	index;
	
	index = [_shownUsers indexOfObject:user];
	
	if(index != NSNotFound) {
		[_userListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
		[_userListTableView scrollRowToVisible:index];
		[[_userListTableView window] makeFirstResponder:_userListTableView];
	}
}



- (NSUInteger)chatID {
	return WCPublicChatID;
}



- (NSTextField *)insertionTextField {
	return _chatInputTextField;
}




#pragma mark -

- (void)sendChat:(NSString *)string {
    WIP7Message		*message;
    
    message = [WIP7Message messageWithName:@"wired.chat.send_say" spec:WCP7Spec];
    [message setString:string forName:@"wired.chat.say"];
    [message setUInt32:[self chatID] forName:@"wired.chat.id"];
    
    [[self connection] sendMessage:message];
    
    [[WCStats stats] addUnsignedLongLong:[string UTF8StringLength] forKey:WCStatsChat];
}

- (void)printEvent:(NSString *)message {
    WIChatLogController     *logController;
    NSBundle                *template;
	NSString                *output, *formattedDate;
	NSMutableString         *mutableOutput;
    NSDictionary            *jsonProxy;
	
    logController   = [[WCApplicationController sharedController] logController];
	output			= [NSSWF:NSLS(@"<<< %@ >>>", @"Chat event (message)"), message];
	mutableOutput	= [NSMutableString stringWithString:output];
	template		= [[WCSettings settings] templateBundleWithIdentifier:[[[self connection] theme] objectForKey:WCThemesTemplate]];
	formattedDate	= [_timestampEveryLineDateFormatter stringFromDate:[NSDate date]];
	
	if([[[self connection] theme] boolForKey:WCThemesShowSmileys])
		[[self class] applyHTMLTagsForSmileysToMutableString:mutableOutput];

    jsonProxy = [NSDictionary dictionaryWithObjectsAndKeys:
                 formattedDate, @"timestamp",
                 mutableOutput, @"message", nil];
    
    [_chatOutputWebView stringByEvaluatingJavaScriptFromString:
     [NSSWF:@"printEvent(%@);", [_jsonWriter stringWithObject:jsonProxy]]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsPlainTextEnabled])
		[logController appendChatLogAsPlainText:[NSSWF:@"[%@]\t%@\n", formattedDate, output]
                              forConnectionName:[[self connection] name]];
}


- (void)printChatNowPlaying {
	[self _sendiTunes];
}


- (void)clearChat {
	[_chatOutputWebView clearChildrenElementsOfElementWithID:@"chat-content"];
}


- (BOOL)chatIsEmpty {
	DOMHTMLElement *chatContentElement = (DOMHTMLElement *)[[[_chatOutputWebView mainFrame] DOMDocument] getElementById:@"chat-content"];
    return ![chatContentElement hasChildNodes];
}





#pragma mark -

- (IBAction)saveDocument:(id)sender {
	[self saveChat:sender];
}



- (IBAction)stats:(id)sender {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.chat.send_say" spec:WCP7Spec];
	[message setUInt32:[self chatID] forName:@"wired.chat.id"];
	[message setString:[[WCStats stats] stringValue] forName:@"wired.chat.say"];
	[[self connection] sendMessage:message];
}



- (IBAction)saveChat:(id)sender {
    NSSavePanel				*savePanel;
	NSArray					*typeNames;
	
	typeNames = [WIChatLogController typeNames];
	[_saveChatFileFormatPopUpButton removeAllItems];
	[_saveChatFileFormatPopUpButton addItemsWithTitles:typeNames];
    
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[WIChatLogController typeNames]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAccessoryView:_saveChatView];
    [savePanel setNameFieldStringValue:[NSSWF:@"%@ Public Chat", [[self connection] name]]];
	
	[self _updateSaveChatForPanel:savePanel];
    
    [savePanel beginSheetModalForWindow:[_userListSplitView window] completionHandler:^(NSInteger result) {
        WIChatLogType			type;
        
        if(result == NSModalResponseOK) {
            type = [_saveChatFileFormatPopUpButton indexOfSelectedItem];
            
            [_chatOutputWebView exportContentToFileAtPath:[[savePanel URL] path] forType:type];
        }
    }];
}


- (void)saveChatPanelDidEnd:(NSSavePanel *)savePanel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WIChatLogType			type;
	
	if(returnCode == NSModalResponseOK) {
		type = [_saveChatFileFormatPopUpButton indexOfSelectedItem];
		
		[_chatOutputWebView exportContentToFileAtPath:[[savePanel URL] path] forType:type];
	}
}



- (IBAction)setTopic:(id)sender {
    
    if(_topic && [_topic topic]) {
        [_setTopicTextView setString:[_topic topic]];
        [_setTopicTextView setSelectedRange:NSMakeRange(0, [[_setTopicTextView string] length])];
	}
    
	[NSApp beginSheet:_setTopicPanel
	   modalForWindow:[_userListSplitView window]
		modalDelegate:self
	   didEndSelector:@selector(setTopicSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}



- (void)setTopicSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WIP7Message		*message;
	
	if(returnCode == NSAlertDefaultReturn) {
		message = [WIP7Message messageWithName:@"wired.chat.set_topic" spec:WCP7Spec];
		[message setUInt32:[self chatID] forName:@"wired.chat.id"];
		[message setString:[_setTopicTextView string] forName:@"wired.chat.topic.topic"];
		[[self connection] sendMessage:message];
	}
	
	[_setTopicPanel close];
	[_setTopicTextView setString:@""];
}



- (IBAction)sendPrivateMessage:(id)sender {
    if(![self selectedUser])
        return;
	
	[[WCMessages messages] showPrivateMessageToUser:[self selectedUser]];
}



- (IBAction)getInfo:(id)sender {
	[WCUserInfo userInfoWithConnection:[self connection] user:[self selectedUser]];
}



- (IBAction)kick:(id)sender {
	[NSApp beginSheet:_kickMessagePanel
	   modalForWindow:[_userListSplitView window]
		modalDelegate:self
	   didEndSelector:@selector(kickSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:[[self selectedUser] retain]];
}



- (void)kickSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WIP7Message		*message;
	WCUser			*user = contextInfo;
	
	if(returnCode == NSAlertDefaultReturn) {
		message = [WIP7Message messageWithName:@"wired.chat.kick_user" spec:WCP7Spec];
		[message setUInt32:[user userID] forName:@"wired.user.id"];
		[message setUInt32:[self chatID] forName:@"wired.chat.id"];
		[message setString:[_kickMessageTextField stringValue] forName:@"wired.user.disconnect_message"];
		[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredChatKickUserReply:)];
	}
	
	[user release];
	
	[_kickMessagePanel close];
	[_kickMessageTextField setStringValue:@""];
}



- (IBAction)editAccount:(id)sender {
	WIP7Message		*message;
	WCUser			*user;
	
	user = [self selectedUser];
	
	message = [WIP7Message messageWithName:@"wired.user.get_info" spec:WCP7Spec];
	[message setUInt32:[user userID] forName:@"wired.user.id"];
	[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredUserGetInfoReply:)];
}



- (IBAction)ignore:(id)sender {
	NSDictionary	*ignore;
	WCUser			*user;
	
	user = [self selectedUser];
	
	if([user isIgnored])
		return;
	
	ignore = [NSDictionary dictionaryWithObject:[user nick] forKey:WCIgnoresNick];
	
	[[WCSettings settings] addObject:ignore toArrayForKey:WCIgnores];
	[[NSNotificationCenter defaultCenter] postNotificationName:WCIgnoresDidChangeNotification];
	
	[_userListTableView reloadData];
}



- (IBAction)unignore:(id)sender {
	NSDictionary		*ignore;
	NSMutableArray		*array;
	NSEnumerator		*enumerator;
	WCUser				*user;
	
	user = [self selectedUser];
	
	if(![user isIgnored])
		return;
	
	array		= [NSMutableArray array];
	enumerator	= [[[WCSettings settings] objectForKey:WCIgnores] objectEnumerator];
	
	while((ignore = [enumerator nextObject])) {
		if(![[ignore objectForKey:WCIgnoresNick] isEqualToString:[user nick]])
			[array addObject:ignore];
	}
	
	[[WCSettings settings] setObject:array forKey:WCIgnores];
	[[NSNotificationCenter defaultCenter] postNotificationName:WCIgnoresDidChangeNotification];
	
	[_userListTableView reloadData];
}


- (IBAction)toggleUserList:(id)sender {
    
    if ([_userListSplitView isSubviewCollapsed:[[_userListSplitView subviews] objectAtIndex:1]]) {
        [_userListSplitView setPosition:[_userListSplitView frame].size.width-176.0
                       ofDividerAtIndex:0];
    } else {
        [_userListSplitView setPosition:[_userListSplitView frame].size.width
                       ofDividerAtIndex:0];
    }
}


- (IBAction)showUserList:(id)sender {
    if ([_userListSplitView isSubviewCollapsed:[[_userListSplitView subviews] objectAtIndex:1]])
        [_userListSplitView setPosition:[_userListSplitView frame].size.width-176.0
                       ofDividerAtIndex:0];
}


- (IBAction)hideUserList:(id)sender {
    if (![_userListSplitView isSubviewCollapsed:[[_userListSplitView subviews] objectAtIndex:1]])
        [_userListSplitView setPosition:[_userListSplitView frame].size.width
                       ofDividerAtIndex:0];
}


- (IBAction)showEmoticons:(id)sender {
    [[WCEmoticonViewController emoticonController] popoverWithSender:sender
                                                            textField:_chatInputTextField];
}


- (IBAction)fileFormat:(id)sender {
	[self _updateSaveChatForPanel:(NSSavePanel *) [sender window]];
}




#pragma mark -

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    WITemplateBundle    *template;
    NSURL               *jqueryURL, *functionsURL, *mainURL;
    NSDictionary		*theme;

	theme		= [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	template	= [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];
        
    if(!template) {
        NSLog(@"Error: Template not found. (%@)", _chatTemplate);
        return;
    }
    
    jqueryURL       = [NSURL fileURLWithPath:[template pathForResource:@"jquery" ofType:@"js" inDirectory:@"htdocs/js"]];
    functionsURL    = [NSURL fileURLWithPath:[template pathForResource:@"functions" ofType:@"js" inDirectory:@"htdocs/js"]];
    mainURL         = [NSURL fileURLWithPath:[template pathForResource:@"chat" ofType:@"js" inDirectory:@"htdocs/js"]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[jqueryURL path]] ||
       ![[NSFileManager defaultManager] fileExistsAtPath:[functionsURL path]] ||
       ![[NSFileManager defaultManager] fileExistsAtPath:[mainURL path]])
    {
        NSLog(@"Error: Invalid template. Missing script. (%@)", _chatTemplate);
        return;
    }
    
    [[_chatOutputWebView windowScriptObject] setValue:self forKey:@"Controller"];
    
    [_chatOutputWebView appendScriptAtURL:jqueryURL];
    [_chatOutputWebView appendScriptAtURL:functionsURL];
    [_chatOutputWebView appendScriptAtURL:mainURL];
    
    [_chatOutputWebView scrollToBottom];
}


- (NSArray *)webView:(WebView *)webView contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
#ifdef WCConfigurationRelease
    return NULL;
#else
    return defaultMenuItems;
#endif
}


-(NSURLRequest *)webView:(WebView *)sender
                resource:(id)identifier
         willSendRequest:(NSURLRequest *)request
        redirectResponse:(NSURLResponse *)redirectResponse
          fromDataSource:(WebDataSource *)dataSource
{
    if ([request cachePolicy] != NSURLRequestReloadIgnoringCacheData)
    {
        return [NSURLRequest requestWithURL:[request URL]
                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                            timeoutInterval:[request timeoutInterval]];
    } else {
        return request;
    }
}

- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)action
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id <WebPolicyDecisionListener>)listener
{
	NSString			*path;
    NSURL               *url;
	WIURL				*wiredURL;
	WCFile				*file;
    NSData              *fileData;
    NSImage             *droppedImage;
	BOOL				handled     = NO;
	BOOL                isDirectory = NO;
    
    if([[action objectForKey:WebActionNavigationTypeKey] unsignedIntegerValue] == WebNavigationTypeLinkClicked) {
        [listener ignore];
        
        url         = [action objectForKey:WebActionOriginalURLKey];
		wiredURL    = [WIURL URLWithURL:url];
        
        isDirectory = [[url absoluteString] hasSuffix:@"/"] ? YES : NO;
		
		if([[wiredURL scheme] isEqualToString:@"wired"] || [[wiredURL scheme] isEqualToString:@"wiredp7"]) {
			if([[wiredURL host] length] == 0) {
				if([self connection] && [[self connection] isConnected]) {
					path = [[wiredURL path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					if(isDirectory) {
                        [WCFiles filesWithConnection:[self connection]
                                                file:[WCFile fileWithDirectory:[path stringByDeletingLastPathComponent] connection:[self connection]]
                                          selectFile:[WCFile fileWithDirectory:path connection:[self connection]]];
                        
					} else {
                        file = [WCFile fileWithFile:path connection:[self connection]];
                        [[WCTransfers transfers] downloadFiles:[NSArray arrayWithObject:file]
                                                      toFolder:[[[WCSettings settings] objectForKey:WCDownloadFolder] stringByStandardizingPath]];
					}
				}
				
				handled = YES;
			}
		}
		
		if(!handled)
			[[NSWorkspace sharedWorkspace] openURL:[action objectForKey:WebActionOriginalURLKey]];
        
    } else {
        url = [action objectForKey:WebActionOriginalURLKey];
        
        if (![[url pathExtension] isEqualToString:@"html"]) {
            [listener ignore];
            
            fileData        = [NSData dataWithContentsOfURL:url];
            droppedImage    = [NSImage imageWithData:fileData];
            
            if (droppedImage) {
                [self _sendLocalImage:url];
            }
        }
        
        [listener use];
    }
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
    // useless but required
}
    
- (NSUInteger)webView:(WebView *)webView
dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)draggingInfo {
    return WebDragDestinationActionLoad;
}
    

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_shownUsers count];
}



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self validate];
}



- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    NSDictionary            *theme;
    WCUserTableCellView     *cellView;
    WCUser                  *user;
    
    theme       = [self _currentTheme];
    user        = [self userAtIndex:row];
    
    switch([[theme objectForKey:WCThemesUserListIconSize] integerValue]) {
		case WCThemesUserListIconSizeLarge: {
            if([[user status] length] > 0)
                cellView = [tableView makeViewWithIdentifier:@"WCLargeUserWithStatusTableCellView" owner:tableView];
            else
                cellView = [tableView makeViewWithIdentifier:@"WCLargeUserTableCellView" owner:tableView];
        } break;
            
		case WCThemesUserListIconSizeSmall: {
            if([[user status] length] > 0)
                cellView = [tableView makeViewWithIdentifier:@"WCSmallUserWithStatusTableCellView" owner:tableView];
            else
                cellView = [tableView makeViewWithIdentifier:@"WCSmallUserTableCellView" owner:tableView];
        } break;
	}
    
    if(row != [tableView selectedRow])
        cellView.nickTextField.textColor = [WCUser colorForColor:[user color] idleTint:[user isIdle]];
    else
        cellView.nickTextField.textColor = [NSColor whiteColor];
    
    [cellView.nickTextField setAllowsEditingTextAttributes:YES];
    
    NSDictionary *attributes;
    
    if([user isIgnored]) {
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInteger:NSUnderlinePatternSolid | NSUnderlineStyleSingle],
                      NSStrikethroughStyleAttributeName,
                      nil];
    } else {
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInteger:NSUnderlinePatternSolid | NSUnderlineStyleNone],
                      NSStrikethroughStyleAttributeName,
                      nil];
    }
    
    cellView.nickTextField.attributedStringValue = [NSAttributedString attributedStringWithString:[user nick]
                                                                                   attributes:attributes];
    
    cellView.nickTextField.toolTip = [user nick];
    
    cellView.statusTextField.toolTip = [user status];
    cellView.statusTextField.stringValue = [user status];
    cellView.imageView.image = [user iconWithIdleTint:YES];
    
    return cellView;
    
}





- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    if(tableView == _userListTableView)
        NSLog(@"willDisplayCell");
//	WCUser		*user;
//	
//	if(column == _nickTableColumn) {
//		user = [self userAtIndex:row];
//		
//		[cell setTextColor:[WCUser colorForColor:[user color] idleTint:[user isIdle]]];
//		[cell setIgnored:[user isIgnored]];
//	}
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	WCUser		*user;
	
	user = [self userAtIndex:row];
	
	if(column == _iconTableColumn)
		return [user iconWithIdleTint:YES];
	else if(column == _nickTableColumn) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[user nick],		WCUserCellNickKey,
				[user status],		WCUserCellStatusKey,
				NULL];
	}
	
	return NULL;
}



- (NSString *)tableView:(NSTableView *)tableView stringValueForRow:(NSInteger)row {
	return [[self userAtIndex:row] nick];
}



- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
	NSMutableString		*toolTip;
	WCUser				*user;
	
	user = [self userAtIndex:row];
	toolTip = [[[user nick] mutableCopy] autorelease];
	
	if([[user status] length] > 0)
		[toolTip appendFormat:@"\n%@", [user status]];
	
	return toolTip;
}



- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	WCUser		*user;
	
	user = [self userAtIndex:[indexes firstIndex]];
	
	[pasteboard declareTypes:[NSArray arrayWithObjects:WCUserPboardType, NSStringPboardType, NULL] owner:NULL];
	[pasteboard setString:[NSSWF:@"%lu", (unsigned long)[user userID]] forType:WCUserPboardType];
	[pasteboard setString:[user nick] forType:NSStringPboardType];
	
	return YES;
}



- (void)tableViewShouldCopyInfo:(NSTableView *)tableView {
	NSPasteboard	*pasteboard;
	WCUser			*user;
	
	user = [self selectedUser];
	
	pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NULL] owner:NULL];
	[pasteboard setString:[user nick] forType:NSStringPboardType];
}





#pragma mark -

- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex {
    BOOL                success = NO;
    BOOL                isDirectory = NO;
    NSString            *path = nil;
    NSURL               *url = (NSURL *)link;
    WCFile              *file = nil;
    
    if([[url absoluteString] containsSubstring:@"wired:///"] || [[url absoluteString] containsSubstring:@"wiredp7:///"]) {
        
        path = [[url path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];      
        isDirectory = [[url absoluteString] hasSuffix:@"/"] ? YES : NO;  
        
        if(isDirectory) {
            
            file = [WCFile fileWithDirectory:path connection:[self connection]];
            [WCFiles filesWithConnection:[self connection]
                                    file:file
                              selectFile:[WCFile fileWithFile:path connection:[self connection]]];
        } else {
            
            file = [WCFile fileWithFile:path connection:[self connection]];
            [[WCTransfers transfers] downloadFiles:[NSArray arrayWithObject:file] 
                                          toFolder:[[[WCSettings settings] objectForKey:WCDownloadFolder] stringByStandardizingPath]];
        }
        
    } else {
        success = [[NSWorkspace sharedWorkspace] openURL: url];   
    }
    
    return success;
}





#pragma mark -

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
	if(splitView == _userListSplitView)
		return 300.0;
	
	else if(splitView == _chatSplitView)
		return proposedMin + 50.0;
	
	return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
	if(splitView == _userListSplitView)
		return proposedMax - 176.0;
	
	else if(splitView == _chatSplitView)
		return proposedMax - 31.0;
    
	return proposedMax;
}



- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    if(splitView == _userListSplitView) {
        if(view == [[splitView subviews] objectAtIndex:0])
            return YES;
        
    } else if(splitView == _chatSplitView) {
        if(view == [[splitView subviews] objectAtIndex:0])
            return YES;
    }
    return NO;
}



- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if(splitView == _userListSplitView)
        if(subview == [[splitView subviews] objectAtIndex:1])
            return YES;
    
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    if(splitView == _userListSplitView)
        return YES;
    else if(splitView == _chatSplitView)
        return NO;
	
    return NO;
}

- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
    if(splitView == _userListSplitView)
        return [_splitResizeView convertRect:[_splitResizeView bounds] toView:splitView];
    
    return NSZeroRect;
}


- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if([[_userListSplitView subviews] objectAtIndex:1].isHidden == YES) {
        [[WCSettings settings] setBool:YES forKey:WCHideServerList];
        [[[WCPublicChat publicChat] viewsSegmentedControl] setSelected:NO forSegment:1];
    }
    else {
        [[WCSettings settings] setBool:NO forKey:WCHideServerList];
        [[[WCPublicChat publicChat] viewsSegmentedControl] setSelected:YES forSegment:1];
    }
}



@end
