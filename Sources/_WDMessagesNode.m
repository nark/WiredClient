// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessagesNode.m instead.

#import "_WDMessagesNode.h"

@implementation WDMessagesNodeID
@end

@implementation _WDMessagesNode

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"MessagesNode" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"MessagesNode";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"MessagesNode" inManagedObjectContext:moc_];
}

- (WDMessagesNodeID*)objectID {
	return (WDMessagesNodeID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"activeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"active"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"directionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"direction"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"unreadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unread"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic active;

- (BOOL)activeValue {
	NSNumber *result = [self active];
	return [result boolValue];
}

- (void)setActiveValue:(BOOL)value_ {
	[self setActive:@(value_)];
}

- (BOOL)primitiveActiveValue {
	NSNumber *result = [self primitiveActive];
	return [result boolValue];
}

- (void)setPrimitiveActiveValue:(BOOL)value_ {
	[self setPrimitiveActive:@(value_)];
}

@dynamic date;

@dynamic direction;

- (int32_t)directionValue {
	NSNumber *result = [self direction];
	return [result intValue];
}

- (void)setDirectionValue:(int32_t)value_ {
	[self setDirection:@(value_)];
}

- (int32_t)primitiveDirectionValue {
	NSNumber *result = [self primitiveDirection];
	return [result intValue];
}

- (void)setPrimitiveDirectionValue:(int32_t)value_ {
	[self setPrimitiveDirection:@(value_)];
}

@dynamic identifier;

@dynamic nick;

@dynamic unread;

- (BOOL)unreadValue {
	NSNumber *result = [self unread];
	return [result boolValue];
}

- (void)setUnreadValue:(BOOL)value_ {
	[self setUnread:@(value_)];
}

- (BOOL)primitiveUnreadValue {
	NSNumber *result = [self primitiveUnread];
	return [result boolValue];
}

- (void)setPrimitiveUnreadValue:(BOOL)value_ {
	[self setPrimitiveUnread:@(value_)];
}

@dynamic user;

@end

@implementation WDMessagesNodeAttributes 
+ (NSString *)active {
	return @"active";
}
+ (NSString *)date {
	return @"date";
}
+ (NSString *)direction {
	return @"direction";
}
+ (NSString *)identifier {
	return @"identifier";
}
+ (NSString *)nick {
	return @"nick";
}
+ (NSString *)unread {
	return @"unread";
}
+ (NSString *)user {
	return @"user";
}
@end

