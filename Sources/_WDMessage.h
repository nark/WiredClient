// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessage.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "WDMessagesNode.h"

NS_ASSUME_NONNULL_BEGIN

@class WDConversation;

@interface WDMessageID : WDMessagesNodeID {}
@end

@interface _WDMessage : WDMessagesNode
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) WDMessageID *objectID;

@property (nonatomic, strong, nullable) NSNumber* draft;

@property (atomic) BOOL draftValue;
- (BOOL)draftValue;
- (void)setDraftValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSString* message;

@property (nonatomic, strong, nullable) WDConversation *conversation;

@end

@interface _WDMessage (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveDraft;
- (void)setPrimitiveDraft:(nullable NSNumber*)value;

- (BOOL)primitiveDraftValue;
- (void)setPrimitiveDraftValue:(BOOL)value_;

- (nullable NSString*)primitiveMessage;
- (void)setPrimitiveMessage:(nullable NSString*)value;

- (nullable WDConversation*)primitiveConversation;
- (void)setPrimitiveConversation:(nullable WDConversation*)value;

@end

@interface WDMessageAttributes: NSObject 
+ (NSString *)draft;
+ (NSString *)message;
@end

@interface WDMessageRelationships: NSObject
+ (NSString *)conversation;
@end

NS_ASSUME_NONNULL_END
