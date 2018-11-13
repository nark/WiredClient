// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WUser.m instead.

#import "_WUser.h"

const struct WUserAttributes WUserAttributes = {
	.icon = @"icon",
	.idelTime = @"idelTime",
	.idle = @"idle",
	.isLocal = @"isLocal",
	.login = @"login",
	.nick = @"nick",
	.status = @"status",
	.userID = @"userID",
	.wiredColor = @"wiredColor",
};

const struct WUserRelationships WUserRelationships = {
	.chats = @"chats",
};

const struct WUserFetchedProperties WUserFetchedProperties = {
};

@implementation WUserID
@end

@implementation _WUser

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"User";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"User" inManagedObjectContext:moc_];
}

- (WUserID*)objectID {
	return (WUserID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"idleValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"idle"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"isLocalValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isLocal"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"userIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"userID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"wiredColorValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"wiredColor"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic icon;






@dynamic idelTime;






@dynamic idle;



- (BOOL)idleValue {
	NSNumber *result = [self idle];
	return [result boolValue];
}

- (void)setIdleValue:(BOOL)value_ {
	[self setIdle:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIdleValue {
	NSNumber *result = [self primitiveIdle];
	return [result boolValue];
}

- (void)setPrimitiveIdleValue:(BOOL)value_ {
	[self setPrimitiveIdle:[NSNumber numberWithBool:value_]];
}





@dynamic isLocal;



- (BOOL)isLocalValue {
	NSNumber *result = [self isLocal];
	return [result boolValue];
}

- (void)setIsLocalValue:(BOOL)value_ {
	[self setIsLocal:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsLocalValue {
	NSNumber *result = [self primitiveIsLocal];
	return [result boolValue];
}

- (void)setPrimitiveIsLocalValue:(BOOL)value_ {
	[self setPrimitiveIsLocal:[NSNumber numberWithBool:value_]];
}





@dynamic login;






@dynamic nick;






@dynamic status;






@dynamic userID;



- (int32_t)userIDValue {
	NSNumber *result = [self userID];
	return [result intValue];
}

- (void)setUserIDValue:(int32_t)value_ {
	[self setUserID:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveUserIDValue {
	NSNumber *result = [self primitiveUserID];
	return [result intValue];
}

- (void)setPrimitiveUserIDValue:(int32_t)value_ {
	[self setPrimitiveUserID:[NSNumber numberWithInt:value_]];
}





@dynamic wiredColor;



- (int32_t)wiredColorValue {
	NSNumber *result = [self wiredColor];
	return [result intValue];
}

- (void)setWiredColorValue:(int32_t)value_ {
	[self setWiredColor:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveWiredColorValue {
	NSNumber *result = [self primitiveWiredColor];
	return [result intValue];
}

- (void)setPrimitiveWiredColorValue:(int32_t)value_ {
	[self setPrimitiveWiredColor:[NSNumber numberWithInt:value_]];
}





@dynamic chats;

	
- (NSMutableSet*)chatsSet {
	[self willAccessValueForKey:@"chats"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"chats"];
  
	[self didAccessValueForKey:@"chats"];
	return result;
}
	






@end
