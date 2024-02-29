// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WUser.h instead.

#import <CoreData/CoreData.h>
#import "WNode.h"

extern const struct WUserAttributes {
	 NSString *icon;
	 NSString *idelTime;
	 NSString *idle;
	 NSString *isLocal;
	 NSString *login;
	 NSString *nick;
	 NSString *status;
	 NSString *userID;
	 NSString *wiredColor;
} WUserAttributes;

extern const struct WUserRelationships {
	 NSString *chats;
} WUserRelationships;

extern const struct WUserFetchedProperties {
} WUserFetchedProperties;

@class WChat;











@interface WUserID : NSManagedObjectID {}
@end

@interface _WUser : WNode {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WUserID*)objectID;





@property (nonatomic, retain) NSData* icon;



//- (BOOL)validateIcon:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSDate* idelTime;



//- (BOOL)validateIdelTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* idle;



@property BOOL idleValue;
- (BOOL)idleValue;
- (void)setIdleValue:(BOOL)value_;

//- (BOOL)validateIdle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* isLocal;



@property BOOL isLocalValue;
- (BOOL)isLocalValue;
- (void)setIsLocalValue:(BOOL)value_;

//- (BOOL)validateIsLocal:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* login;



//- (BOOL)validateLogin:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* nick;



//- (BOOL)validateNick:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* status;



//- (BOOL)validateStatus:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* userID;



@property int32_t userIDValue;
- (int32_t)userIDValue;
- (void)setUserIDValue:(int32_t)value_;

//- (BOOL)validateUserID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* wiredColor;



@property int32_t wiredColorValue;
- (int32_t)wiredColorValue;
- (void)setWiredColorValue:(int32_t)value_;

//- (BOOL)validateWiredColor:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSSet *chats;

- (NSMutableSet*)chatsSet;





@end

@interface _WUser (CoreDataGeneratedAccessors)

- (void)addChats:(NSSet*)value_;
- (void)removeChats:(NSSet*)value_;
- (void)addChatsObject:(WChat*)value_;
- (void)removeChatsObject:(WChat*)value_;

@end

@interface _WUser (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveIcon;
- (void)setPrimitiveIcon:(NSData*)value;




- (NSDate*)primitiveIdelTime;
- (void)setPrimitiveIdelTime:(NSDate*)value;




- (NSNumber*)primitiveIdle;
- (void)setPrimitiveIdle:(NSNumber*)value;

- (BOOL)primitiveIdleValue;
- (void)setPrimitiveIdleValue:(BOOL)value_;




- (NSNumber*)primitiveIsLocal;
- (void)setPrimitiveIsLocal:(NSNumber*)value;

- (BOOL)primitiveIsLocalValue;
- (void)setPrimitiveIsLocalValue:(BOOL)value_;




- (NSString*)primitiveLogin;
- (void)setPrimitiveLogin:(NSString*)value;




- (NSString*)primitiveNick;
- (void)setPrimitiveNick:(NSString*)value;




- (NSString*)primitiveStatus;
- (void)setPrimitiveStatus:(NSString*)value;




- (NSNumber*)primitiveUserID;
- (void)setPrimitiveUserID:(NSNumber*)value;

- (int32_t)primitiveUserIDValue;
- (void)setPrimitiveUserIDValue:(int32_t)value_;




- (NSNumber*)primitiveWiredColor;
- (void)setPrimitiveWiredColor:(NSNumber*)value;

- (int32_t)primitiveWiredColorValue;
- (void)setPrimitiveWiredColorValue:(int32_t)value_;





- (NSMutableSet*)primitiveChats;
- (void)setPrimitiveChats:(NSMutableSet*)value;


@end
