//
//  WCDOMPostElement.m
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCDOMPostElement.h"

@implementation WCDOMPostElement


#pragma mark -

+ (id)postElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html {
	return [[[[self class] alloc] initForFrame:frame withTemplate:html] autorelease];
}




#pragma mark -

- (void)setPostID:(NSString *)postID {
	DOMHTMLElement *element;
	
	element = (DOMHTMLElement *)[[_element getElementsByClassName:@"anchor"] item:0];
	[element setAttribute:@"name" value:postID];
	
	element = (DOMHTMLElement *)[[_element getElementsByClassName:@"quotebutton"] item:0];
	[element setAttribute:@"onclick" value:[NSSWF:@"window.Boards.replyToPostWithID_('%@');", postID]];
	
	element = (DOMHTMLElement *)[[_element getElementsByClassName:@"editbutton"] item:0];
	[element setAttribute:@"onclick" value:[NSSWF:@"window.Boards.editPostWithID_('%@');", postID]];
	
	element = (DOMHTMLElement *)[[_element getElementsByClassName:@"deletebutton"] item:0];
	[element setAttribute:@"onclick" value:[NSSWF:@"window.Boards.deletePostWithID_('%@');", postID]];
}




#pragma mark -

- (void)setFrom:(NSString *)from {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"postfrom"] item:0];
	[element setInnerHTML:from];
}


- (void)setPostDate:(NSString *)date {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"postpostdate"] item:0];
	[element setInnerHTML:date];
}


- (void)setEditDate:(NSString *)date {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"posteditdate"] item:0];
	[element setInnerHTML:date];
}




#pragma mark -

- (void)setPostIcon:(NSString *)icon {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"posticon"] item:0];
	[element setInnerHTML:icon];
}


- (void)setUnreadImage:(NSString *)unread {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"postunread"] item:0];
	[element setInnerHTML:unread];
}





#pragma mark -

- (void)setPostDateString:(NSString *)string {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"postpostdatestring"] item:0];
	[element setInnerHTML:string];
}


- (void)setFromString:(NSString *)string {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"postfromstring"] item:0];
	[element setInnerHTML:string];
}


- (void)setEditDateString:(NSString *)string {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"posteditdatestring"] item:0];
	[element setInnerHTML:string];
}




#pragma mark -

- (void)setPostContent:(NSString *)content {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"postbody"] item:0];
	[element setInnerHTML:content];
}




#pragma mark -

- (void)setQuoteDisabled:(BOOL)disabled {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"quotebutton"] item:0];
	
	if(!disabled)
		[element removeAttribute:@"disabled"];
	else
		[element setAttribute:@"disabled" value:@"disabled"];
}


- (void)setEditDisabled:(BOOL)disabled {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"editbutton"] item:0];
	
	if(!disabled)
		[element removeAttribute:@"disabled"];
	else
		[element setAttribute:@"disabled" value:@"disabled"];
}


- (void)setDeleteDisabled:(BOOL)disabled {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"deletebutton"] item:0];
	
	if(!disabled)
		[element removeAttribute:@"disabled"];
	else
		[element setAttribute:@"disabled" value:@"disabled"];
}




#pragma mark -

- (void)setQuoteButtonString:(NSString *)string {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"quotebutton"] item:0];
	[element setAttribute:@"value" value:string];
    [element setAttribute:@"title" value:string];
}


- (void)setEditButtonString:(NSString *)string {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"editbutton"] item:0];
	[element setAttribute:@"value" value:string];
    [element setAttribute:@"title" value:string];
}


- (void)setDeleteButtonString:(NSString *)string {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"deletebutton"] item:0];
	[element setAttribute:@"value" value:string];
    [element setAttribute:@"title" value:string];
}


@end
