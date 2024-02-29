// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WEvent.h instead.

#import <CoreData/CoreData.h>


extern const struct WEventAttributes {
	 NSString *eventDate;
	 NSString *eventDescription;
	 NSString *eventTitle;
	 NSString *eventType;
} WEventAttributes;

extern const struct WEventRelationships {
	 NSString *server;
} WEventRelationships;

extern const struct WEventFetchedProperties {
} WEventFetchedProperties;

@class WServer;






@interface WEventID : NSManagedObjectID {}
@end

@interface _WEvent : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WEventID*)objectID;





@property (nonatomic, retain) NSDate* eventDate;



//- (BOOL)validateEventDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* eventDescription;



//- (BOOL)validateEventDescription:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* eventTitle;



//- (BOOL)validateEventTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* eventType;



@property int32_t eventTypeValue;
- (int32_t)eventTypeValue;
- (void)setEventTypeValue:(int32_t)value_;

//- (BOOL)validateEventType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) WServer *server;

//- (BOOL)validateServer:(id*)value_ error:(NSError**)error_;





@end

@interface _WEvent (CoreDataGeneratedAccessors)

@end

@interface _WEvent (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveEventDate;
- (void)setPrimitiveEventDate:(NSDate*)value;




- (NSString*)primitiveEventDescription;
- (void)setPrimitiveEventDescription:(NSString*)value;




- (NSString*)primitiveEventTitle;
- (void)setPrimitiveEventTitle:(NSString*)value;




- (NSNumber*)primitiveEventType;
- (void)setPrimitiveEventType:(NSNumber*)value;

- (int32_t)primitiveEventTypeValue;
- (void)setPrimitiveEventTypeValue:(int32_t)value_;





- (WServer*)primitiveServer;
- (void)setPrimitiveServer:(WServer*)value;


@end
