//
//  WCDOMChatMessage.m
//  WiredClient
//
//  Created by Rafaël Warnault on 12/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCDOMChatMessage.h"


@implementation WCDOMChatMessage

#pragma mark -

+ (id)chatMessageElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html {
	return [[[[self class] alloc] initForFrame:frame withTemplate:html] autorelease];
}



#pragma mark -

- (void)setNick:(NSString *)nick {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"nick"] item:0];
	[element setInnerHTML:nick];
}


- (void)setTimestamp:(NSString *)timestamp {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"timestamp"] item:0];
	[element setInnerHTML:timestamp];
}


- (void)setMessage:(NSString *)message {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"message"] item:0];
	[element setInnerHTML:message];
}



@end
