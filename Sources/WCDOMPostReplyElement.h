//
//  WCDOMPostReplyElement.h
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


@interface WCDOMPostReplyElement : WIDOMElement

+ (id)postReplyElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html;

- (void)setReplyString:(NSString *)reply;
- (void)setReplyEnabled:(BOOL)enabled;

@end
