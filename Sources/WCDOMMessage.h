//
//  WCDOMMessage.h
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


@interface WCDOMMessage : WIDOMElement

+ (id)messageElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html;

- (void)setTime:(NSString *)time;
- (void)setServer:(NSString *)server;
- (void)setMessageContent:(NSString *)message;
- (void)setIcon:(NSString *)icon;
- (void)setNick:(NSString *)nick;
- (void)setDirection:(NSString *)direction;

@end
