//
//  WITemplateBundle.m
//  wired
//
//  Created by Rafaël Warnault on 19/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WITemplateBundle.h"


#define WI_TEMPLATE_HTDOCS_DIR_NAME		@"htdocs"
#define WI_TEMPLATE_CSS_DIR_NAME		@"htdocs/css"
#define WI_TEMPLATE_JS_DIR_NAME			@"htdocs/js"



NSString * const WITemplateAttributesFontName			= @"<? fontname ?>";
NSString * const WITemplateAttributesFontSize			= @"<? fontsize ?>";

NSString * const WITemplateAttributesBackgroundColor	= @"<? backgroundcolor ?>";
NSString * const WITemplateAttributesFontColor			= @"<? textcolor ?>";

NSString * const WITemplateAttributesTimestampColor		= @"<? timestampcolor ?>";
NSString * const WITemplateAttributesEventColor			= @"<? eventcolor ?>";
NSString * const WITemplateAttributesURLTextColor		= @"<? urltextcolor ?>";


@interface WITemplateBundle (Private)

- (void)_overwriteAttributes:(NSDictionary *)attributes forType:(WITemplateType)type;

- (NSString *)_CSSResourceNameForType:(WITemplateType)type;
- (NSString *)_HTMLResourceNameForType:(WITemplateType)type;
- (NSMutableDictionary *)_attributesForType:(WITemplateType)type;

@end





@implementation WITemplateBundle



#pragma mark

+ (id)templateWithPath:(NSString *)path {
	return [[[[self class] alloc] initTemplateWithPath:path] autorelease];
}





#pragma mark

- (id)initTemplateWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self) {
        _chatAttributes			= [[NSMutableDictionary alloc] init];
		_messagesAttributes		= [[NSMutableDictionary alloc] init];
		_boardsAttributes		= [[NSMutableDictionary alloc] init];
		
		_attributesChanged		= NO;
    }
    return self;
}


- (void)dealloc
{
    [_chatAttributes release];
	[_messagesAttributes release];
	[_boardsAttributes release];
    [super dealloc];
}




#pragma mark -

- (NSString *)templateName {
	return [self objectForInfoDictionaryKey:@"CFBundleName"];
}


- (NSString *)templateVersion {
	return [self objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}


- (BOOL)hasChanges {
	return _attributesChanged;	
}







#pragma mark -

- (void)setCSSValue:(id)value toAttribute:(NSString *)attibute ofType:(WITemplateType)type {
	switch (type) {
		case WITemplateTypeChat: {
			[_chatAttributes setValue:value forKey:attibute];
		} break;
			
		case WITemplateTypeMessages: {
			[_messagesAttributes setValue:value forKey:attibute];
		} break;
			
		case WITemplateTypeBoards: {
			[_boardsAttributes setValue:value forKey:attibute];
		} break;
	}
	_attributesChanged = YES;
}


- (void)saveChanges {
	
	if(_attributesChanged) {
		// perform save here...
		[self _overwriteAttributes:_chatAttributes forType:WITemplateTypeChat];
		[self _overwriteAttributes:_messagesAttributes forType:WITemplateTypeChat];
		[self _overwriteAttributes:_boardsAttributes forType:WITemplateTypeChat];
		
		// clean changes by calling the undo method
		[self undoChanges];
	}
	
}


- (void)saveChangesForType:(WITemplateType)type {
	if(_attributesChanged) {
		NSMutableDictionary		*attributes;
		
		attributes	= [self _attributesForType:type];
		
		[self _overwriteAttributes:attributes forType:type];
		[attributes removeAllObjects];
	}
}



- (void)undoChanges {
	if(_attributesChanged) {
		
		[_chatAttributes removeAllObjects];
		[_messagesAttributes removeAllObjects];
		[_boardsAttributes removeAllObjects];
		
		_attributesChanged = NO;
	}
}



#pragma mark -

- (NSString *)htmlPathForType:(WITemplateType)type {	
	return [self pathForResource:[self _HTMLResourceNameForType:type] 
						  ofType:@"html"
					 inDirectory:WI_TEMPLATE_HTDOCS_DIR_NAME];
}


- (NSString *)stylesheetPathForType:(WITemplateType)type {
	return [self pathForResource:[self _CSSResourceNameForType:type] 
						  ofType:@"css"
					 inDirectory:WI_TEMPLATE_CSS_DIR_NAME];
}


- (NSString *)defaultStylesheetPathForType:(WITemplateType)type {
	NSString	*defaultPath;
	
	defaultPath = [self pathForResource:[NSSWF:@"default_%@", [self _CSSResourceNameForType:type]] 
								 ofType:@"css" 
							inDirectory:WI_TEMPLATE_CSS_DIR_NAME];
	
	// check if 'default_' already exists, if not, create it
	if(![[NSFileManager defaultManager] fileExistsAtPath:defaultPath])
		[[NSFileManager defaultManager] createFileAtPath:defaultPath contents:nil attributes:nil];
	
	return defaultPath;
}





#pragma mark - Private Methods

- (void)_overwriteAttributes:(NSDictionary *)attributes forType:(WITemplateType)type {
	NSString			*sourceSheetPath, *defaultSheetPath;
	NSMutableString		*sourceString;
	NSError				*error;
	
	sourceSheetPath		= [self stylesheetPathForType:type];
	defaultSheetPath	= [self defaultStylesheetPathForType:type];
	
	sourceString		= [NSMutableString stringWithContentsOfFile:sourceSheetPath 
													 encoding:NSUTF8StringEncoding 
														error:&error];
	
	for(NSString *key in [attributes allKeys]) {
		NSString *value = [attributes valueForKey:key];
		[sourceString replaceOccurrencesOfString:key withString:value];
	}

	[sourceString writeToFile:defaultSheetPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
}



- (NSString *)_CSSResourceNameForType:(WITemplateType)type {
	NSString	*result = nil;
	
	switch (type) {
		case WITemplateTypeChat:		result = @"chat";		break;
		case WITemplateTypeMessages:	result = @"messages";	break;
		case WITemplateTypeBoards:		result = @"boards";		break;
	}
	return result;
}



- (NSString *)_HTMLResourceNameForType:(WITemplateType)type {
	NSString	*result = nil;
	
	switch (type) {
		case WITemplateTypeChat:		result = @"chat";		break;
		case WITemplateTypeMessages:	result = @"messages";	break;
		case WITemplateTypeBoards:		result = @"boards";		break;
	}
	return result;
}



- (NSMutableDictionary *)_attributesForType:(WITemplateType)type {
	switch (type) {
		case WITemplateTypeChat:		return _chatAttributes;		break;
		case WITemplateTypeMessages:	return _messagesAttributes;	break;
		case WITemplateTypeBoards:		return _boardsAttributes;	break;
	}
	return nil;
}

@end
