//
//  WITemplateBundleManager.h
//  wired
//
//  Created by Rafaël Warnault on 08/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

@class WITemplateBundle;

@interface WITemplateBundleManager : WIObject {
	NSString			*_path;
	NSMutableArray		*_templates;
	
	BOOL				_private;
}

+ (id)templateManagerForPath:(NSString *)path;
+ (id)templateManagerForPath:(NSString *)path isPrivate:(BOOL)flag;

- (BOOL)addTemplateAtPath:(NSString *)path;
- (BOOL)removeTemplate:(WITemplateBundle *)bundle;

- (WITemplateBundle *)templateWithIdentifier:(NSString *)identifier;

- (NSString *)path;
- (NSArray *)templates;
- (BOOL)isPrivate;

@end
