// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDArchivesConversation.m instead.

#import "_WDArchivesConversation.h"

@implementation WDArchivesConversationID
@end

@implementation _WDArchivesConversation

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ArchivesConversation" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ArchivesConversation";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ArchivesConversation" inManagedObjectContext:moc_];
}

- (WDArchivesConversationID*)objectID {
	return (WDArchivesConversationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@end

