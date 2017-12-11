// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessagesNode.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class NSObject;

@interface WDMessagesNodeID : NSManagedObjectID {}
@end

@interface _WDMessagesNode : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) WDMessagesNodeID *objectID;

@property (nonatomic, strong, nullable) NSNumber* active;

@property (atomic) BOOL activeValue;
- (BOOL)activeValue;
- (void)setActiveValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSDate* date;

@property (nonatomic, strong, nullable) NSNumber* direction;

@property (atomic) int32_t directionValue;
- (int32_t)directionValue;
- (void)setDirectionValue:(int32_t)value_;

@property (nonatomic, strong, nullable) NSString* identifier;

@property (nonatomic, strong, nullable) NSString* nick;

@property (nonatomic, strong, nullable) NSNumber* unread;

@property (atomic) BOOL unreadValue;
- (BOOL)unreadValue;
- (void)setUnreadValue:(BOOL)value_;

@property (nonatomic, strong, nullable) id user;

@end

@interface _WDMessagesNode (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveActive;
- (void)setPrimitiveActive:(nullable NSNumber*)value;

- (BOOL)primitiveActiveValue;
- (void)setPrimitiveActiveValue:(BOOL)value_;

- (nullable NSDate*)primitiveDate;
- (void)setPrimitiveDate:(nullable NSDate*)value;

- (nullable NSNumber*)primitiveDirection;
- (void)setPrimitiveDirection:(nullable NSNumber*)value;

- (int32_t)primitiveDirectionValue;
- (void)setPrimitiveDirectionValue:(int32_t)value_;

- (nullable NSString*)primitiveIdentifier;
- (void)setPrimitiveIdentifier:(nullable NSString*)value;

- (nullable NSString*)primitiveNick;
- (void)setPrimitiveNick:(nullable NSString*)value;

- (nullable NSNumber*)primitiveUnread;
- (void)setPrimitiveUnread:(nullable NSNumber*)value;

- (BOOL)primitiveUnreadValue;
- (void)setPrimitiveUnreadValue:(BOOL)value_;

- (nullable id)primitiveUser;
- (void)setPrimitiveUser:(nullable id)value;

@end

@interface WDMessagesNodeAttributes: NSObject 
+ (NSString *)active;
+ (NSString *)date;
+ (NSString *)direction;
+ (NSString *)identifier;
+ (NSString *)nick;
+ (NSString *)unread;
+ (NSString *)user;
@end

NS_ASSUME_NONNULL_END
