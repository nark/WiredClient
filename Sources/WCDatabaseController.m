//
//  WIDatabaseController.m
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 12/03/13.
//  Copyright (c) 2013 OPALE. All rights reserved.
//

#import "WCDatabaseController.h"
#import "WCApplicationController.h"
#import "WCSecretKeyAccessoryViewController.h"
#import "WCKeychain.h"


@interface WCDatabaseController (Private)

- (NSString *)_checkSecretKey;

@end





@implementation WCDatabaseController (Private)

- (NSString *)_checkSecretKey {
    WCSecretKeyAccessoryViewController      *controller;
    NSAlert                                 *alert;
    NSString                                *secretKey;
    NSInteger                               result;
    
    secretKey = [[WCKeychain keychain] secretKey];
    
    if(!secretKey) {
        alert = [NSAlert alertWithMessageText:NSLS(@"Define a Secret Key", @"Secret Key Alert Title")
                                defaultButton:@"OK"
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:NSLS(@"You have not define a secret key yet. Wired Client uses a personnal secret key to encrypt/decrypt your local data. The key is stored into your Keychain to ensure its confidentiality.", @"Secret Key Alert Message")];
        
        controller = [WCSecretKeyAccessoryViewController viewController];
        
        [alert setAccessoryView:[controller view]];
        [alert setAlertStyle:NSCriticalAlertStyle];
        
        result = [alert runModal];
        
        if (result == NSAlertDefaultReturn && [controller verifyKeys]) {
            secretKey = [controller secretKey];
            
            [[WCKeychain keychain] setSecretKey:secretKey];
        }
        else {
            exit(0);
        }
    }
    
    return secretKey;
}

@end




@implementation WCDatabaseController


#pragma mark -

static WCDatabaseController *_controller = nil;

+ (id)sharedController {
    if(!_controller) {
        _controller = [[[self class] alloc] init];
    }
    
    return _controller;
}


+ (NSManagedObjectContext *)context {
    return [[[self class] sharedController] managedObjectContext];
}


+ (NSOperationQueue *)queue {
    return [[[self class] sharedController] queue];
}




#pragma mark -

@synthesize persistentStoreCoordinator      = _persistentStoreCoordinator;
@synthesize managedObjectModel              = _managedObjectModel;
@synthesize managedObjectContext            = _managedObjectContext;
@synthesize queue                           = _queue;





#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}



- (void)dealloc
{
    [_persistentStoreCoordinator release];
    [_managedObjectModel release];
    [_managedObjectContext release];
    
    [_queue release];
    
    [super dealloc];
}




#pragma mark -

- (BOOL)save {
    [self saveContext:self.managedObjectContext];
    return YES;
}


- (BOOL)saveContext:(NSManagedObjectContext *)context {
    __block NSError *error;
    
    error = nil;
    
    //[context performBlock:^{
        if(![context save:&error]) {
            NSLog(@"ERROR: Core Data saving error: %@", error);
        }
    //}];
    return YES;
}


- (void)mergeChanges:(NSNotification *)notification {
    // Only interested in merging from master into main.
    //if ([notification object] != self.managedObjectContext) return;
    
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}


- (NSString *)secretKey {
    return [self _checkSecretKey];
}




#pragma mark -

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSBundle *bundle    = [NSBundle bundleForClass:[self class]];
    NSURL *modelURL     = [bundle URLForResource:@"WiredClient" withExtension:@"momd"];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}



- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
//    // get the coordinator
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    
//    // add store
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
//    [fileManager createDirectoryAtURL:applicationSupportURL withIntermediateDirectories:NO attributes:nil error:nil];
//    NSURL *databaseURL = [applicationSupportURL URLByAppendingPathComponent:@"WiredClient.sqlite"];
//    NSDictionary *options = @{
//                              EncryptedStorePassphraseKey : [self secretKey],
//                              NSMigratePersistentStoresAutomaticallyOption : @YES,
//                              NSInferMappingModelAutomaticallyOption : @YES
//                              };
//    NSError *error = nil;
//    NSPersistentStore *store = [_persistentStoreCoordinator
//                                addPersistentStoreWithType:EncryptedStoreType
//                                configuration:nil
//                                URL:databaseURL
//                                options:options
//                                error:&error];
//    
//    NSAssert(store, @"Unable to add persistent store\n%@", error);

    NSURL *storeURL;
    
#ifdef WCConfigurationRelease
    storeURL = [[[WCApplicationController sharedController] applicationFilesDirectory] URLByAppendingPathComponent:@"WiredClient.sqlite"];
#else
    storeURL = [[[WCApplicationController sharedController] applicationFilesDirectory] URLByAppendingPathComponent:@"WiredClientDebug.sqlite"];
#endif
        
    NSError *error = nil;
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    }

    return _persistentStoreCoordinator;
}



- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"fr.read-write.WiredClient" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    [_managedObjectContext setRetainsRegisteredObjects:YES];
    
    return _managedObjectContext;
}


@end
