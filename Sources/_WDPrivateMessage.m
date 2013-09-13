// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDPrivateMessage.m instead.

#import "_WDPrivateMessage.h"

const struct WDPrivateMessageAttributes WDPrivateMessageAttributes = {
};

const struct WDPrivateMessageRelationships WDPrivateMessageRelationships = {
};

const struct WDPrivateMessageFetchedProperties WDPrivateMessageFetchedProperties = {
};

@implementation WDPrivateMessageID
@end

@implementation _WDPrivateMessage

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

- (WDPrivateMessageID*)objectID {
	return (WDPrivateMessageID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
