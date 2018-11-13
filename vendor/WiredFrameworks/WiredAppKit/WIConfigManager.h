//
//  WIConfigManager.h
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 23/06/13.
//  Copyright (c) 2013 Read-Write. All rights reserved.
//

#import <WiredFoundation/WiredFoundation.h>

@class WIError;

@interface WIConfigManager : WIObject {
    NSString					*_configPath;
	
	WIDateFormatter				*_dateFormatter;
}

- (id)initWithConfigPath:(NSString *)configPath;

- (BOOL)setString:(NSString *)string forConfigWithName:(NSString *)name andWriteWithError:(WIError **)error;
- (NSString *)stringForConfigWithName:(NSString *)name;

@end
