// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDBroadcastsConversation.m instead.

#import "_WDBroadcastsConversation.h"

@implementation WDBroadcastsConversationID
@end

@implementation _WDBroadcastsConversation

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"BroadcastsConversation" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"BroadcastsConversation";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"BroadcastsConversation" inManagedObjectContext:moc_];
}

- (WDBroadcastsConversationID*)objectID {
	return (WDBroadcastsConversationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@end

