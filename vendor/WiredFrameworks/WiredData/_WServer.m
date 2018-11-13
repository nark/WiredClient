// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WServer.m instead.

#import "_WServer.h"

const struct WServerAttributes WServerAttributes = {
	.address = @"address",
	.banner = @"banner",
	.downloadSpeed = @"downloadSpeed",
	.downloads = @"downloads",
	.lastConnectDate = @"lastConnectDate",
	.login = @"login",
	.numberOfFiles = @"numberOfFiles",
	.password = @"password",
	.preferredNick = @"preferredNick",
	.preferredStatus = @"preferredStatus",
	.serverDescription = @"serverDescription",
	.serverName = @"serverName",
	.size = @"size",
	.startTime = @"startTime",
	.supportRsrc = @"supportRsrc",
	.uploadSpeed = @"uploadSpeed",
	.uploads = @"uploads",
};

const struct WServerRelationships WServerRelationships = {
	.events = @"events",
	.privateMessages = @"privateMessages",
	.publicChat = @"publicChat",
};

const struct WServerFetchedProperties WServerFetchedProperties = {
};

@implementation WServerID
@end

@implementation _WServer

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Server";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Server" inManagedObjectContext:moc_];
}

- (WServerID*)objectID {
	return (WServerID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"downloadSpeedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"downloadSpeed"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"downloadsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"downloads"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"numberOfFilesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"numberOfFiles"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"sizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"size"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"supportRsrcValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"supportRsrc"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"uploadSpeedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"uploadSpeed"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"uploadsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"uploads"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic address;






@dynamic banner;






@dynamic downloadSpeed;



- (int32_t)downloadSpeedValue {
	NSNumber *result = [self downloadSpeed];
	return [result intValue];
}

- (void)setDownloadSpeedValue:(int32_t)value_ {
	[self setDownloadSpeed:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveDownloadSpeedValue {
	NSNumber *result = [self primitiveDownloadSpeed];
	return [result intValue];
}

- (void)setPrimitiveDownloadSpeedValue:(int32_t)value_ {
	[self setPrimitiveDownloadSpeed:[NSNumber numberWithInt:value_]];
}





@dynamic downloads;



- (int32_t)downloadsValue {
	NSNumber *result = [self downloads];
	return [result intValue];
}

- (void)setDownloadsValue:(int32_t)value_ {
	[self setDownloads:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveDownloadsValue {
	NSNumber *result = [self primitiveDownloads];
	return [result intValue];
}

- (void)setPrimitiveDownloadsValue:(int32_t)value_ {
	[self setPrimitiveDownloads:[NSNumber numberWithInt:value_]];
}





@dynamic lastConnectDate;






@dynamic login;






@dynamic numberOfFiles;



- (int64_t)numberOfFilesValue {
	NSNumber *result = [self numberOfFiles];
	return [result longLongValue];
}

- (void)setNumberOfFilesValue:(int64_t)value_ {
	[self setNumberOfFiles:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveNumberOfFilesValue {
	NSNumber *result = [self primitiveNumberOfFiles];
	return [result longLongValue];
}

- (void)setPrimitiveNumberOfFilesValue:(int64_t)value_ {
	[self setPrimitiveNumberOfFiles:[NSNumber numberWithLongLong:value_]];
}





@dynamic password;






@dynamic preferredNick;






@dynamic preferredStatus;






@dynamic serverDescription;






@dynamic serverName;






@dynamic size;



- (int64_t)sizeValue {
	NSNumber *result = [self size];
	return [result longLongValue];
}

- (void)setSizeValue:(int64_t)value_ {
	[self setSize:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveSizeValue {
	NSNumber *result = [self primitiveSize];
	return [result longLongValue];
}

- (void)setPrimitiveSizeValue:(int64_t)value_ {
	[self setPrimitiveSize:[NSNumber numberWithLongLong:value_]];
}





@dynamic startTime;






@dynamic supportRsrc;



- (BOOL)supportRsrcValue {
	NSNumber *result = [self supportRsrc];
	return [result boolValue];
}

- (void)setSupportRsrcValue:(BOOL)value_ {
	[self setSupportRsrc:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveSupportRsrcValue {
	NSNumber *result = [self primitiveSupportRsrc];
	return [result boolValue];
}

- (void)setPrimitiveSupportRsrcValue:(BOOL)value_ {
	[self setPrimitiveSupportRsrc:[NSNumber numberWithBool:value_]];
}





@dynamic uploadSpeed;



- (int32_t)uploadSpeedValue {
	NSNumber *result = [self uploadSpeed];
	return [result intValue];
}

- (void)setUploadSpeedValue:(int32_t)value_ {
	[self setUploadSpeed:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveUploadSpeedValue {
	NSNumber *result = [self primitiveUploadSpeed];
	return [result intValue];
}

- (void)setPrimitiveUploadSpeedValue:(int32_t)value_ {
	[self setPrimitiveUploadSpeed:[NSNumber numberWithInt:value_]];
}





@dynamic uploads;



- (int32_t)uploadsValue {
	NSNumber *result = [self uploads];
	return [result intValue];
}

- (void)setUploadsValue:(int32_t)value_ {
	[self setUploads:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveUploadsValue {
	NSNumber *result = [self primitiveUploads];
	return [result intValue];
}

- (void)setPrimitiveUploadsValue:(int32_t)value_ {
	[self setPrimitiveUploads:[NSNumber numberWithInt:value_]];
}





@dynamic events;

	
- (NSMutableSet*)eventsSet {
	[self willAccessValueForKey:@"events"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"events"];
  
	[self didAccessValueForKey:@"events"];
	return result;
}
	

@dynamic privateMessages;

	
- (NSMutableSet*)privateMessagesSet {
	[self willAccessValueForKey:@"privateMessages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"privateMessages"];
  
	[self didAccessValueForKey:@"privateMessages"];
	return result;
}
	

@dynamic publicChat;

	






@end
