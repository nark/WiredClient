//
//  WCDOMPostReplyElement.m
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCDOMPostReplyElement.h"

@implementation WCDOMPostReplyElement


#pragma mark -

+ (id)postReplyElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html {
	return [[[[self class] alloc] initForFrame:frame withTemplate:html] autorelease];
}



#pragma mark -

- (void)setReplyString:(NSString *)string {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByTagName:@"input"] item:0];
	[element setAttribute:@"value" value:string];
}


- (void)setReplyEnabled:(BOOL)enabled {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByTagName:@"input"] item:0];
	
	if(enabled)
		[element removeAttribute:@"disabled"];
	else
		[element setAttribute:@"disabled" value:@"disabled"];
}


@end
