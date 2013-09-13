// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessagesNode.m instead.

#import "_WDMessagesNode.h"

const struct WDMessagesNodeAttributes WDMessagesNodeAttributes = {
	.date = @"date",
	.direction = @"direction",
	.identifier = @"identifier",
	.nick = @"nick",
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
	
	if ([key isEqualToString:@"directionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"direction"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
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






@dynamic user;











@end
