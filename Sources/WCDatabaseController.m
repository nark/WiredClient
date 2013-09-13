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



#pragma mark -

@synthesize persistentStoreCoordinator      = _persistentStoreCoordinator;
@synthesize managedObjectModel              = _managedObjectModel;
@synthesize managedObjectContext            = _managedObjectContext;




#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}



- (void)dealloc
{
    [_persistentStoreCoordinator release];
    [_managedObjectModel release];
    [_managedObjectContext release];
    
    [super dealloc];
}




#pragma mark -

- (BOOL)save {
    NSError *error;
    
    error = nil;
    
    if(![self.managedObjectContext save:&error]) {
        NSLog(@"ERROR: Core Data saving error: %@", error);
        return  NO;
    }
    
    return  YES;
}



- (NSString *)secretKey {
    WCSecretKeyAccessoryViewController      *controller;
    NSAlert                                 *alert;
    NSString                                *secretKey;
    NSInteger                               result;
    
    secretKey = [[WCKeychain keychain] secretKey];
        
    if(!secretKey) {
        alert = [NSAlert alertWithMessageText:@"Define a Secret Key"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"You have not define a secret key yet. Wired Client uses a personnal secret key to encrypt/decrypt your local data. This key is stored into the Keychain to ensure its confidentiality."];
        
        controller = [WCSecretKeyAccessoryViewController viewController];
        
        [alert setAccessoryView:[controller view]];
        [alert setAlertStyle:NSCriticalAlertStyle];
        
        result = [alert runModal];
        
        if (result == NSAlertDefaultReturn &&
            [[controller secretKey] isEqualToString:[controller verifyKey]] &&
            [[controller secretKey] length] > 0) {
            
            secretKey = [controller secretKey]; 
                        
            [[WCKeychain keychain] setSecretKey:secretKey];
        } else {
            exit(0);
        }
    }
    
    return secretKey;
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
    
    NSURL *storeURL = [[[WCApplicationController sharedController] applicationFilesDirectory] URLByAppendingPathComponent:@"WiredClient.sqlite"];
    
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
