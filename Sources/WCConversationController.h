/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "WCWebDataSource.h"

@class WDConversation, WDMessage;

@interface WCConversationController : WIObject <WCWebDataSource> {
	IBOutlet WebView					*_conversationWebView;
	
    NSArray                             *_messages;
	NSOperationQueue					*_loadingQueue;

	NSString							*_templatePath;
	NSFont								*_font;
	NSColor								*_textColor;
	NSColor								*_backgroundColor;

	WIDateFormatter						*_messageStatusDateFormatter;
	WIDateFormatter						*_messageTimeDateFormatter;
}

- (void)appendMessage:(WDMessage *)message;
- (void)appendCommand:(WDMessage *)message;

- (void)reloadData;
- (void)reloadTemplate;

- (void)setMessages:(NSArray *)messages;
- (NSArray *)messages;

- (void)setTemplatePath:(NSString *)path;
- (NSString *)templatePath;

- (void)setFont:(NSFont *)font;
- (NSFont *)font;

- (void)setTextColor:(NSColor *)textColor;
- (NSColor *)textColor;

- (void)setBackgroundColor:(NSColor *)backgroundColor;
- (NSColor *)backgroundColor;

- (LNWebView *)conversationWebView;
- (NSString *)HTMLString;

@end
