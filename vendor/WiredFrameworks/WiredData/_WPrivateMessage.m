// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WPrivateMessage.m instead.

#import "_WPrivateMessage.h"

const struct WPrivateMessageAttributes WPrivateMessageAttributes = {
};

const struct WPrivateMessageRelationships WPrivateMessageRelationships = {
	.conversation = @"conversation",
	.server = @"server",
};

const struct WPrivateMessageFetchedProperties WPrivateMessageFetchedProperties = {
};

@implementation WPrivateMessageID
@end

@implementation _WPrivateMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"PrivateMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"PrivateMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"PrivateMessage" inManagedObjectContext:moc_];
}

- (WPrivateMessageID*)objectID {
	return (WPrivateMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic conversation;

	

@dynamic server;

	






@end
