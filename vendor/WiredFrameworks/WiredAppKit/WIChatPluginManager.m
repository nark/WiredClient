//
//  WIChatPluginManager.m
//  wired
//
//  Created by Rafaël Warnault on 16/06/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WIChatPluginManager.h"




@interface WIChatPluginManager (Private)

- (void)_loadPlugins;

- (NSArray *)_pluginsAtPath:(NSString *)path;

@end






@implementation WIChatPluginManager (Private)

- (void)_loadPlugins {
    for(NSString *path in _paths)
        [_plugins addObjectsFromArray:[self _pluginsAtPath:path]];
}



- (NSArray *)_pluginsAtPath:(NSString *)path {
    NSFileManager       *fileManager;
    NSMutableArray      *result;
    NSArray             *fileNames;
    NSString            *subPath;
    NSBundle            *bundle;
    NSError             *error;
    
    fileManager     = [NSFileManager defaultManager];
    result          = [NSMutableArray array];
    fileNames       = [fileManager contentsOfDirectoryAtPath:path error:&error];
    
    for(NSString *fileName in fileNames) {
        subPath = [path stringByAppendingPathComponent:fileName];
        
        if(![subPath hasPrefix:@"."]) {
            if([[subPath pathExtension] isEqualToString:@"WiredChatCommand"]) {
                bundle = [NSBundle bundleWithPath:subPath];
                
                if(bundle != nil)
                    [result addObject:bundle];
            }
        }
    }
    
    return result;
}

@end






@implementation WIChatPluginManager



#pragma mark -

- (id)initWithPath:(NSArray *)paths
{
    self = [super init];
    if (self) {
        _paths = [[NSMutableArray arrayWithArray:paths] retain];
        _plugins = [[NSMutableArray alloc] init];
        
        [self reloadPlugins];
    }
    return self;
}


- (void)dealloc
{
    [_paths release];
    [_plugins release];
    [super dealloc];
}





#pragma mark -

- (void)reloadPlugins {
    [_paths removeAllObjects];
    
    [self _loadPlugins];
}





#pragma mark -

- (NSArray *)plugins {
    return _plugins;
}



- (void)addPath:(NSString *)path {
    [_paths addObject:path];
}


- (NSArray *)paths {
    return _paths;
}

@end
