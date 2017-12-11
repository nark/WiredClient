// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDArchivesConversation.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "WDConversation.h"

NS_ASSUME_NONNULL_BEGIN

@interface WDArchivesConversationID : WDConversationID {}
@end

@interface _WDArchivesConversation : WDConversation
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) WDArchivesConversationID *objectID;

@end

@interface _WDArchivesConversation (CoreDataGeneratedPrimitiveAccessors)

@end

NS_ASSUME_NONNULL_END
