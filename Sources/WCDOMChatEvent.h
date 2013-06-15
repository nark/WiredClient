//
//  WCDOMChatEvent.h
//  WiredClient
//
//  Created by Rafaël Warnault on 12/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


@interface WCDOMChatEvent : WIDOMElement

+ (id)chatEventElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html;

- (void)setTimestamp:(NSString *)timestamp;
- (void)setMessage:(NSString *)message;

@end
