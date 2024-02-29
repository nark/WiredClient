// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WChatMessage.h instead.

#import <CoreData/CoreData.h>
#import "WMessage.h"

extern const struct WChatMessageAttributes {
	 NSString *type;
} WChatMessageAttributes;

extern const struct WChatMessageRelationships {
	 NSString *chat;
} WChatMessageRelationships;

extern const struct WChatMessageFetchedProperties {
} WChatMessageFetchedProperties;

@class WChat;



@interface WChatMessageID : NSManagedObjectID {}
@end

@interface _WChatMessage : WMessage {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WChatMessageID*)objectID;





@property (nonatomic, retain) NSString* type;



//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) WChat *chat;

//- (BOOL)validateChat:(id*)value_ error:(NSError**)error_;





@end

@interface _WChatMessage (CoreDataGeneratedAccessors)

@end

@interface _WChatMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;





- (WChat*)primitiveChat;
- (void)setPrimitiveChat:(WChat*)value;


@end
