// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDBroadcastMessage.m instead.

#import "_WDBroadcastMessage.h"

@implementation WDBroadcastMessageID
@end

@implementation _WDBroadcastMessage

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"BroadcastMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"BroadcastMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"BroadcastMessage" inManagedObjectContext:moc_];
}

- (WDBroadcastMessageID*)objectID {
	return (WDBroadcastMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@end

