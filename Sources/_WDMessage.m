// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessage.m instead.

#import "_WDMessage.h"

const struct WDMessageAttributes WDMessageAttributes = {
	.draft = @"draft",
	.message = @"message",
	.unread = @"unread",
};

const struct WDMessageRelationships WDMessageRelationships = {
	.conversation = @"conversation",
};

const struct WDMessageFetchedProperties WDMessageFetchedProperties = {
};

@implementation WDMessageID
@end

@implementation _WDMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Message";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Message" inManagedObjectContext:moc_];
}

- (WDMessageID*)objectID {
	return (WDMessageID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"draftValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"draft"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"unreadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unread"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic draft;



- (BOOL)draftValue {
	NSNumber *result = [self draft];
	return [result boolValue];
}

- (void)setDraftValue:(BOOL)value_ {
	[self setDraft:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveDraftValue {
	NSNumber *result = [self primitiveDraft];
	return [result boolValue];
}

- (void)setPrimitiveDraftValue:(BOOL)value_ {
	[self setPrimitiveDraft:[NSNumber numberWithBool:value_]];
}





@dynamic message;






@dynamic unread;



- (BOOL)unreadValue {
	NSNumber *result = [self unread];
	return [result boolValue];
}

- (void)setUnreadValue:(BOOL)value_ {
	[self setUnread:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveUnreadValue {
	NSNumber *result = [self primitiveUnread];
	return [result boolValue];
}

- (void)setPrimitiveUnreadValue:(BOOL)value_ {
	[self setPrimitiveUnread:[NSNumber numberWithBool:value_]];
}





@dynamic conversation;

	






@end
