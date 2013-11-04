// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessagesNode.h instead.

#import <CoreData/CoreData.h>


extern const struct WDMessagesNodeAttributes {
	 NSString *active;
	 NSString *date;
	 NSString *direction;
	 NSString *identifier;
	 NSString *nick;
	 NSString *unread;
	 NSString *user;
} WDMessagesNodeAttributes;

extern const struct WDMessagesNodeRelationships {
} WDMessagesNodeRelationships;

extern const struct WDMessagesNodeFetchedProperties {
} WDMessagesNodeFetchedProperties;








@class NSObject;

@interface WDMessagesNodeID : NSManagedObjectID {}
@end

@interface _WDMessagesNode : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WDMessagesNodeID*)objectID;





@property (nonatomic, retain) NSNumber* active;



@property BOOL activeValue;
- (BOOL)activeValue;
- (void)setActiveValue:(BOOL)value_;

//- (BOOL)validateActive:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSDate* date;



//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* direction;



@property int32_t directionValue;
- (int32_t)directionValue;
- (void)setDirectionValue:(int32_t)value_;

//- (BOOL)validateDirection:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* identifier;



//- (BOOL)validateIdentifier:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* nick;



//- (BOOL)validateNick:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* unread;



@property BOOL unreadValue;
- (BOOL)unreadValue;
- (void)setUnreadValue:(BOOL)value_;

//- (BOOL)validateUnread:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) id user;



//- (BOOL)validateUser:(id*)value_ error:(NSError**)error_;






@end

@interface _WDMessagesNode (CoreDataGeneratedAccessors)

@end

@interface _WDMessagesNode (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveActive;
- (void)setPrimitiveActive:(NSNumber*)value;

- (BOOL)primitiveActiveValue;
- (void)setPrimitiveActiveValue:(BOOL)value_;




- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;




- (NSNumber*)primitiveDirection;
- (void)setPrimitiveDirection:(NSNumber*)value;

- (int32_t)primitiveDirectionValue;
- (void)setPrimitiveDirectionValue:(int32_t)value_;




- (NSString*)primitiveIdentifier;
- (void)setPrimitiveIdentifier:(NSString*)value;




- (NSString*)primitiveNick;
- (void)setPrimitiveNick:(NSString*)value;




- (NSNumber*)primitiveUnread;
- (void)setPrimitiveUnread:(NSNumber*)value;

- (BOOL)primitiveUnreadValue;
- (void)setPrimitiveUnreadValue:(BOOL)value_;




- (id)primitiveUser;
- (void)setPrimitiveUser:(id)value;




@end
