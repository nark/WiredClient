//
//  WITemplateBundle.h
//  wired
//
//  Created by Rafaël Warnault on 19/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


extern NSString * const		WITemplateAttributesFontName;
extern NSString * const		WITemplateAttributesFontSize;

extern NSString * const		WITemplateAttributesBackgroundColor;
extern NSString * const		WITemplateAttributesFontColor;

extern NSString * const		WITemplateAttributesTimestampColor;
extern NSString * const		WITemplateAttributesEventColor;
extern NSString * const		WITemplateAttributesURLTextColor;



enum _WITemplateType {
	WITemplateTypeChat		= 0,
	WITemplateTypeMessages	= 1,
	WITemplateTypeBoards	= 2
} typedef WITemplateType;



@interface WITemplateBundle : NSBundle {
	NSMutableDictionary		*_chatAttributes;
	NSMutableDictionary		*_messagesAttributes;
	NSMutableDictionary		*_boardsAttributes;
	
	BOOL					_attributesChanged;
}

+ (id)templateWithPath:(NSString *)path;

- (id)initTemplateWithPath:(NSString *)path;

- (NSString *)templateName;
- (NSString *)templateVersion;
- (BOOL)hasChanges;

- (void)setCSSValue:(id)value toAttribute:(NSString *)attibutes ofType:(WITemplateType)type;

- (void)saveChanges;
- (void)saveChangesForType:(WITemplateType)type;
- (void)undoChanges;

- (NSString *)htmlPathForType:(WITemplateType)type;
- (NSString *)stylesheetPathForType:(WITemplateType)type;
- (NSString *)defaultStylesheetPathForType:(WITemplateType)type;

@end
