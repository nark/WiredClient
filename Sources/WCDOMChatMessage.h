//
//  WCDOMChatMessage.h
//  WiredClient
//
//  Created by Rafaël Warnault on 12/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


@interface WCDOMChatMessage : WIDOMElement

+ (id)chatMessageElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html;

- (void)setNick:(NSString *)nick;
- (void)setTimestamp:(NSString *)timestamp;
- (void)setMessage:(NSString *)message;

@end
