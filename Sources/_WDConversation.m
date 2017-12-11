// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDConversation.m instead.

#import "_WDConversation.h"

@implementation WDConversationID
@end

@implementation _WDConversation

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Conversation";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Conversation" inManagedObjectContext:moc_];
}

- (WDConversationID*)objectID {
	return (WDConversationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"numberOfUnreadsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"numberOfUnreads"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic numberOfUnreads;

- (int32_t)numberOfUnreadsValue {
	NSNumber *result = [self numberOfUnreads];
	return [result intValue];
}

- (void)setNumberOfUnreadsValue:(int32_t)value_ {
	[self setNumberOfUnreads:@(value_)];
}

- (int32_t)primitiveNumberOfUnreadsValue {
	NSNumber *result = [self primitiveNumberOfUnreads];
	return [result intValue];
}

- (void)setPrimitiveNumberOfUnreadsValue:(int32_t)value_ {
	[self setPrimitiveNumberOfUnreads:@(value_)];
}

@dynamic serverName;

@dynamic messages;

- (NSMutableSet<WDMessage*>*)messagesSet {
	[self willAccessValueForKey:@"messages"];

	NSMutableSet<WDMessage*> *result = (NSMutableSet<WDMessage*>*)[self mutableSetValueForKey:@"messages"];

	[self didAccessValueForKey:@"messages"];
	return result;
}

@end

@implementation WDConversationAttributes 
+ (NSString *)numberOfUnreads {
	return @"numberOfUnreads";
}
+ (NSString *)serverName {
	return @"serverName";
}
@end

@implementation WDConversationRelationships 
+ (NSString *)messages {
	return @"messages";
}
@end

