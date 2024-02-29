// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WEvent.m instead.

#import "_WEvent.h"

const struct WEventAttributes WEventAttributes = {
	.eventDate = @"eventDate",
	.eventDescription = @"eventDescription",
	.eventTitle = @"eventTitle",
	.eventType = @"eventType",
};

const struct WEventRelationships WEventRelationships = {
	.server = @"server",
};

const struct WEventFetchedProperties WEventFetchedProperties = {
};

@implementation WEventID
@end

@implementation _WEvent

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Event";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Event" inManagedObjectContext:moc_];
}

- (WEventID*)objectID {
	return (WEventID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"eventTypeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"eventType"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic eventDate;






@dynamic eventDescription;






@dynamic eventTitle;






@dynamic eventType;



- (int32_t)eventTypeValue {
	NSNumber *result = [self eventType];
	return [result intValue];
}

- (void)setEventTypeValue:(int32_t)value_ {
	[self setEventType:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveEventTypeValue {
	NSNumber *result = [self primitiveEventType];
	return [result intValue];
}

- (void)setPrimitiveEventTypeValue:(int32_t)value_ {
	[self setPrimitiveEventType:[NSNumber numberWithInt:value_]];
}





@dynamic server;

	






@end
