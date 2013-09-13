//
//  WIDatabaseController.h
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 12/03/13.
//  Copyright (c) 2013 OPALE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCDatabaseController : NSObject {
    NSPersistentStoreCoordinator    *_persistentStoreCoordinator;
    NSManagedObjectModel            *_managedObjectModel;
    NSManagedObjectContext          *_managedObjectContext;
}

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;

+ (id)sharedController;

+ (NSManagedObjectContext *)context;

- (NSString *)secretKey;
- (BOOL)save;

@end
