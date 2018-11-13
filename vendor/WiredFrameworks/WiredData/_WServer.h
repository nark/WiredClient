// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WServer.h instead.

#import <CoreData/CoreData.h>
#import "WNode.h"

extern const struct WServerAttributes {
	 NSString *address;
	 NSString *banner;
	 NSString *downloadSpeed;
	 NSString *downloads;
	 NSString *lastConnectDate;
	 NSString *login;
	 NSString *numberOfFiles;
	 NSString *password;
	 NSString *preferredNick;
	 NSString *preferredStatus;
	 NSString *serverDescription;
	 NSString *serverName;
	 NSString *size;
	 NSString *startTime;
	 NSString *supportRsrc;
	 NSString *uploadSpeed;
	 NSString *uploads;
} WServerAttributes;

extern const struct WServerRelationships {
	 NSString *events;
	 NSString *privateMessages;
	 NSString *publicChat;
} WServerRelationships;

extern const struct WServerFetchedProperties {
} WServerFetchedProperties;

@class WEvent;
@class WPrivateMessage;
@class WChat;



















@interface WServerID : NSManagedObjectID {}
@end

@interface _WServer : WNode {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WServerID*)objectID;





@property (nonatomic, retain) NSString* address;



//- (BOOL)validateAddress:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSData* banner;



//- (BOOL)validateBanner:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* downloadSpeed;



@property int32_t downloadSpeedValue;
- (int32_t)downloadSpeedValue;
- (void)setDownloadSpeedValue:(int32_t)value_;

//- (BOOL)validateDownloadSpeed:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* downloads;



@property int32_t downloadsValue;
- (int32_t)downloadsValue;
- (void)setDownloadsValue:(int32_t)value_;

//- (BOOL)validateDownloads:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSDate* lastConnectDate;



//- (BOOL)validateLastConnectDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* login;



//- (BOOL)validateLogin:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* numberOfFiles;



@property int64_t numberOfFilesValue;
- (int64_t)numberOfFilesValue;
- (void)setNumberOfFilesValue:(int64_t)value_;

//- (BOOL)validateNumberOfFiles:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* password;



//- (BOOL)validatePassword:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* preferredNick;



//- (BOOL)validatePreferredNick:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* preferredStatus;



//- (BOOL)validatePreferredStatus:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* serverDescription;



//- (BOOL)validateServerDescription:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* serverName;



//- (BOOL)validateServerName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* size;



@property int64_t sizeValue;
- (int64_t)sizeValue;
- (void)setSizeValue:(int64_t)value_;

//- (BOOL)validateSize:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSDate* startTime;



//- (BOOL)validateStartTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* supportRsrc;



@property BOOL supportRsrcValue;
- (BOOL)supportRsrcValue;
- (void)setSupportRsrcValue:(BOOL)value_;

//- (BOOL)validateSupportRsrc:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* uploadSpeed;



@property int32_t uploadSpeedValue;
- (int32_t)uploadSpeedValue;
- (void)setUploadSpeedValue:(int32_t)value_;

//- (BOOL)validateUploadSpeed:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSNumber* uploads;



@property int32_t uploadsValue;
- (int32_t)uploadsValue;
- (void)setUploadsValue:(int32_t)value_;

//- (BOOL)validateUploads:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSSet *events;

- (NSMutableSet*)eventsSet;




@property (nonatomic, retain) NSSet *privateMessages;

- (NSMutableSet*)privateMessagesSet;




@property (nonatomic, retain) WChat *publicChat;

//- (BOOL)validatePublicChat:(id*)value_ error:(NSError**)error_;





@end

@interface _WServer (CoreDataGeneratedAccessors)

- (void)addEvents:(NSSet*)value_;
- (void)removeEvents:(NSSet*)value_;
- (void)addEventsObject:(WEvent*)value_;
- (void)removeEventsObject:(WEvent*)value_;

- (void)addPrivateMessages:(NSSet*)value_;
- (void)removePrivateMessages:(NSSet*)value_;
- (void)addPrivateMessagesObject:(WPrivateMessage*)value_;
- (void)removePrivateMessagesObject:(WPrivateMessage*)value_;

@end

@interface _WServer (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAddress;
- (void)setPrimitiveAddress:(NSString*)value;




- (NSData*)primitiveBanner;
- (void)setPrimitiveBanner:(NSData*)value;




- (NSNumber*)primitiveDownloadSpeed;
- (void)setPrimitiveDownloadSpeed:(NSNumber*)value;

- (int32_t)primitiveDownloadSpeedValue;
- (void)setPrimitiveDownloadSpeedValue:(int32_t)value_;




- (NSNumber*)primitiveDownloads;
- (void)setPrimitiveDownloads:(NSNumber*)value;

- (int32_t)primitiveDownloadsValue;
- (void)setPrimitiveDownloadsValue:(int32_t)value_;




- (NSDate*)primitiveLastConnectDate;
- (void)setPrimitiveLastConnectDate:(NSDate*)value;




- (NSString*)primitiveLogin;
- (void)setPrimitiveLogin:(NSString*)value;




- (NSNumber*)primitiveNumberOfFiles;
- (void)setPrimitiveNumberOfFiles:(NSNumber*)value;

- (int64_t)primitiveNumberOfFilesValue;
- (void)setPrimitiveNumberOfFilesValue:(int64_t)value_;




- (NSString*)primitivePassword;
- (void)setPrimitivePassword:(NSString*)value;




- (NSString*)primitivePreferredNick;
- (void)setPrimitivePreferredNick:(NSString*)value;




- (NSString*)primitivePreferredStatus;
- (void)setPrimitivePreferredStatus:(NSString*)value;




- (NSString*)primitiveServerDescription;
- (void)setPrimitiveServerDescription:(NSString*)value;




- (NSString*)primitiveServerName;
- (void)setPrimitiveServerName:(NSString*)value;




- (NSNumber*)primitiveSize;
- (void)setPrimitiveSize:(NSNumber*)value;

- (int64_t)primitiveSizeValue;
- (void)setPrimitiveSizeValue:(int64_t)value_;




- (NSDate*)primitiveStartTime;
- (void)setPrimitiveStartTime:(NSDate*)value;




- (NSNumber*)primitiveSupportRsrc;
- (void)setPrimitiveSupportRsrc:(NSNumber*)value;

- (BOOL)primitiveSupportRsrcValue;
- (void)setPrimitiveSupportRsrcValue:(BOOL)value_;




- (NSNumber*)primitiveUploadSpeed;
- (void)setPrimitiveUploadSpeed:(NSNumber*)value;

- (int32_t)primitiveUploadSpeedValue;
- (void)setPrimitiveUploadSpeedValue:(int32_t)value_;




- (NSNumber*)primitiveUploads;
- (void)setPrimitiveUploads:(NSNumber*)value;

- (int32_t)primitiveUploadsValue;
- (void)setPrimitiveUploadsValue:(int32_t)value_;





- (NSMutableSet*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet*)value;



- (NSMutableSet*)primitivePrivateMessages;
- (void)setPrimitivePrivateMessages:(NSMutableSet*)value;



- (WChat*)primitivePublicChat;
- (void)setPrimitivePublicChat:(WChat*)value;


@end
