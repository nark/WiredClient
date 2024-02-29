// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WChatMessage.m instead.

#import "_WChatMessage.h"

const struct WChatMessageAttributes WChatMessageAttributes = {
	.type = @"type",
};

const struct WChatMessageRelationships WChatMessageRelationships = {
	.chat = @"chat",
};

const struct WChatMessageFetchedProperties WChatMessageFetchedProperties = {
};

@implementation WChatMessageID
@end

@implementation _WChatMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ChatMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ChatMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ChatMessage" inManagedObjectContext:moc_];
}

- (WChatMessageID*)objectID {
	return (WChatMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic type;






@dynamic chat;

	






@end
