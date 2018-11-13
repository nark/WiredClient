// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WNode.h instead.

#import <CoreData/CoreData.h>


extern const struct WNodeAttributes {
	 NSString *appBuild;
	 NSString *appName;
	 NSString *appVersion;
	 NSString *arch;
	 NSString *osName;
	 NSString *osVersion;
} WNodeAttributes;

extern const struct WNodeRelationships {
} WNodeRelationships;

extern const struct WNodeFetchedProperties {
} WNodeFetchedProperties;









@interface WNodeID : NSManagedObjectID {}
@end

@interface _WNode : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WNodeID*)objectID;





@property (nonatomic, retain) NSString* appBuild;



//- (BOOL)validateAppBuild:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* appName;



//- (BOOL)validateAppName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* appVersion;



//- (BOOL)validateAppVersion:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* arch;



//- (BOOL)validateArch:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* osName;



//- (BOOL)validateOsName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSString* osVersion;



//- (BOOL)validateOsVersion:(id*)value_ error:(NSError**)error_;






@end

@interface _WNode (CoreDataGeneratedAccessors)

@end

@interface _WNode (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAppBuild;
- (void)setPrimitiveAppBuild:(NSString*)value;




- (NSString*)primitiveAppName;
- (void)setPrimitiveAppName:(NSString*)value;




- (NSString*)primitiveAppVersion;
- (void)setPrimitiveAppVersion:(NSString*)value;




- (NSString*)primitiveArch;
- (void)setPrimitiveArch:(NSString*)value;




- (NSString*)primitiveOsName;
- (void)setPrimitiveOsName:(NSString*)value;




- (NSString*)primitiveOsVersion;
- (void)setPrimitiveOsVersion:(NSString*)value;




@end
