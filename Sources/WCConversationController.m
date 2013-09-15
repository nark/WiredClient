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
#import "WDWiredModel.h"
#import "WCDatabaseController.h"

#import "SBJsonWriter+WCJsonWriter.h"
#import "NSManagedObjectContext+Fetch.h"


#define WC_MESSAGES_STATUS_INTERVAL 60*60*24





@implementation WCConversationController

- (id)init {
	self = [super init];
	
	_loadingQueue = [[NSOperationQueue alloc] init];
    _conversation = nil;

	_messageStatusDateFormatter = [[WIDateFormatter alloc] init];
	[_messageStatusDateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[_messageStatusDateFormatter setDateStyle:NSDateFormatterLongStyle];
	
	_messageTimeDateFormatter = [[WIDateFormatter alloc] init];
	[_messageTimeDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	return self;
}



- (void)dealloc {
	[_loadingQueue release];
	
	[_font release];
	[_textColor release];
	[_backgroundColor release];
	
	[_messageStatusDateFormatter release];
	[_messageTimeDateFormatter release];
    
    [_conversation release];
	
	[super dealloc];
}


- (void)awakeFromNib {
	[_conversationWebView setUIDelegate:self];
    [_conversationWebView setFrameLoadDelegate:self];
	[_conversationWebView setResourceLoadDelegate:self];
	[_conversationWebView setPolicyDelegate:self];
}





#pragma mark -

- (void)setConversation:(WDConversation *)conversation {
    [conversation retain];
	[_conversation release];
    
	_conversation	= conversation;
}

- (WDConversation *)conversation {
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

- (WebView *)conversationWebView {
	return _conversationWebView;
}

- (NSString *)HTMLString {
    return [[[NSString alloc] initWithData:[[[_conversationWebView mainFrame] dataSource] data] 
                                  encoding:NSUTF8StringEncoding] autorelease];
}






#pragma mark -

- (void)appendMessage:(WDMessage *)message {
    SBJsonWriter    *jsonWriter;
    NSString        *jsonString;
    
    jsonWriter      = [[SBJsonWriter alloc] init];
    jsonString      = [jsonWriter stringWithObject:message];
    
    [jsonWriter release];
    
    [_conversationWebView stringByEvaluatingJavaScriptFromString:
            [NSSWF:@"printMessage(%@);", jsonString]];
}



- (void)appendCommand:(WDMessage *)message {
//	NSMutableDictionary		*icons;
//	NSMutableString			*mutableMessage;
//    NSString				*icon, *messageTemplate;
//    WCDOMMessage			*messageElement;
//	WITemplateBundle		*template;
//	NSError					*error;
//	BOOL					changedUnread = NO, isKeyWindow;
//	
//	template		= [[WCSettings settings] templateBundleWithIdentifier:[[[_conversation connection] theme] objectForKey:WCThemesTemplate]];
//	messageTemplate = [NSString stringWithContentsOfFile:[template pathForResource:@"Message" ofType:@"html" inDirectory:@"htdocs"] encoding:NSUTF8StringEncoding error:&error];;
//	
//    if(_conversation && ![_conversation isExpandable]) {
//        icons       = [NSMutableDictionary dictionary];
//        icon        = [icons objectForKey:[NSNumber numberWithInt:[[message user] userID]]];
//        isKeyWindow = ([NSApp keyWindow] == [_conversationWebView window]);
//        
//        if(!icon) {
//            icon    = [[[[message user] icon] TIFFRepresentation] base64EncodedString];
//            
//            if(icon)
//                [icons setObject:icon forKey:[NSNumber numberWithInt:[[message user] userID]]];
//        }
//		
//		mutableMessage = [NSMutableString stringWithString:[message message]];
//		
//		[mutableMessage replaceOccurrencesOfString:@"\n" withString:@"<br />\n"];
//		
//		messageElement = [WCDOMMessage messageElementForFrame:[_conversationWebView mainFrame] withTemplate:messageTemplate];
//		[messageElement setServer:[message connectionName]];
//		[messageElement setTime:[_messageTimeDateFormatter stringFromDate:[message date]]];
//		[messageElement setNick:[message nick]];
//		
//		if([message direction] == WCMessageTo)
//			[messageElement setDirection:@"to"];
//		else
//			[messageElement setDirection:@"from"];
//		
//		[messageElement setIcon:[NSSWF:@"data:image/tiff;base64,%@", icon]];
//		[messageElement setMessageContent:mutableMessage];
//		
//		[_conversationWebView appendElement:[messageElement element] 
//					toBottomOfElementWithID:@"messages-content" 
//									 scroll:YES];
//		
//        if([message isUnread] && isKeyWindow) {
//            [message setUnread:NO];
//            
//            changedUnread = YES;
//        }
//        if([_conversation isUnread] && isKeyWindow) {
//            [_conversation setUnread:NO];
//            
//            changedUnread = YES;
//        }
//        if(changedUnread)
//            [[NSNotificationCenter defaultCenter] postNotificationName:WCMessagesDidChangeUnreadCountNotification];
//    }
}



- (void)reloadData {
    NSURL                       *url;
    WITemplateBundle            *template;
    BOOL						isKeyWindow;
    
    template        = [WITemplateBundle templateWithPath:_templatePath];
    isKeyWindow     = ([NSApp keyWindow] == [_conversationWebView window]);
    
    if(template) {
        url = [NSURL fileURLWithPath: [template pathForResource:@"messages"
                                                         ofType:@"html"
                                                    inDirectory:@"htdocs"]];
        
        [[_conversationWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
    }
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
    WITemplateBundle *template = [WITemplateBundle templateWithPath:_templatePath];
    
    NSURL *jqueryURL    = [NSURL fileURLWithPath:[template pathForResource:@"jquery" ofType:@"js" inDirectory:@"htdocs/js"]];
    NSURL *functionsURL = [NSURL fileURLWithPath:[template pathForResource:@"functions" ofType:@"js" inDirectory:@"htdocs/js"]];
    NSURL *mainURL      = [NSURL fileURLWithPath:[template pathForResource:@"main" ofType:@"js" inDirectory:@"htdocs/js"]];

    [[webView windowScriptObject] setValue:self forKey:@"Controller"];
        
    [_conversationWebView appendScriptAtURL:jqueryURL];
    [_conversationWebView appendScriptAtURL:functionsURL];
    [_conversationWebView appendScriptAtURL:mainURL];
        
    [_conversationWebView scrollToBottom];
}



- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)action request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
    WDConversation      *conversation;
    NSString			*path;
    NSURL               *url;
	WIURL				*wiredURL;
	WCFile				*file;
	BOOL				handled     = NO;
	BOOL                isDirectory = NO;
    
    conversation        = [self conversation];
    
	if([[action objectForKey:WebActionNavigationTypeKey] unsignedIntegerValue] == WebNavigationTypeOther) {
		[listener use];
	} else {
		[listener ignore];
        
        url         = [action objectForKey:WebActionOriginalURLKey];
		wiredURL    = [WIURL URLWithURL:url];
        
        isDirectory = [[url absoluteString] hasSuffix:@"/"] ? YES : NO;
		
		if([[wiredURL scheme] isEqualToString:@"wired"] || [[wiredURL scheme] isEqualToString:@"wiredp7"]) {
			if([[wiredURL host] length] == 0) {
				if([conversation connection] && [[conversation connection] isConnected]) {
					path = [[wiredURL path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					if(isDirectory) {
                        [WCFiles filesWithConnection:[conversation connection]
                                                file:[WCFile fileWithDirectory:[path stringByDeletingLastPathComponent] connection:[conversation connection]]
                                          selectFile:[WCFile fileWithDirectory:path connection:[conversation connection]]];
                        
					} else {
                        file = [WCFile fileWithFile:path connection:[conversation connection]];
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
#ifdef WCConfigurationRelease
    return NULL;
#else
    return defaultMenuItems;
#endif
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
    // useless but required
}




#pragma mark -

+ (NSString *)webScriptNameForSelector:(SEL)selector
{
    NSString *name;
    
    if (selector == @selector(loadScriptWithName:))
        name = @"loadScriptWithName";
    if (selector == @selector(JSONObjectsUntilDate:withLimit:))
        name = @"JSONObjectsUntilDateWithLimit";
    if (selector == @selector(lastMessageDate))
        name = @"lastMessageDate";
    
    return name;
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    if (selector == @selector(loadScriptWithName:)) return NO;
    if (selector == @selector(JSONObjectsUntilDate:withLimit:)) return NO;
    if (selector == @selector(lastMessageDate)) return NO;
    return YES;
}





#pragma mark -

- (BOOL)loadScriptWithName:(NSString *)name {
    WITemplateBundle        *template;
    NSURL                   *scriptURL;
    
    template    = [WITemplateBundle templateWithPath:_templatePath];
    scriptURL   = [NSURL fileURLWithPath:[template pathForResource:name ofType:@"js" inDirectory:@"htdocs/js"]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[scriptURL path]])
        return NO;
    
    [_conversationWebView appendScriptAtURL:scriptURL];
    
    return YES;
}


- (NSString *)lastMessageDate {
    NSDateFormatter     *dateFormatter;
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
    
    return [dateFormatter stringFromDate:[_conversation date]];
}


- (NSString *)JSONObjectsUntilDate:(NSString *)dateString withLimit:(NSUInteger)limit {
    NSPredicate         *predicate;
    NSSortDescriptor    *descriptor;
    NSDate              *date;
    NSDateFormatter     *dateFormatter;
    NSString            *jsonString;
    NSArray             *sortedMessages;
    
    dateFormatter   = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
    
    
    if(dateString != nil) {
        date            = [dateFormatter dateFromString:dateString];    
    } else {
        date            = [_conversation date];
    }
    
    if(!date) {
        return nil;
    }

    
    predicate       = [NSPredicate predicateWithFormat:@"(conversation == %@) && (date <= %@)", _conversation, date];
    descriptor      = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    sortedMessages  = [[WCDatabaseController context] fetchEntitiesNammed:@"Message"
                                                            withPredicate:predicate
                                                               descriptor:descriptor
                                                                    limit:limit
                                                                    error:nil];
    
    jsonString      = [[SBJsonWriter writer] stringWithObject:sortedMessages];
    
    
    [dateFormatter release];
    
    return jsonString;
}

@end
