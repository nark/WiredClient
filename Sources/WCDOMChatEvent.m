//
//  WCDOMChatEvent.m
//  WiredClient
//
//  Created by Rafaël Warnault on 12/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCDOMChatEvent.h"

@implementation WCDOMChatEvent

#pragma mark -

+ (id)chatEventElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html {
	return [[[[self class] alloc] initForFrame:frame withTemplate:html] autorelease];
}



#pragma mark -

- (void)setTimestamp:(NSString *)timestamp {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"timestamp"] item:0];
	[element setInnerHTML:timestamp];
}


- (void)setMessage:(NSString *)message {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"message"] item:0];
	[element setInnerHTML:message];
}




@end
