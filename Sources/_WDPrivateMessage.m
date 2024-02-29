// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDPrivateMessage.m instead.

#import "_WDPrivateMessage.h"

@implementation WDPrivateMessageID
@end

@implementation _WDPrivateMessage

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
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

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@end

