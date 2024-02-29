//
//  WCDOMChatElement.m
//  WiredClient
//
//  Created by Rafaël Warnault on 12/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WIDOMElement.h"


@implementation WIDOMElement

#pragma mark -

- (id)initForFrame:(WebFrame *)frame withTemplate:(NSString *)html
{
	self = [super init];
	if (self) {
		_element = (DOMHTMLElement *)[[[frame DOMDocument] createElement:@"div"] retain];
		[_element setInnerHTML:html];
	}
	return self;
}


- (DOMHTMLElement *)element {
	return _element;
}

@end
