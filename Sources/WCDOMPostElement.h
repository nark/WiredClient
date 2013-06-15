//
//  WCDOMPostElement.h
//  WiredClient
//
//  Created by Rafaël Warnault on 14/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


@interface WCDOMPostElement : WIDOMElement

+ (id)postElementForFrame:(WebFrame *)frame withTemplate:(NSString *)html;

- (void)setPostID:(NSString *)postID;

- (void)setFrom:(NSString *)from;

- (void)setPostIcon:(NSString *)icon;
- (void)setUnreadImage:(NSString *)unread;

- (void)setPostDate:(NSString *)date;
- (void)setEditDate:(NSString *)date;

- (void)setFromString:(NSString *)string;
- (void)setPostDateString:(NSString *)string;
- (void)setEditDateString:(NSString *)string;

- (void)setPostContent:(NSString *)content;

- (void)setQuoteDisabled:(BOOL)enabled;
- (void)setEditDisabled:(BOOL)enabled;
- (void)setDeleteDisabled:(BOOL)enabled;

- (void)setQuoteButtonString:(NSString *)string;
- (void)setEditButtonString:(NSString *)string;
- (void)setDeleteButtonString:(NSString *)string;

@end
