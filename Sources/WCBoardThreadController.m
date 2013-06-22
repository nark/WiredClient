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
#import "WCDOMPostElement.h"
#import "WCDOMPostReplyElement.h"


@interface WCBoardThreadController(Private)


- (void)_reloadDataAndScrollToCurrentPosition:(BOOL)scrollToCurrentPosition selectPost:(WCBoardPost *)selectPost;

- (void)_setTitle:(NSString *)title;

- (void)_appendHTMLElementForReadPostIDs:(NSSet **)readPostIDs;
- (void)_appendHTMLElementForPost:(id)post writable:(BOOL)writable;

@end





@implementation WCBoardThreadController(Private)

- (void)_reloadDataAndScrollToCurrentPosition:(BOOL)scrollToCurrentPosition selectPost:(WCBoardPost *)selectPost {
	NSSet				*readPostIDs;

	[self reloadTemplate];
	
	if(scrollToCurrentPosition)
		_previousVisibleRect = [[[[[_threadWebView mainFrame] frameView] documentView] enclosingScrollView] documentVisibleRect];
	else
		_previousVisibleRect = NSZeroRect;
	
	[_selectPost release];
	_selectPost = [selectPost retain];
	
	if(_thread) {
		[self _appendHTMLElementForReadPostIDs:&readPostIDs];
	} else {
		readPostIDs = NULL;
		[_threadWebView clearChildrenElementsOfElementWithID:@"thread-content"];
	}
}



- (void)_setTitle:(NSString *)title {
	[_threadWebView stringByEvaluatingJavaScriptFromString:[NSSWF:@"document.title='%@'", title]];
}




#pragma mark -

- (void)_appendHTMLElementForReadPostIDs:(NSSet **)readPostIDs {
	NSError					*error;
	NSEnumerator			*enumerator;
	NSMutableSet			*set;
	__block WCBoardPost		*post;
	__block WCDOMPostReplyElement	*postReplyElement;
	NSString				*replyTemplate;
	NSBundle				*template;
	BOOL					writable, isKeyWindow;
	
	template			= [NSBundle bundleWithPath:_templatePath];
	replyTemplate		= [NSString stringWithContentsOfFile:[template pathForResource:@"BoardReply" ofType:@"html" inDirectory:@"htdocs"] encoding:NSUTF8StringEncoding error:&error];	
	
	// set the page title
	[self _setTitle:[_thread subject]];
	
	isKeyWindow		= ([NSApp keyWindow] == [_threadWebView window]);
	set				= [NSMutableSet set];
	enumerator		= [[_thread posts] reverseObjectEnumerator];
	writable		= [_board isWritable];
		
	if([_thread text]) {
		__block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
			
			dispatch_sync(dispatch_get_main_queue(), ^{
				[_threadWebView clearChildrenElementsOfElementWithID:@"thread-content"];
			});
						  
			// append posts thread sub elements
			while((post = [enumerator nextObject]) && ![operation isCancelled]) {
				
				if(![operation isCancelled])
					[self _appendHTMLElementForPost:post writable:writable];
				
				dispatch_sync(dispatch_get_main_queue(), ^{
					if(isKeyWindow) {
						[post setUnread:NO];
						
						[set addObject:[post postID]];
					}
				});
			}
			
			// append thread element
			if(![operation isCancelled]) {
				[self _appendHTMLElementForPost:_thread writable:writable];
			
				dispatch_sync(dispatch_get_main_queue(), ^{
					if(isKeyWindow) {
						[_thread setUnread:NO];
						
						[set addObject:[_thread threadID]];
					}
					
					// append post reply element
					postReplyElement	= [WCDOMPostReplyElement postReplyElementForFrame:[_threadWebView mainFrame] withTemplate:replyTemplate];	
					
					if(([[[_thread connection] account] boardAddPosts] && writable) ||
                       [[[WCBoards boards] selectedBoard] isKindOfClass:[WCSmartBoard class]]) {
                        
						[postReplyElement setReplyEnabled:YES];
					}
                    else {
						[postReplyElement setReplyEnabled:NO];
					}
                    
					[postReplyElement setReplyString:NSLS(@"Post Reply", @"Post reply button title")];
					
					[_threadWebView appendElement:[postReplyElement element] toBottomOfElementWithID:@"thread-content" scroll:YES];
				});
			}
		}];
		
		[operation setCompletionBlock:^{
			dispatch_sync(dispatch_get_main_queue(), ^{
				
				//if(readPostIDs)
					*readPostIDs = set;
//				
//				NSLog(@"thread loaded: %@", set);
//				NSLog(@"readPostIDs: %@", *readPostIDs);
//				
				if([*readPostIDs count] > 0)
					[[NSNotificationCenter defaultCenter] postNotificationName:WCBoardsDidChangeUnreadCountNotification object:*readPostIDs];
			});
		}];
				
		if(![operation isCancelled])
			[_loadingQueue addOperation:operation];
	}
}


- (void)_appendHTMLElementForPost:(id)post writable:(BOOL)writable {
	NSEnumerator				*enumerator;
	NSDictionary				*theme, *regexs;
	NSMutableString				*text, *regex;
	__block NSString			*substring, *smiley, *path, *icon, *smileyBase64String;
	WCAccount					*account;
	__block WCDOMPostElement	*postElement;
	NSString					*postTemplate;
	NSBundle					*template;
	NSError						*error;
	NSRange						range;
	__block BOOL				own;
	
	theme				= [post theme];
	template			= [NSBundle bundleWithPath:_templatePath];
	postTemplate		= [NSString stringWithContentsOfFile:[template pathForResource:@"BoardPost" ofType:@"html" inDirectory:@"htdocs"] encoding:NSUTF8StringEncoding error:&error];
	
	account				= [(WCServerConnection *) [post connection] account];
	text				= [[[post text] mutableCopy] autorelease];
	
	[text replaceOccurrencesOfString:@"&" withString:@"&#38;"];
	[text replaceOccurrencesOfString:@"<" withString:@"&#60;"];
	[text replaceOccurrencesOfString:@">" withString:@"&#62;"];
	[text replaceOccurrencesOfString:@"\"" withString:@"&#34;"];
	[text replaceOccurrencesOfString:@"\'" withString:@"&#39;"];
	[text replaceOccurrencesOfString:@"\n" withString:@"\n<br />\n"];
	
	[text replaceOccurrencesOfRegex:@"\\[code\\](.+?)\\[/code\\]"
						 withString:@"<blockquote><pre>$1</pre></blockquote>"
							options:RKLCaseless | RKLDotAll];
	
	while([text replaceOccurrencesOfRegex:@"<pre>(.*?)\\[+(.*?)</pre>"
							   withString:@"<pre>$1&#91;$2</pre>"
								  options:RKLCaseless | RKLDotAll] > 0)
		;
	
	while([text replaceOccurrencesOfRegex:@"<pre>(.*?)\\]+(.*?)</pre>"
							   withString:@"<pre>$1&#93;$2</pre>"
								  options:RKLCaseless | RKLDotAll] > 0)
		;
	
	while([text replaceOccurrencesOfRegex:@"<pre>(.*?)<br />\n(.*?)</pre>"
							   withString:@"<pre>$1$2</pre>"
								  options:RKLCaseless | RKLDotAll] > 0)
		;
	
	if([theme boolForKey:WCThemesShowSmileys]) {
		regexs		= [WCChatController smileyRegexs];
		enumerator	= [regexs keyEnumerator];
		
		while((smiley = [enumerator nextObject])) {
			regex				= [regexs objectForKey:smiley];
			path				= [[WCApplicationController sharedController] pathForSmiley:smiley];
			smileyBase64String	= [_smileyBase64Strings objectForKey:smiley];
			
			if(!smileyBase64String) {
				smileyBase64String = [[[NSImage imageWithContentsOfFile:path] TIFFRepresentation] base64EncodedString];
				
				[_smileyBase64Strings setObject:smileyBase64String forKey:smiley];
			}
			
			[text replaceOccurrencesOfRegex:[NSSWF:@"(^|\\s)%@(\\s|$)", regex]
								 withString:[NSSWF:@"$1<img src=\"data:image/tiff;base64,%@\" alt=\"%@\" />$2",
											 smileyBase64String, smiley]
									options:RKLCaseless | RKLMultiline];
		}
	}
	
	[text replaceOccurrencesOfRegex:@"\\[b\\](.+?)\\[/b\\]"
						 withString:@"<b>$1</b>"
							options:RKLCaseless | RKLDotAll];
	[text replaceOccurrencesOfRegex:@"\\[u\\](.+?)\\[/u\\]"
						 withString:@"<u>$1</u>"
							options:RKLCaseless | RKLDotAll];
	[text replaceOccurrencesOfRegex:@"\\[i\\](.+?)\\[/i\\]"
						 withString:@"<i>$1</i>"
							options:RKLCaseless | RKLDotAll];
	[text replaceOccurrencesOfRegex:@"\\[color=(.+?)\\](.+?)\\[/color\\]"
						 withString:@"<span style=\"color: $1\">$2</span>"
							options:RKLCaseless | RKLDotAll];
	[text replaceOccurrencesOfRegex:@"\\[center\\](.+?)\\[/center\\]"
						 withString:@"<div class=\"center\">$1</div>"
							options:RKLCaseless | RKLDotAll];
	
	/* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
	do {
		range = [text rangeOfRegex:@"\\[url]wiredp7://(/.+?)\\[/url\\]" options:RKLCaseless capture:0];
		
		if(range.location != NSNotFound) {
			substring = [text substringWithRange:[text rangeOfRegex:@"\\[url]wiredp7://(/.+?)\\[/url\\]" options:RKLCaseless capture:1]];
			
			[text replaceCharactersInRange:range withString:
			 [NSSWF:@"<img src=\"data:image/tiff;base64,%@\" /> <a href=\"wiredp7://%@\">%@</a>",
			  _fileLinkBase64String, substring, substring]];
		}
	} while(range.location != NSNotFound);
	
	[text replaceOccurrencesOfRegex:@"\\[url=(.+?)\\](.+?)\\[/url\\]"
						 withString:@"<a href=\"$1\">$2</a>"
							options:RKLCaseless];
	
	/* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
	do {
		range = [text rangeOfRegex:@"\\[url](.+?)\\[/url\\]" options:RKLCaseless capture:0];
		
		if(range.location != NSNotFound) {
			substring = [text substringWithRange:[text rangeOfRegex:@"\\[url](.+?)\\[/url\\]" options:RKLCaseless capture:1]];
			
			[text replaceCharactersInRange:range withString:[NSSWF:@"<a href=\"%@\">%@</a>", substring, substring]];
		}
	} while(range.location != NSNotFound);
	
	[text replaceOccurrencesOfRegex:@"\\[email=(.+?)\\](.+?)\\[/email\\]"
						 withString:@"<a href=\"mailto:$1\">$2</a>"
							options:RKLCaseless];
	[text replaceOccurrencesOfRegex:@"\\[email](.+?)\\[/email\\]"
						 withString:@"<a href=\"mailto:$1\">$1</a>"
							options:RKLCaseless];
	[text replaceOccurrencesOfRegex:@"\\[img](.+?)\\[/img\\]"
						 withString:@"<img src=\"$1\" alt=\"\" />"
							options:RKLCaseless];
	
	[text replaceOccurrencesOfRegex:@"\\[quote=(.+?)\\](.+?)\\[/quote\\]"
						 withString:[NSSWF:@"<blockquote><b>%@</b><br />$2</blockquote>", NSLS(@"$1 wrote:", @"Board quote (nick)")]
							options:RKLCaseless | RKLDotAll];
	
	[text replaceOccurrencesOfRegex:@"\\[quote\\](.+?)\\[/quote\\]"
						 withString:@"<blockquote>$1</blockquote>"
							options:RKLCaseless | RKLDotAll];
		
	dispatch_sync(dispatch_get_main_queue(), ^{
		
		postElement			= [WCDOMPostElement postElementForFrame:[_threadWebView mainFrame] withTemplate:postTemplate];	
		
		[postElement setFromString:NSLS(@"From:", @"Post header")];
		[postElement setPostDateString:NSLS(@"Post Date:", @"Post header")];
		
		[postElement setFrom:[post nick]];
		
		if([post isUnread]) {
			[postElement setUnreadImage:[NSSWF:@"<img class=\"postunread\" src=\"data:image/tiff;base64,%@\" />", _unreadPostBase64String]];
		} else {
			[postElement setUnreadImage:@""];
		}
		
		[postElement setPostDate:[_dateFormatter stringFromDate:[post postDate]]];
		
		if([post editDate]) {
			[postElement setEditDateString:NSLS(@"Edit Date:", @"Post header")];
			[postElement setEditDate:[_dateFormatter stringFromDate:[post editDate]]];
		} else {
			[postElement setEditDateString:@""];
			[postElement setEditDate:@""];
		}
		
		icon = (NSString *) [post icon];
		
		if([icon length] > 0) {
			[postElement setPostIcon:[NSSWF:@"<img src='data:image/tiff;base64,%@' width='32' height='32' alt='' />", icon]];
		} else {
			[postElement setPostIcon:[NSSWF:@"<img src='data:image/tiff;base64,%@' width='32' height='32' alt='' />", _defaultIconBase64String]];
		}
		
		// post body
		[postElement setPostContent:text];
		
		// buttons
		if([post isKindOfClass:[WCBoardThread class]])
			[postElement setPostID:[post threadID]];
		else
			[postElement setPostID:[post postID]];
        
		if(([account boardAddPosts] && writable) ||
           [[[WCBoards boards] selectedBoard] isKindOfClass:[WCSmartBoard class]])
			[postElement setQuoteDisabled:NO];
		else
			[postElement setQuoteDisabled:YES];
		
		if([post isKindOfClass:[WCBoardThread class]])
			own = [post isOwnThread];
		else
			own = [post isOwnPost];
		
		if((([account boardEditAllThreadsAndPosts] || ([account boardEditOwnThreadsAndPosts] && own)) && writable) ||
           [[[WCBoards boards] selectedBoard] isKindOfClass:[WCSmartBoard class]])
			[postElement setEditDisabled:NO];
		else
			[postElement setEditDisabled:YES];
		
		if((([account boardDeleteAllThreadsAndPosts] || ([account boardDeleteOwnThreadsAndPosts] && own)) && writable) ||
            [[[WCBoards boards] selectedBoard] isKindOfClass:[WCSmartBoard class]])
			[postElement setDeleteDisabled:NO];
		else
			[postElement setDeleteDisabled:YES];	
		
		[postElement setQuoteButtonString:NSLS(@"Quote", @"Quote post button title")];
		[postElement setEditButtonString:NSLS(@"Edit", @"Edit post button title")];
		[postElement setDeleteButtonString:NSLS(@"Delete", @"Delete post button title")];
		
		// append to the DOM
		[_threadWebView appendElement:[postElement element] toTopOfElementWithID:@"thread-content" scroll:YES];
	});
}

@end





@implementation WCBoardThreadController

- (id)init {
	self = [super init];
		
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
	NSBundle		*template;
	NSDictionary	*theme;
	NSString		*htmlPath;
	
	[_threadWebView setUIDelegate:self];
    [_threadWebView setFrameLoadDelegate:self];
	[_threadWebView setResourceLoadDelegate:self];
	[_threadWebView setPolicyDelegate:self];
	
	theme			= [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	template		= [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];
	htmlPath		= [template pathForResource:@"Boards" ofType:@"html" inDirectory:@"htdocs"];
	
    [[_threadWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
}




#pragma mark -

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {	
	if(_previousVisibleRect.size.height > 0.0)
		[[[[_threadWebView mainFrame] frameView] documentView] scrollRectToVisible:_previousVisibleRect];

	if(_selectPost) {
		[_threadWebView stringByEvaluatingJavaScriptFromString:[NSSWF:@"window.location.hash='%@';", [_selectPost postID]]];
		
		[_selectPost release];
		_selectPost = NULL;
	}
}



- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
	if(webView == _threadWebView)
		[windowObject setValue:[WCBoards boards] forKey:@"Boards"];
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

						file = [WCFile fileWithDirectory:path connection:[_thread connection]];
						[WCFiles filesWithConnection:[_thread connection] file:file selectFile:file];
                        
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
	return NULL;
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
	[_loadingQueue cancelAllOperations];
	[self _reloadDataAndScrollToCurrentPosition:NO selectPost:NULL];
}



- (void)reloadDataAndScrollToCurrentPosition {
	[_loadingQueue cancelAllOperations];
	[self _reloadDataAndScrollToCurrentPosition:YES selectPost:NULL];
}



- (void)reloadDataAndSelectPost:(WCBoardPost *)selectPost {
	[_loadingQueue cancelAllOperations];
	[self _reloadDataAndScrollToCurrentPosition:NO selectPost:selectPost];
}



#pragma mark -

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
