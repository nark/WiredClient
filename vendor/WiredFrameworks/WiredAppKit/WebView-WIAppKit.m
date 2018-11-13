//
//  WebView-WIAppKit.m
//  wired
//
//  Created by Rafaël Warnault on 19/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WebView-WIAppKit.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>




@interface WebView (WIAppKitPrivate)

- (WebArchive *)_webArchive;
- (void)_exportWebArchiveToPath:(NSString *)path;
- (void)_exportHTMLToPath:(NSString *)path;
- (void)_exportRTFDToPath:(NSString *)path;
- (void)_exportTXTToPath:(NSString *)path;

@end



@implementation WebView (WIAppKitPrivate)

- (WebArchive *)_webArchive {
    WebResource		*dataSource;
	WebArchive		*archive;
    
    dataSource		= [[[[self mainFrame] DOMDocument] webArchive] mainResource];
	archive			= [[WebArchive alloc] initWithMainResource:dataSource
                                            subresources:nil
                                        subframeArchives:nil];
    
    return [archive autorelease];
}



- (void)_exportWebArchiveToPath:(NSString *)path {
	WebArchive		*archive;
	
	archive			= [self _webArchive];
	
	[[archive data] writeToFile:path atomically:YES];
	
	//[archive release];
}



- (void)_exportHTMLToPath:(NSString *)path {
	NSString		*htmlString;
	NSError			*error;
		
	htmlString = [self stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('html')[0].innerHTML"];
	
	[htmlString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
}



- (void)_exportRTFDToPath:(NSString *)path {
	WebArchive				*archive;
	NSDictionary			*options;
	NSAttributedString		*attributedSting;
	
	archive			= [self _webArchive];
	options         = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding] 
										  forKey: NSCharacterEncodingDocumentOption];
	
	attributedSting	= [[NSAttributedString alloc] initWithHTML:[archive data] options:options documentAttributes:NULL];
	
    [[attributedSting RTFDFromRange:NSMakeRange(0, [attributedSting length]) documentAttributes:@{}] writeToFile:path
																									  atomically:YES];
	
	[attributedSting autorelease];
	//[archive release];
}



- (void)_exportTXTToPath:(NSString *)path {
	WebArchive				*archive;
	NSDictionary			*options;
	NSAttributedString		*attributedSting;
	NSString				*string;
	NSError					*error;
	
	archive             = [self _webArchive];
	options             = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding]
                                                      forKey: NSCharacterEncodingDocumentOption];
	
	attributedSting     = [[NSAttributedString alloc] initWithHTML:[archive data] options:options documentAttributes:NULL];
	string              = [attributedSting string];
	
	[string writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];

	[attributedSting autorelease];
	//[archive release];
}


@end






@implementation WebView (WIAppKit)

#pragma mark -

- (void)scrollToBottom {
	DOMNodeList         *bodyNodeList;
    DOMHTMLElement      *bodyNode;
    NSNumber            *bodyHeight;
    NSScrollView        *scrollView;
    NSRect              rect;
    
    bodyNodeList        = [[[self mainFrame] DOMDocument] getElementsByTagName:@"body"];
    bodyNode            = (DOMHTMLElement *)[bodyNodeList item:0];
    bodyHeight          = [bodyNode valueForKey:@"scrollHeight"];
    scrollView          = [[[[self mainFrame] frameView] documentView] enclosingScrollView];
        
	rect                = [scrollView documentVisibleRect];
	rect.origin.y       = [bodyHeight doubleValue] + 50;
    
	[[[[self mainFrame] frameView] documentView] scrollRectToVisible:rect];
}





#pragma mark -

- (void)appendElement:(DOMElement *)element toTopOfElementWithID:(NSString *)elementID scroll:(BOOL)scroll {
	DOMHTMLElement		*containerElement;
	DOMNode				*refElement;
	
	containerElement	= (DOMHTMLElement *)[[[self mainFrame] DOMDocument] getElementById:elementID];
	refElement			= [containerElement firstChild];
	
	if(!refElement)
		[containerElement appendChild:element];
	else
		[containerElement insertBefore:element refChild:refElement];
	
	if(scroll)
		[self scrollToBottom];
}


- (void)appendElement:(DOMElement *)element toBottomOfElementWithID:(NSString *)elementID scroll:(BOOL)scroll {
	DOMElement *contentElement;
    
    contentElement = [[[self mainFrame] DOMDocument] getElementById:elementID];
    
	[contentElement appendChild:element];
	
	if(scroll)
		[self scrollToBottom];
}






#pragma mark -

- (void)appendScriptAtURL:(NSURL *)url {
    NSString            *string;
    DOMDocument         *document;
    DOMElement          *jsElement, *headElement;
    DOMText             *text;
    
    if(!url)
        return;
    
    string          = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    document        = [self mainFrameDocument];
    jsElement       = [document createElement:@"script"];
    text            = [document createTextNode:string];
    headElement     = (DOMElement*)[[document getElementsByTagName:@"head"] item:0];
    
    [jsElement setAttribute:@"type" value:@"text/javascript"];
    [jsElement appendChild:text];
    [headElement appendChild:jsElement];
}


- (void)reloadStylesheetWithID:(NSString *)elementID withTemplate:(WITemplateBundle *)template type:(WITemplateType)type {
	DOMHTMLElement *header;
    
    header = (DOMHTMLElement *)[[[self mainFrame] DOMDocument] getElementById:elementID];
    
	[header setAttribute:@"href" value:[template defaultStylesheetPathForType:type]];
}


- (void)clearChildrenElementsOfElementWithID:(NSString *)elementID {
	DOMHTMLElement *contentElement;
    
    contentElement = (DOMHTMLElement *)[[[self mainFrame] DOMDocument] getElementById:elementID];
    
	[contentElement setInnerHTML:@""];
}




#pragma mark -

- (void)exportContentToFileAtPath:(NSString *)path forType:(WIChatLogType)type {
	
	switch (type) {
		case WIChatLogTypeWebArchive:	[self _exportWebArchiveToPath:path];	break;
		case WIChatLogTypeTXT:			[self _exportTXTToPath:path];			break;
		default:						[self _exportWebArchiveToPath:path];	break;
	}
}


@end
