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
#import "WDWiredModel.h"
#import "WCDatabaseController.h"

#import "SBJsonWriter+WCJsonWriter.h"
#import "NSManagedObjectContext+Fetch.h"




@implementation WCConversationController

- (id)init {
	self = [super init];
	
    _conversation = nil;
	
	return self;
}



- (void)dealloc {
    
	[_font release];
	[_textColor release];
	[_backgroundColor release];
    
    [_conversation release];
	
	[super dealloc];
}


- (void)awakeFromNib {
	[_conversationWebView setUIDelegate:(id)self];
    [_conversationWebView setFrameLoadDelegate:(id)self];
	[_conversationWebView setResourceLoadDelegate:(id)self];
	[_conversationWebView setPolicyDelegate:(id)self];
    [_conversationWebView registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    [self reloadData];
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
    [_conversationWebView stringByEvaluatingJavaScriptFromString:
            [NSSWF:@"printMessage(%@);", [[SBJson4Writer writer] stringWithObject:message]]];
}





#pragma mark -

- (void)reloadData {
    NSURL                       *url;
    WITemplateBundle            *template;
    
    template        = [WITemplateBundle templateWithPath:_templatePath];
    
    if(template) {
        url = [NSURL fileURLWithPath: [template pathForResource:@"messages"
                                                         ofType:@"html"
                                                    inDirectory:@"htdocs"]];
        
        [[_conversationWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
    }
}


- (void)reloadTemplate {
	WITemplateBundle			*template;
	
	template  = [WITemplateBundle templateWithPath:_templatePath];

	// reload CSS in the main thread
	[template setCSSValue:[_font fontName]
              toAttribute:WITemplateAttributesFontName
                   ofType:WITemplateTypeMessages];
    
	[template setCSSValue:[NSSWF:@"%.0fpx", [_font pointSize]]
              toAttribute:WITemplateAttributesFontSize
                   ofType:WITemplateTypeMessages];
    
	[template setCSSValue:[NSSWF:@"#%.6lx", (unsigned long)[_textColor HTMLValue]]
              toAttribute:WITemplateAttributesFontColor
                   ofType:WITemplateTypeMessages];
    
	[template setCSSValue:[NSSWF:@"#%.6lx", (unsigned long)[_backgroundColor HTMLValue]]
              toAttribute:WITemplateAttributesBackgroundColor
                   ofType:WITemplateTypeMessages];
	
	[template saveChangesForType:WITemplateTypeMessages];
	
	[_conversationWebView reloadStylesheetWithID:@"wc-stylesheet"
									withTemplate:template
											type:WITemplateTypeMessages];
}






#pragma mark -

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {
    WITemplateBundle    *template;
    NSURL               *jqueryURL, *functionsURL, *mainURL;
 
    template        = [WITemplateBundle templateWithPath:_templatePath];
    
    if(!template) {
        NSLog(@"Error: Template not found. (%@)", _templatePath);
        return;
    }
    
    jqueryURL       = [NSURL fileURLWithPath:[template pathForResource:@"jquery" ofType:@"js" inDirectory:@"htdocs/js"]];
    functionsURL    = [NSURL fileURLWithPath:[template pathForResource:@"functions" ofType:@"js" inDirectory:@"htdocs/js"]];
    mainURL         = [NSURL fileURLWithPath:[template pathForResource:@"messages" ofType:@"js" inDirectory:@"htdocs/js"]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[jqueryURL path]] ||
       ![[NSFileManager defaultManager] fileExistsAtPath:[functionsURL path]] ||
       ![[NSFileManager defaultManager] fileExistsAtPath:[mainURL path]])
    {
        NSLog(@"Error: Invalid template. Missing script. (%@)", _templatePath);
        return;
    }

    [[_conversationWebView windowScriptObject] setValue:self forKey:@"Controller"];
        
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
    NSData              *fileData;
    NSImage             *droppedImage;
	BOOL				handled     = NO;
	BOOL                isDirectory = NO;
    
    conversation        = [self conversation];
    
	if([[action objectForKey:WebActionNavigationTypeKey] unsignedIntegerValue] == WebNavigationTypeLinkClicked) {
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

- (NSUInteger)webView:(WebView *)webView
dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)draggingInfo {
    return WebDragDestinationActionLoad;
}
    
    
- (void)_sendLocalImage:(NSURL *)url {
    NSString            *html;
    NSString            *base64ImageString;
    NSData              *imageData;
    
    imageData = [NSData dataWithContentsOfURL:url];
    base64ImageString = [imageData base64EncodedString];
    
    html = [NSSWF:@"<img src='data:image/png;base64, %@'/>", base64ImageString];
    
    if(html && [html length] > 0) {
         [[WCMessages messages] sendMessage:html toUser:self.conversation.user];
    }
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
    
    dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]];
    
    return [dateFormatter stringFromDate:[_conversation date]];
}


- (NSString *)JSONObjectsUntilDate:(NSString *)dateString withLimit:(NSUInteger)limit {
    NSPredicate         *predicate;
    NSSortDescriptor    *descriptor;
    NSDate              *date;
    NSDateFormatter     *dateFormatter;
    NSString            *jsonString;
    NSArray             *sortedMessages;
    NSCalendar          *calendar;
    
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setCalendar:calendar];
    
    if(dateString != nil) {
        date = [dateFormatter dateFromString:dateString];    
    } else {
        date = [_conversation date];
    }
    
    if(!date) {
        [dateFormatter release];
        [calendar release];
        return nil;
    }
    
    predicate       = [NSPredicate predicateWithFormat:@"(conversation == %@) && (date <= %@)", _conversation, date];
    descriptor      = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    sortedMessages  = [[WCDatabaseController context] fetchEntitiesNammed:@"Message"
                                                            withPredicate:predicate
                                                               descriptor:descriptor
                                                                    limit:limit
                                                                    error:nil];
    
    jsonString      = [[SBJson4Writer writer] stringWithObject:sortedMessages];
    
    [descriptor release];
    [dateFormatter release];
    [calendar release];
    
    //NSLog(@"jsonString: %@", jsonString);
    
    return jsonString;
}

@end
