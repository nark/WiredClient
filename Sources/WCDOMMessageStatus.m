//
//  WCDOMMessageStatus.m
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCDOMMessageStatus.h"

@implementation WCDOMMessageStatus


#pragma mark -

+ (id)messageStatusElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html {
	return [[[[self class] alloc] initForFrame:frame withTemplate:html] autorelease];
}



#pragma mark -

- (void)setMessageStatus:(NSString *)status {
	DOMHTMLElement *element = (DOMHTMLElement *)[[_element getElementsByClassName:@"messagestatus"] item:0];
	[element setInnerText:status];
}

@end
