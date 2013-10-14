// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessagesNode.m instead.

#import "_WDMessagesNode.h"

const struct WDMessagesNodeAttributes WDMessagesNodeAttributes = {
	.active = @"active",
	.date = @"date",
	.direction = @"direction",
	.identifier = @"identifier",
	.nick = @"nick",
	.unread = @"unread",
	.user = @"user",
};

const struct WDMessagesNodeRelationships WDMessagesNodeRelationships = {
};

const struct WDMessagesNodeFetchedProperties WDMessagesNodeFetchedProperties = {
};

@implementation WDMessagesNodeID
@end

@implementation _WDMessagesNode

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"activeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"active"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"directionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"direction"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"unreadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unread"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic active;



- (BOOL)activeValue {
	NSNumber *result = [self active];
	return [result boolValue];
}

- (void)setActiveValue:(BOOL)value_ {
	[self setActive:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveActiveValue {
	NSNumber *result = [self primitiveActive];
	return [result boolValue];
}

- (void)setPrimitiveActiveValue:(BOOL)value_ {
	[self setPrimitiveActive:[NSNumber numberWithBool:value_]];
}





@dynamic date;






@dynamic direction;



- (int32_t)directionValue {
	NSNumber *result = [self direction];
	return [result intValue];
}

- (void)setDirectionValue:(int32_t)value_ {
	[self setDirection:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveDirectionValue {
	NSNumber *result = [self primitiveDirection];
	return [result intValue];
}

- (void)setPrimitiveDirectionValue:(int32_t)value_ {
	[self setPrimitiveDirection:[NSNumber numberWithInt:value_]];
}





@dynamic identifier;






@dynamic nick;






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





@dynamic user;











@end
