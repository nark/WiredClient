// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WDPrivateMessage.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "WDMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface WDPrivateMessageID : WDMessageID {}
@end

@interface _WDPrivateMessage : WDMessage
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) WDPrivateMessageID *objectID;

@end

@interface _WDPrivateMessage (CoreDataGeneratedPrimitiveAccessors)

@end

NS_ASSUME_NONNULL_END
