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

#import "WCAccount.h"
#import "WCApplicationController.h"
#import "WCBoard.h"
#import "WCBoardPost.h"
#import "WCBoards.h"
#import "WCBoardThread.h"
#import "WCBoardThreadController.h"
#import "WCChatController.h"
#import "WCFile.h"
#import "WCFiles.h"
#import "WCTransfers.h"



@interface WCBoardThreadController(Private)


- (void)_reloadDataAndScrollToCurrentPosition:(BOOL)scrollToCurrentPosition selectPost:(WCBoardPost *)selectPost;

- (void)_setTitle:(NSString *)title;

@end





@implementation WCBoardThreadController(Private)

- (void)_reloadDataAndScrollToCurrentPosition:(BOOL)scrollToCurrentPosition selectPost:(WCBoardPost *)selectPost {
    NSURL                       *url;
    NSDictionary                *theme;
    WITemplateBundle            *template;
    
    // get theme and template
    theme			= [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	template		= [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];
	
    //[self reloadTemplate];
    
    // load the webView
    if(template) {
        url = [NSURL fileURLWithPath: [template pathForResource:@"boards"
                                                         ofType:@"html"
                                                    inDirectory:@"htdocs"]];
        
        [[_threadWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
    }
}



- (void)_setTitle:(NSString *)title {
	[_threadWebView stringByEvaluatingJavaScriptFromString:[NSSWF:@"document.title='%@'", title]];
}


@end





@implementation WCBoardThreadController

- (id)init {
	self = [super initWithNibName:@"ThreadView" bundle:nil];
		
	_loadingQueue = [[NSOperationQueue alloc] init];
	[_loadingQueue setMaxConcurrentOperationCount:1];
	
	_dateFormatter		= [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	_fileLinkBase64String		= [[[[NSImage imageNamed:@"FileLink"] TIFFRepresentation] base64EncodedString] retain];
	_unreadPostBase64String		= [[[[NSImage imageNamed:@"UnreadPost"] TIFFRepresentation] base64EncodedString] retain];
	_defaultIconBase64String	= [[[[NSImage imageNamed:@"DefaultIcon"] TIFFRepresentation] base64EncodedString] retain];
	
	_smileyBase64Strings		= [[NSMutableDictionary alloc] init];
	
	return self;
}



- (void)dealloc {
	[_thread release];
	
	[_loadingQueue release];
	
	[_fileLinkBase64String release];
	[_unreadPostBase64String release];
	[_defaultIconBase64String release];
	
	[_font release];
	[_textColor release];
	[_backgroundColor release];
	
	[_dateFormatter release];
	
	[_selectPost release];
	
	[super dealloc];
}




- (void)awakeFromNib {    
	[_threadWebView setUIDelegate:(id)self];
    [_threadWebView setFrameLoadDelegate:(id)self];
	[_threadWebView setResourceLoadDelegate:(id)self];
	[_threadWebView setPolicyDelegate:(id)self];
    
    [self reloadData];
}




#pragma mark -

- (void)webView:(WebView *)webView didCommitLoadForFrame:(WebFrame *)frame {
}

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
    mainURL         = [NSURL fileURLWithPath:[template pathForResource:@"boards" ofType:@"js" inDirectory:@"htdocs/js"]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[jqueryURL path]] ||
       ![[NSFileManager defaultManager] fileExistsAtPath:[functionsURL path]] ||
       ![[NSFileManager defaultManager] fileExistsAtPath:[mainURL path]])
    {
        NSLog(@"Error: Invalid template. Missing script. (%@)", _templatePath);
        return;
    }
    
    [_threadWebView appendScriptAtURL:jqueryURL];
    [_threadWebView appendScriptAtURL:functionsURL];
    [_threadWebView appendScriptAtURL:mainURL];
}



- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
    [[_threadWebView windowScriptObject] setValue:[WCBoards boards] forKey:@"Controller"];
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
				if([[_thread connection] isConnected]) {
					path = [[wiredURL path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					if(isDirectory) {
                        [WCFiles filesWithConnection:[_thread connection]
                                                file:[WCFile fileWithDirectory:[path stringByDeletingLastPathComponent] connection:[_thread connection]]
                                          selectFile:[WCFile fileWithDirectory:path connection:[_thread connection]]];
                        
					} else {
                        file = [WCFile fileWithFile:path connection:[_thread connection]];
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

- (void)setBoard:(WCBoard *)board {
	[board retain];
	[_board release];
	
	[_loadingQueue cancelAllOperations];
	
	_board = board;
}



- (WCBoard *)board {
	return _board;
}



- (void)setThread:(WCBoardThread *)thread {
	[thread retain];
	[_thread release];
	
	[_loadingQueue cancelAllOperations];
	
	_thread = thread;
}



- (WCBoardThread *)thread {
	return _thread;
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

- (WebView *)threadWebView {
	return _threadWebView;
}



- (NSString *)HTMLString {
	return [[[NSString alloc] initWithData:[[[_threadWebView mainFrame] dataSource] data] 
                                  encoding:NSUTF8StringEncoding] autorelease];
}



#pragma mark -

- (void)reloadData {
    [self _reloadDataAndScrollToCurrentPosition:YES selectPost:NULL];
}



- (void)reloadDataAndScrollToCurrentPosition {
    [self _reloadDataAndScrollToCurrentPosition:YES selectPost:NULL];
}



- (void)reloadDataAndSelectPost:(WCBoardPost *)selectPost {
//    NSArray *syms = [NSThread  callStackSymbols];
//    if ([syms count] > 1) {
//        NSLog(@"<%@ %p> %@ - caller: %@ ", [self class], self, NSStringFromSelector(_cmd),[syms objectAtIndex:1]);
//    } else {
//        NSLog(@"<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd));
//    }
    [self _reloadDataAndScrollToCurrentPosition:NO selectPost:selectPost];
}




#pragma mark -
#pragma mark Reload CSS Template

- (void)reloadTemplate {
	WITemplateBundle	*template;
	
	template			= [WITemplateBundle templateWithPath:_templatePath];
	
	[template setCSSValue:[_font fontName] toAttribute:WITemplateAttributesFontName ofType:WITemplateTypeBoards];
	[template setCSSValue:[NSSWF:@"%.0fpx", [_font pointSize]] toAttribute:WITemplateAttributesFontSize ofType:WITemplateTypeBoards];
	[template setCSSValue:[NSSWF:@"#%.6x", (unsigned int)[_textColor HTMLValue]] toAttribute:WITemplateAttributesFontColor ofType:WITemplateTypeBoards];
	[template setCSSValue:[NSSWF:@"#%.6x", (unsigned int)[_backgroundColor HTMLValue]] toAttribute:WITemplateAttributesBackgroundColor ofType:WITemplateTypeBoards];
	
	[template saveChangesForType:WITemplateTypeBoards];
	
	[_threadWebView reloadStylesheetWithID:@"wc-stylesheet"
							  withTemplate:template
									  type:WITemplateTypeBoards];
}


@end
