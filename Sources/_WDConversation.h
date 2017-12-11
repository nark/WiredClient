// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDConversation.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "WDMessagesNode.h"

NS_ASSUME_NONNULL_BEGIN

@class WDMessage;

@interface WDConversationID : WDMessagesNodeID {}
@end

@interface _WDConversation : WDMessagesNode
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) WDConversationID *objectID;

@property (nonatomic, strong, nullable) NSNumber* numberOfUnreads;

@property (atomic) int32_t numberOfUnreadsValue;
- (int32_t)numberOfUnreadsValue;
- (void)setNumberOfUnreadsValue:(int32_t)value_;

@property (nonatomic, strong, nullable) NSString* serverName;

@property (nonatomic, strong, nullable) NSSet<WDMessage*> *messages;
- (nullable NSMutableSet<WDMessage*>*)messagesSet;

@end

@interface _WDConversation (MessagesCoreDataGeneratedAccessors)
- (void)addMessages:(NSSet<WDMessage*>*)value_;
- (void)removeMessages:(NSSet<WDMessage*>*)value_;
- (void)addMessagesObject:(WDMessage*)value_;
- (void)removeMessagesObject:(WDMessage*)value_;

@end

@interface _WDConversation (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveNumberOfUnreads;
- (void)setPrimitiveNumberOfUnreads:(nullable NSNumber*)value;

- (int32_t)primitiveNumberOfUnreadsValue;
- (void)setPrimitiveNumberOfUnreadsValue:(int32_t)value_;

- (nullable NSString*)primitiveServerName;
- (void)setPrimitiveServerName:(nullable NSString*)value;

- (NSMutableSet<WDMessage*>*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet<WDMessage*>*)value;

@end

@interface WDConversationAttributes: NSObject 
+ (NSString *)numberOfUnreads;
+ (NSString *)serverName;
@end

@interface WDConversationRelationships: NSObject
+ (NSString *)messages;
@end

NS_ASSUME_NONNULL_END
