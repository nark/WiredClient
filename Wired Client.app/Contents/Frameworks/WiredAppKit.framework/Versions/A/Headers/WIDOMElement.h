//
//  WCDOMChatElement.h
//  WiredClient
//
//  Created by Rafaël Warnault on 12/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WIDOMElement : NSObject {
	DOMHTMLElement *_element;
}

- (id)initForFrame:(WebFrame *)frame withTemplate:(NSString *)html;

- (DOMHTMLElement *)element;

@end
