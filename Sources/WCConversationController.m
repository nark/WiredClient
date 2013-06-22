/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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
#import "WCFiles.h"
#import "WCFile.h"
#import "WCTransfers.h"
#import "WCDOMMessage.h"
#import "WCDOMMessageStatus.h"




#define WC_MESSAGES_STATUS_INTERVAL 60*60*24




@interface WCConversationController(Private)

- (void)_reloadDataAsynchronously;

@end







@implementation WCConversationController(Private)


- (void)_reloadDataAsynchronously {	
	__block NSEnumerator				*enumerator;
	__block NSMutableDictionary			*icons;
	__block NSCalendar					*calendar;
	__block NSDate						*previousDate;
	__block NSDateComponents			*components;
	__block NSMutableString				*mutableMessage;
	__block NSString					*icon, *messageTemplate, *statusTemplate;
	__block NSError						*error;
	__block WITemplateBundle			*template;
	__block WCMessage					*message;
	__block WCDOMMessage				*messageElement;
	__block WCDOMMessageStatus			*messageStatusElement;
	__block NSInteger					day;
	__block BOOL						changedUnread = NO, isKeyWindow;
	
	// launch background operation 
	__block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		
		// clean the webview in the main thread
		dispatch_sync(dispatch_get_main_queue(), ^{
			[_conversationWebView clearChildrenElementsOfElementWithID:@"messages-content"];
		});
		
		template		= [WITemplateBundle templateWithPath:_templatePath];
	
		messageTemplate = [NSString stringWithContentsOfFile:[template pathForResource:@"Message" ofType:@"html" inDirectory:@"htdocs"] encoding:NSUTF8StringEncoding error:&error];;
		statusTemplate	= [NSString stringWithContentsOfFile:[template pathForResource:@"MessageStatus" ofType:@"html" inDirectory:@"htdocs"] encoding:NSUTF8StringEncoding error:&error];
		
		// reload CSS in the main thread
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self reloadTemplate];
		});
		
		
		if(_conversation && ![_conversation isExpandable]) {
			
			isKeyWindow = ([NSApp keyWindow] == [_conversationWebView window]);
			
			if([_conversation numberOfMessages] != 0) {
				calendar		= [NSCalendar currentCalendar];
				day				= -1;
				previousDate	= nil;
				icons			= [NSMutableDictionary dictionary];
				enumerator		= [[_conversation messages] reverseObjectEnumerator];
				
				// for each message of the conversation, if operation is still running
				while((message = [enumerator nextObject]) && ![operation isCancelled]) {	
					
					// check for status element
					components	= [calendar components:NSDayCalendarUnit fromDate:[message date]];
					
					if(previousDate == nil) {
						previousDate	= [message date];
						
					} else {
						if([previousDate timeIntervalSinceDate:[message date]] > WC_MESSAGES_STATUS_INTERVAL) {
							// append status element in the main thread
							dispatch_sync(dispatch_get_main_queue(), ^{
								messageStatusElement = [WCDOMMessageStatus messageStatusElementForFrame:[_conversationWebView mainFrame] withTemplate:statusTemplate];
								[messageStatusElement setMessageStatus:[_messageStatusDateFormatter stringFromDate:previousDate]];
								
								[_conversationWebView appendElement:[messageStatusElement element] 
											   toTopOfElementWithID:@"messages-content" 
															 scroll:YES];
							});	
							previousDate = [message date];
						}
					}
					
					// compute icon as a base 64 string
					icon = [icons objectForKey:[NSNumber numberWithInt:[[message user] userID]]];
					
					if(!icon) {
						icon = [[[[message user] icon] TIFFRepresentation] base64EncodedString];
						
						if(icon)
							[icons setObject:icon forKey:[NSNumber numberWithInt:[[message user] userID]]];
					}
					
					// compute message string (format HTML, URL, smileys)
					mutableMessage = [NSMutableString stringWithString:[message message]];
					
					if(![WCChatController isHTMLString:mutableMessage]) {
						
						[WCChatController applyHTMLEscapingToMutableString:mutableMessage];
						[WCChatController applyHTMLTagsForURLToMutableString:mutableMessage];
						
						if([[[_conversation connection] theme] boolForKey:WCThemesShowSmileys])
							[WCChatController applyHTMLTagsForSmileysToMutableString:mutableMessage];
						
					}
					
					[mutableMessage replaceOccurrencesOfString:@"\n" withString:@"<br />\n"];
					
					
					// apend chat element in the main thread, re-check if operation is still running
					if(![operation isCancelled]) {
						dispatch_sync(dispatch_get_main_queue(), ^{
							messageElement = [WCDOMMessage messageElementForFrame:[_conversationWebView mainFrame] withTemplate:messageTemplate];
							[messageElement setServer:[message connectionName]];
							[messageElement setTime:[_messageTimeDateFormatter stringFromDate:[message date]]];
							[messageElement setNick:[message nick]];
							
							if([message direction] == WCMessageTo)
								[messageElement setDirection:@"to"];
							else
								[messageElement setDirection:@"from"];
							
							[messageElement setIcon:[NSSWF:@"data:image/tiff;base64,%@", icon]];
							[messageElement setMessageContent:mutableMessage];
							
							[_conversationWebView appendElement:[messageElement element] 
										   toTopOfElementWithID:@"messages-content" 
														 scroll:YES];
						});
					}
					
					// append status element in the main thread (if messages are all loaded, append the status date at the top)
					if(message == [[_conversation messages] objectAtIndex:0]) {
						dispatch_sync(dispatch_get_main_queue(), ^{
							messageStatusElement = [WCDOMMessageStatus messageStatusElementForFrame:[_conversationWebView mainFrame] withTemplate:statusTemplate];
							[messageStatusElement setMessageStatus:[_messageStatusDateFormatter stringFromDate:[message date]]];
							
							[_conversationWebView appendElement:[messageStatusElement element] 
										   toTopOfElementWithID:@"messages-content" 
														 scroll:YES];
						});	
					}
					
					// check messages unread
					if([message isUnread] && isKeyWindow) {
						[message setUnread:NO];
						changedUnread = YES;
					}
				}
			}
			
			// check conversation unread
			if([_conversation isUnread] && isKeyWindow) {
				[_conversation setUnread:NO];
				changedUnread = YES;
			}
		}
		
		// notify in the main thread: messages changed
		dispatch_sync(dispatch_get_main_queue(), ^{	
			if(changedUnread)
				[[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
		});
	}];
	
	// add operation to the queue if still valid
	if(![operation isCancelled])
		[_loadingQueue addOperation:operation];
}




@end









@implementation WCConversationController

- (id)init {
	self = [super init];
	
	_loadingQueue = [[NSOperationQueue alloc] init];

	_messageStatusDateFormatter = [[WIDateFormatter alloc] init];
	[_messageStatusDateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[_messageStatusDateFormatter setDateStyle:NSDateFormatterLongStyle];
	
	_messageTimeDateFormatter = [[WIDateFormatter alloc] init];
	[_messageTimeDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	return self;
}



- (void)dealloc {
	[_conversation release];
	[_loadingQueue release];
	
	[_font release];
	[_textColor release];
	[_backgroundColor release];
	
	[_messageStatusDateFormatter release];
	[_messageTimeDateFormatter release];
	
	[super dealloc];
}


- (void)awakeFromNib {
	NSDictionary			*theme;
	WITemplateBundle		*template;
	NSString				*htmlPath;
	
	[_conversationWebView setUIDelegate:self];
    [_conversationWebView setFrameLoadDelegate:self];
	[_conversationWebView setResourceLoadDelegate:self];
	[_conversationWebView setPolicyDelegate:self];
    	
	// load the HTML default page following selected Themes > Templates
	theme			= [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	template		= [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];
	htmlPath		= [template htmlPathForType:WITemplateTypeMessages];
    	
    [[_conversationWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
}





#pragma mark -

- (void)setConversation:(WCConversation *)conversation {
	[conversation retain];
	[_conversation release];

	_conversation	= conversation;
}



- (WCConversation *)conversation {
	return _conversation;
}



- (void)setTemplatePath:(NSString *)path {
	[path retain];
	[_templatePath release];
	
	_templatePath = path;
}


- (NSString *)templatePath {
	return _templatePath;
}



- (void)setFont:(NSFont *)font {
	[font retain];
	[_font release];
	
	_font = font;
}



- (NSFont *)font {
	return _font;
}



- (void)setTextColor:(NSColor *)textColor {
	[textColor retain];
	[_textColor release];
	
	_textColor = textColor;
}



- (NSColor *)textColor {
	return _textColor;
}



- (void)setBackgroundColor:(NSColor *)backgroundColor {
	[backgroundColor retain];
	[_backgroundColor release];
	
	_backgroundColor = backgroundColor;
}



- (NSColor *)backgroundColor {
	return _backgroundColor;
}





#pragma mark -

- (LNWebView *)conversationWebView {
	return _conversationWebView;
}

- (NSString *)HTMLString {
    return [[[NSString alloc] initWithData:[[[_conversationWebView mainFrame] dataSource] data] 
                                  encoding:NSUTF8StringEncoding] autorelease];
}






#pragma mark -

- (void)appendMessage:(WCMessage *)message {
    NSMutableDictionary		*icons;
	NSMutableString			*mutableMessage;
    NSString				*icon, *messageTemplate;
    WCDOMMessage			*messageElement;
	WITemplateBundle		*template;
	NSError					*error;
	BOOL					changedUnread = NO, isKeyWindow;
	
	template		= [[WCSettings settings] templateBundleWithIdentifier:[[[_conversation connection] theme] objectForKey:WCThemesTemplate]];
	messageTemplate = [NSString stringWithContentsOfFile:[template pathForResource:@"Message" ofType:@"html" inDirectory:@"htdocs"] encoding:NSUTF8StringEncoding error:&error];;

    if(_conversation && ![_conversation isExpandable]) {
        icons       = [NSMutableDictionary dictionary];
        icon        = [icons objectForKey:[NSNumber numberWithInt:[[message user] userID]]];
        isKeyWindow = ([NSApp keyWindow] == [_conversationWebView window]);
        
        if(!icon) {
            icon    = [[[[message user] icon] TIFFRepresentation] base64EncodedString];
            
            if(icon)
                [icons setObject:icon forKey:[NSNumber numberWithInt:[[message user] userID]]];
        }
		
		mutableMessage = [NSMutableString stringWithString:[message message]];
	

		[WCChatController applyHTMLEscapingToMutableString:mutableMessage];
		[WCChatController applyHTMLTagsForURLToMutableString:mutableMessage];
		
		if([[[_conversation connection] theme] boolForKey:WCThemesShowSmileys])
			[WCChatController applyHTMLTagsForSmileysToMutableString:mutableMessage];
		
		[mutableMessage replaceOccurrencesOfString:@"\n" withString:@"<br />\n"];

		messageElement = [WCDOMMessage messageElementForFrame:[_conversationWebView mainFrame] withTemplate:messageTemplate];
		[messageElement setServer:[message connectionName]];
		[messageElement setTime:[_messageTimeDateFormatter stringFromDate:[message date]]];
		[messageElement setNick:[message nick]];
		
		if([message direction] == WCMessageTo)
			[messageElement setDirection:@"to"];
		else
			[messageElement setDirection:@"from"];
		
		[messageElement setIcon:[NSSWF:@"data:image/tiff;base64,%@", icon]];
		[messageElement setMessageContent:mutableMessage];
		
		[_conversationWebView appendElement:[messageElement element] 
					toBottomOfElementWithID:@"messages-content" 
									 scroll:YES];
				
        if([message isUnread] && isKeyWindow) {
            [message setUnread:NO];
            
            changedUnread = YES;
        }
        if([_conversation isUnread] && isKeyWindow) {
            [_conversation setUnread:NO];
            
            changedUnread = YES;
        }
        if(changedUnread)
            [[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
    }
}



- (void)appendCommand:(WCMessage *)message {
	NSMutableDictionary		*icons;
	NSMutableString			*mutableMessage;
    NSString				*icon, *messageTemplate;
    WCDOMMessage			*messageElement;
	WITemplateBundle		*template;
	NSError					*error;
	BOOL					changedUnread = NO, isKeyWindow;
	
	template		= [[WCSettings settings] templateBundleWithIdentifier:[[[_conversation connection] theme] objectForKey:WCThemesTemplate]];
	messageTemplate = [NSString stringWithContentsOfFile:[template pathForResource:@"Message" ofType:@"html" inDirectory:@"htdocs"] encoding:NSUTF8StringEncoding error:&error];;
	
    if(_conversation && ![_conversation isExpandable]) {
        icons       = [NSMutableDictionary dictionary];
        icon        = [icons objectForKey:[NSNumber numberWithInt:[[message user] userID]]];
        isKeyWindow = ([NSApp keyWindow] == [_conversationWebView window]);
        
        if(!icon) {
            icon    = [[[[message user] icon] TIFFRepresentation] base64EncodedString];
            
            if(icon)
                [icons setObject:icon forKey:[NSNumber numberWithInt:[[message user] userID]]];
        }
		
		mutableMessage = [NSMutableString stringWithString:[message message]];
		
		[mutableMessage replaceOccurrencesOfString:@"\n" withString:@"<br />\n"];
		
		messageElement = [WCDOMMessage messageElementForFrame:[_conversationWebView mainFrame] withTemplate:messageTemplate];
		[messageElement setServer:[message connectionName]];
		[messageElement setTime:[_messageTimeDateFormatter stringFromDate:[message date]]];
		[messageElement setNick:[message nick]];
		
		if([message direction] == WCMessageTo)
			[messageElement setDirection:@"to"];
		else
			[messageElement setDirection:@"from"];
		
		[messageElement setIcon:[NSSWF:@"data:image/tiff;base64,%@", icon]];
		[messageElement setMessageContent:mutableMessage];
		
		[_conversationWebView appendElement:[messageElement element] 
					toBottomOfElementWithID:@"messages-content" 
									 scroll:YES];
		
        if([message isUnread] && isKeyWindow) {
            [message setUnread:NO];
            
            changedUnread = YES;
        }
        if([_conversation isUnread] && isKeyWindow) {
            [_conversation setUnread:NO];
            
            changedUnread = YES;
        }
        if(changedUnread)
            [[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
    }
}



- (void)reloadData {
	
	[_loadingQueue cancelAllOperations];
	
	[self _reloadDataAsynchronously];
}


- (void)reloadTemplate {
	WITemplateBundle			*template;
	
	template		= [WITemplateBundle templateWithPath:_templatePath];

	// reload CSS in the main thread
	[template setCSSValue:[_font fontName] toAttribute:WITemplateAttributesFontName ofType:WITemplateTypeMessages];
	[template setCSSValue:[NSSWF:@"%.0fpx", [_font pointSize]] toAttribute:WITemplateAttributesFontSize ofType:WITemplateTypeMessages];
	[template setCSSValue:[NSSWF:@"#%.6x", [_textColor HTMLValue]] toAttribute:WITemplateAttributesFontColor ofType:WITemplateTypeMessages];
	[template setCSSValue:[NSSWF:@"#%.6x", [_backgroundColor HTMLValue]] toAttribute:WITemplateAttributesBackgroundColor ofType:WITemplateTypeMessages];
	
	[template saveChangesForType:WITemplateTypeMessages];
	
	[_conversationWebView reloadStylesheetWithID:@"wc-stylesheet"
									withTemplate:template
											type:WITemplateTypeMessages];
}






#pragma mark -

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {
	[webView scrollToBottom];
}



- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)action request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
    
    NSString			*path;
    NSURL               *url;
	WIURL				*wiredURL;
	WCFile				*file;
	BOOL				handled     = NO;
	BOOL                isDirectory = NO;
    
	if([[action objectForKey:WebActionNavigationTypeKey] unsignedIntegerValue] == WebNavigationTypeOther) {
		[listener use];
	} else {
		[listener ignore];
        
        url         = [action objectForKey:WebActionOriginalURLKey];
		wiredURL    = [WIURL URLWithURL:url];
        
        isDirectory = [[url absoluteString] hasSuffix:@"/"] ? YES : NO;
		
		if([[wiredURL scheme] isEqualToString:@"wired"] || [[wiredURL scheme] isEqualToString:@"wiredp7"]) {
			if([[wiredURL host] length] == 0) {
				if([_conversation connection] && [[_conversation connection] isConnected]) {
					path = [[wiredURL path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					if(isDirectory) {
                        
						file = [WCFile fileWithDirectory:path connection:[_conversation connection]];
						[WCFiles filesWithConnection:[_conversation connection] file:file];
                        
					} else {
                        file = [WCFile fileWithFile:path connection:[_conversation connection]];
                        [[WCTransfers transfers] downloadFiles:[NSArray arrayWithObject:file] 
                                                      toFolder:[[[WCSettings settings] objectForKey:WCDownloadFolder] stringByStandardizingPath]];
					}
				}
				
				handled = YES;
			}
		}
		
		if(!handled)
			[[NSWorkspace sharedWorkspace] openURL:[action objectForKey:WebActionOriginalURLKey]];
	}
}



- (NSArray *)webView:(WebView *)webView contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	return NULL;
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
    // useless but required
}


@end
