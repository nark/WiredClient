//
//  WIChatPluginManager.h
//  wired
//
//  Created by Rafaël Warnault on 16/06/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WIChatPluginManager : NSObject {
    NSMutableArray             *_paths;
    NSMutableArray             *_plugins;
}

- (id)initWithPath:(NSArray *)paths;

- (void)reloadPlugins;

- (void)addPath:(NSString *)path;
- (NSArray *)paths;

@end
