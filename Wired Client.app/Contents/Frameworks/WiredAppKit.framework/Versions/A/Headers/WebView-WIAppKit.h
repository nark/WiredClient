//
//  WebView-WIAppKit.h
//  wired
//
//  Created by Rafaël Warnault on 19/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WITemplateBundle.h"
#import "WIChatLogController.h"



@interface WebView (WIAppKit)

- (void)scrollToBottom;

- (void)appendElement:(DOMElement *)element toTopOfElementWithID:(NSString *)elementID scroll:(BOOL)scroll;
- (void)appendElement:(DOMElement *)element toBottomOfElementWithID:(NSString *)elementID scroll:(BOOL)scroll;

- (void)appendScriptAtURL:(NSURL *)url;
- (void)reloadStylesheetWithID:(NSString *)elementID withTemplate:(WITemplateBundle *)template type:(WITemplateType)type;

- (void)clearChildrenElementsOfElementWithID:(NSString *)elementID;

- (void)exportContentToFileAtPath:(NSString *)path forType:(WIChatLogType)type;

@end
