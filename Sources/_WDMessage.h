// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessage.h instead.

#import <CoreData/CoreData.h>
#import "WDMessagesNode.h"

extern const struct WDMessageAttributes {
	 NSString *draft;
	 NSString *message;
} WDMessageAttributes;

extern const struct WDMessageRelationships {
	 NSString *conversation;
} WDMessageRelationships;

extern const struct WDMessageFetchedProperties {
} WDMessageFetchedProperties;

@class WDConversation;




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




@property (nonatomic, retain) NSString* message;


//- (BOOL)validateMessage:(id*)value_ error:(NSError**)error_;





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




- (NSString*)primitiveMessage;
- (void)setPrimitiveMessage:(NSString*)value;





- (WDConversation*)primitiveConversation;
- (void)setPrimitiveConversation:(WDConversation*)value;


@end
