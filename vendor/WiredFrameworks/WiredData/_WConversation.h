// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WConversation.h instead.

#import <CoreData/CoreData.h>


extern const struct WConversationAttributes {
	 NSString *withNick;
} WConversationAttributes;

extern const struct WConversationRelationships {
	 NSString *messages;
} WConversationRelationships;

extern const struct WConversationFetchedProperties {
} WConversationFetchedProperties;

@class WPrivateMessage;



@interface WConversationID : NSManagedObjectID {}
@end

@interface _WConversation : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WConversationID*)objectID;





@property (nonatomic, retain) NSString* withNick;



//- (BOOL)validateWithNick:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSSet *messages;

- (NSMutableSet*)messagesSet;





@end

@interface _WConversation (CoreDataGeneratedAccessors)

- (void)addMessages:(NSSet*)value_;
- (void)removeMessages:(NSSet*)value_;
- (void)addMessagesObject:(WPrivateMessage*)value_;
- (void)removeMessagesObject:(WPrivateMessage*)value_;

@end

@interface _WConversation (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveWithNick;
- (void)setPrimitiveWithNick:(NSString*)value;





- (NSMutableSet*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet*)value;


@end
