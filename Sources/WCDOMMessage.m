//
//  WCDOMMessage.m
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCDOMMessage.h"

@implementation WCDOMMessage

#pragma mark -

+ (id)messageElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html {
	return [[[[self class] alloc] initForFrame:frame withTemplate:html] autorelease];
}



#pragma mark -

- (void)setTime:(NSString *)time {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"time"] item:0];
	[element setInnerText:time];
}


- (void)setServer:(NSString *)server {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"server"] item:0];
	[element setInnerText:server];
}


- (void)setMessageContent:(NSString *)message {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"messagecontent"] item:0];
	[element setInnerHTML:message];
}


- (void)setIcon:(NSString *)icon {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"icon"] item:0];
	[element setInnerHTML:[NSSWF:@"<img src='%@' width='32' height='32' alt='' />", icon]];
}


- (void)setNick:(NSString *)nick {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"nick"] item:0];
	[element setInnerHTML:nick];
}

- (void)setDirection:(NSString *)direction {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"message"] item:0];
	[element setAttribute:@"class" value:[NSSWF:@"message %@", direction]];
}

@end
