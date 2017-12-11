// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDMessagesConversation.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "WDConversation.h"

NS_ASSUME_NONNULL_BEGIN

@interface WDMessagesConversationID : WDConversationID {}
@end

@interface _WDMessagesConversation : WDConversation
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) WDMessagesConversationID *objectID;

@end

@interface _WDMessagesConversation (CoreDataGeneratedPrimitiveAccessors)

@end

NS_ASSUME_NONNULL_END
