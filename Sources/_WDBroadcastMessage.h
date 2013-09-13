// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDBroadcastMessage.h instead.

#import <CoreData/CoreData.h>
#import "WDMessage.h"

extern const struct WDBroadcastMessageAttributes {
} WDBroadcastMessageAttributes;

extern const struct WDBroadcastMessageRelationships {
} WDBroadcastMessageRelationships;

extern const struct WDBroadcastMessageFetchedProperties {
} WDBroadcastMessageFetchedProperties;



@interface WDBroadcastMessageID : NSManagedObjectID {}
@end

@interface _WDBroadcastMessage : WDMessage {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WDBroadcastMessageID*)objectID;






@end

@interface _WDBroadcastMessage (CoreDataGeneratedAccessors)

@end

@interface _WDBroadcastMessage (CoreDataGeneratedPrimitiveAccessors)


@end
