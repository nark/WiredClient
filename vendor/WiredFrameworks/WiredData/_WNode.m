// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WNode.m instead.

#import "_WNode.h"

const struct WNodeAttributes WNodeAttributes = {
	.appBuild = @"appBuild",
	.appName = @"appName",
	.appVersion = @"appVersion",
	.arch = @"arch",
	.osName = @"osName",
	.osVersion = @"osVersion",
};

const struct WNodeRelationships WNodeRelationships = {
};

const struct WNodeFetchedProperties WNodeFetchedProperties = {
};

@implementation WNodeID
@end

@implementation _WNode

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Node";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Node" inManagedObjectContext:moc_];
}

- (WNodeID*)objectID {
	return (WNodeID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic appBuild;






@dynamic appName;






@dynamic appVersion;






@dynamic arch;






@dynamic osName;






@dynamic osVersion;











@end
