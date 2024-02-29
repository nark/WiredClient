// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WMessage.h instead.

#import <CoreData/CoreData.h>


extern const struct WMessageAttributes {
	 NSString *nick;
	 NSString *read;
	 NSString *sentDate;
	 NSString *text;
	 NSString *userID;
} WMessageAttributes;

extern const struct WMessageRelationships {
} WMessageRelationships;

extern const struct WMessageFetchedProperties {
} WMessageFetchedProperties;








@interface WMessageID : NSManagedObjectID {}
@end

@interface _WMessage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WMessageID*)objectID;





@property (nonatomic, retain) NSString* nick;



//- (BOOL)validateNick:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* read;



@property BOOL readValue;
- (BOOL)readValue;
- (void)setReadValue:(BOOL)value_;

//- (BOOL)validateRead:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSDate* sentDate;



//- (BOOL)validateSentDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* text;



//- (BOOL)validateText:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* userID;



@property int32_t userIDValue;
- (int32_t)userIDValue;
- (void)setUserIDValue:(int32_t)value_;

//- (BOOL)validateUserID:(id*)value_ error:(NSError**)error_;






@end

@interface _WMessage (CoreDataGeneratedAccessors)

@end

@interface _WMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveNick;
- (void)setPrimitiveNick:(NSString*)value;




- (NSNumber*)primitiveRead;
- (void)setPrimitiveRead:(NSNumber*)value;

- (BOOL)primitiveReadValue;
- (void)setPrimitiveReadValue:(BOOL)value_;




- (NSDate*)primitiveSentDate;
- (void)setPrimitiveSentDate:(NSDate*)value;




- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;




- (NSNumber*)primitiveUserID;
- (void)setPrimitiveUserID:(NSNumber*)value;

- (int32_t)primitiveUserIDValue;
- (void)setPrimitiveUserIDValue:(int32_t)value_;




@end
