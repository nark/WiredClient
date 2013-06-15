//
//  WCDOMMessageStatus.h
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


@interface WCDOMMessageStatus : WIDOMElement

+ (id)messageStatusElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html;

- (void)setMessageStatus:(NSString *)status;

@end
