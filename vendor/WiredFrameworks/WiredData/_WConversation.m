// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WConversation.m instead.

#import "_WConversation.h"

const struct WConversationAttributes WConversationAttributes = {
	.withNick = @"withNick",
};

const struct WConversationRelationships WConversationRelationships = {
	.messages = @"messages",
};

const struct WConversationFetchedProperties WConversationFetchedProperties = {
};

@implementation WConversationID
@end

@implementation _WConversation

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

- (WConversationID*)objectID {
	return (WConversationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic withNick;






@dynamic messages;

	
- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];
  
	[self didAccessValueForKey:@"messages"];
	return result;
}
	






@end
