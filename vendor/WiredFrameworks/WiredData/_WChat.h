// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WChat.h instead.

#import <CoreData/CoreData.h>


extern const struct WChatAttributes {
	 NSString *chatID;
	 NSString *topic;
	 NSString *topicNick;
	 NSString *topicTime;
} WChatAttributes;

extern const struct WChatRelationships {
	 NSString *messages;
	 NSString *server;
	 NSString *users;
} WChatRelationships;

extern const struct WChatFetchedProperties {
} WChatFetchedProperties;

@class WChatMessage;
@class WServer;
@class WUser;






@interface WChatID : NSManagedObjectID {}
@end

@interface _WChat : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WChatID*)objectID;





@property (nonatomic, retain) NSNumber* chatID;



@property int32_t chatIDValue;
- (int32_t)chatIDValue;
- (void)setChatIDValue:(int32_t)value_;

//- (BOOL)validateChatID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* topic;



//- (BOOL)validateTopic:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* topicNick;



//- (BOOL)validateTopicNick:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSDate* topicTime;



//- (BOOL)validateTopicTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSSet *messages;

- (NSMutableSet*)messagesSet;




@property (nonatomic, retain) WServer *server;

//- (BOOL)validateServer:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSSet *users;

- (NSMutableSet*)usersSet;





@end

@interface _WChat (CoreDataGeneratedAccessors)

- (void)addMessages:(NSSet*)value_;
- (void)removeMessages:(NSSet*)value_;
- (void)addMessagesObject:(WChatMessage*)value_;
- (void)removeMessagesObject:(WChatMessage*)value_;

- (void)addUsers:(NSSet*)value_;
- (void)removeUsers:(NSSet*)value_;
- (void)addUsersObject:(WUser*)value_;
- (void)removeUsersObject:(WUser*)value_;

@end

@interface _WChat (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveChatID;
- (void)setPrimitiveChatID:(NSNumber*)value;

- (int32_t)primitiveChatIDValue;
- (void)setPrimitiveChatIDValue:(int32_t)value_;




- (NSString*)primitiveTopic;
- (void)setPrimitiveTopic:(NSString*)value;




- (NSString*)primitiveTopicNick;
- (void)setPrimitiveTopicNick:(NSString*)value;




- (NSDate*)primitiveTopicTime;
- (void)setPrimitiveTopicTime:(NSDate*)value;





- (NSMutableSet*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet*)value;



- (WServer*)primitiveServer;
- (void)setPrimitiveServer:(WServer*)value;



- (NSMutableSet*)primitiveUsers;
- (void)setPrimitiveUsers:(NSMutableSet*)value;


@end
