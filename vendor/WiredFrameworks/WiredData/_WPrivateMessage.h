// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WPrivateMessage.h instead.

#import <CoreData/CoreData.h>
#import "WMessage.h"

extern const struct WPrivateMessageAttributes {
} WPrivateMessageAttributes;

extern const struct WPrivateMessageRelationships {
	 NSString *conversation;
	 NSString *server;
} WPrivateMessageRelationships;

extern const struct WPrivateMessageFetchedProperties {
} WPrivateMessageFetchedProperties;

@class WConversation;
@class WServer;


@interface WPrivateMessageID : NSManagedObjectID {}
@end

@interface _WPrivateMessage : WMessage {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WPrivateMessageID*)objectID;





@property (nonatomic, retain) WConversation *conversation;

//- (BOOL)validateConversation:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) WServer *server;

//- (BOOL)validateServer:(id*)value_ error:(NSError**)error_;





@end

@interface _WPrivateMessage (CoreDataGeneratedAccessors)

@end

@interface _WPrivateMessage (CoreDataGeneratedPrimitiveAccessors)



- (WConversation*)primitiveConversation;
- (void)setPrimitiveConversation:(WConversation*)value;



- (WServer*)primitiveServer;
- (void)setPrimitiveServer:(WServer*)value;


@end
