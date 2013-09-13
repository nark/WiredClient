// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessage.h instead.

#import <CoreData/CoreData.h>
#import "WDMessagesNode.h"

extern const struct WDMessageAttributes {
	 NSString *draft;
	 NSString *message;
	 NSString *unread;
} WDMessageAttributes;

extern const struct WDMessageRelationships {
	 NSString *conversation;
} WDMessageRelationships;

extern const struct WDMessageFetchedProperties {
} WDMessageFetchedProperties;

@class WDConversation;


@class NSObject;


@interface WDMessageID : NSManagedObjectID {}
@end

@interface _WDMessage : WDMessagesNode {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WDMessageID*)objectID;




@property (nonatomic, retain) NSNumber* draft;


@property BOOL draftValue;
- (BOOL)draftValue;
- (void)setDraftValue:(BOOL)value_;

//- (BOOL)validateDraft:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) id message;


//- (BOOL)validateMessage:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber* unread;


@property BOOL unreadValue;
- (BOOL)unreadValue;
- (void)setUnreadValue:(BOOL)value_;

//- (BOOL)validateUnread:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) WDConversation* conversation;

//- (BOOL)validateConversation:(id*)value_ error:(NSError**)error_;





@end

@interface _WDMessage (CoreDataGeneratedAccessors)

@end

@interface _WDMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveDraft;
- (void)setPrimitiveDraft:(NSNumber*)value;

- (BOOL)primitiveDraftValue;
- (void)setPrimitiveDraftValue:(BOOL)value_;




- (id)primitiveMessage;
- (void)setPrimitiveMessage:(id)value;




- (NSNumber*)primitiveUnread;
- (void)setPrimitiveUnread:(NSNumber*)value;

- (BOOL)primitiveUnreadValue;
- (void)setPrimitiveUnreadValue:(BOOL)value_;





- (WDConversation*)primitiveConversation;
- (void)setPrimitiveConversation:(WDConversation*)value;


@end
