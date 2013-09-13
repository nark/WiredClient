// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDConversation.m instead.

#import "_WDConversation.h"

const struct WDConversationAttributes WDConversationAttributes = {
	.serverName = @"serverName",
};

const struct WDConversationRelationships WDConversationRelationships = {
	.messages = @"messages",
};

const struct WDConversationFetchedProperties WDConversationFetchedProperties = {
};

@implementation WDConversationID
@end

@implementation _WDConversation

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic serverName;






@dynamic messages;

	
- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];
  
	[self didAccessValueForKey:@"messages"];
	return result;
}
	






@end
