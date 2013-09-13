// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDPrivateMessage.h instead.

#import <CoreData/CoreData.h>
#import "WDMessage.h"

extern const struct WDPrivateMessageAttributes {
} WDPrivateMessageAttributes;

extern const struct WDPrivateMessageRelationships {
} WDPrivateMessageRelationships;

extern const struct WDPrivateMessageFetchedProperties {
} WDPrivateMessageFetchedProperties;



@interface WDPrivateMessageID : NSManagedObjectID {}
@end

@interface _WDPrivateMessage : WDMessage {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WDPrivateMessageID*)objectID;






@end

@interface _WDPrivateMessage (CoreDataGeneratedAccessors)

@end

@interface _WDPrivateMessage (CoreDataGeneratedPrimitiveAccessors)


@end
