// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WChat.m instead.

#import "_WChat.h"

const struct WChatAttributes WChatAttributes = {
	.chatID = @"chatID",
	.topic = @"topic",
	.topicNick = @"topicNick",
	.topicTime = @"topicTime",
};

const struct WChatRelationships WChatRelationships = {
	.messages = @"messages",
	.server = @"server",
	.users = @"users",
};

const struct WChatFetchedProperties WChatFetchedProperties = {
};

@implementation WChatID
@end

@implementation _WChat

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Chat" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Chat";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Chat" inManagedObjectContext:moc_];
}

- (WChatID*)objectID {
	return (WChatID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"chatIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"chatID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic chatID;



- (int32_t)chatIDValue {
	NSNumber *result = [self chatID];
	return [result intValue];
}

- (void)setChatIDValue:(int32_t)value_ {
	[self setChatID:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveChatIDValue {
	NSNumber *result = [self primitiveChatID];
	return [result intValue];
}

- (void)setPrimitiveChatIDValue:(int32_t)value_ {
	[self setPrimitiveChatID:[NSNumber numberWithInt:value_]];
}





@dynamic topic;






@dynamic topicNick;






@dynamic topicTime;






@dynamic messages;

	
- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];
  
	[self didAccessValueForKey:@"messages"];
	return result;
}
	

@dynamic server;

	

@dynamic users;

	
- (NSMutableSet*)usersSet {
	[self willAccessValueForKey:@"users"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"users"];
  
	[self didAccessValueForKey:@"users"];
	return result;
}
	






@end
