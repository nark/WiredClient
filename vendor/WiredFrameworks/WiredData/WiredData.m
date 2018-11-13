//
//  WiredData.m
//  WiredData
//
//  Created by Rafaël Warnault on 30/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import "WiredData.h"

static NSManagedObjectModel *__managedObjectModel;

@implementation WiredData

+ (NSManagedObjectModel *)managedObjectModel {
    if (!__managedObjectModel) 
    {
        NSMutableSet *allBundles = [[[NSMutableSet alloc] init] autorelease];
        [allBundles addObjectsFromArray: [NSBundle allBundles]];
        [allBundles addObjectsFromArray: [NSBundle allFrameworks]];
        
        __managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    }
    return __managedObjectModel;
}

@end
