//
//  WIDatabaseController.h
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 12/03/13.
//  Copyright (c) 2013 Read-Write.fr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCDatabaseController : NSObject {
    NSPersistentStoreCoordinator    *_persistentStoreCoordinator;
    NSManagedObjectModel            *_managedObjectModel;
    NSManagedObjectContext          *_managedObjectContext;
    
    NSOperationQueue                *_queue;
}

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;

@property (readwrite, retain)           NSOperationQueue                *queue;

+ (id)                                  sharedController;

+ (NSManagedObjectContext *)            context;
+ (NSOperationQueue *)                  queue;

//- (NSString *)                          secretKey;

- (BOOL)                                save;
- (BOOL)                                saveContext:(NSManagedObjectContext *)context;
- (void)                                mergeChanges:(NSNotification *)notification;

@end
