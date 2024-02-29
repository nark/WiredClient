//
//  WCFilesWiredFileSystem.m
//  WiredClient
//
//  Created by Rafaël Warnault on 19/01/13.
//
//

#import "WCFilesWiredFileSystem.h"


static NSString *helloStr = @"Hello World!\n";
static NSString *helloPath = @"/hello.txt";


@implementation WCFilesWiredFileSystem

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    return [NSArray arrayWithObject:[helloPath lastPathComponent]];
}

- (NSData *)contentsAtPath:(NSString *)path {
    if ([path isEqualToString:helloPath])
        return [helloStr dataUsingEncoding:NSUTF8StringEncoding];
    return nil;
}

#pragma mark - Custom Icon

- (NSDictionary *)finderAttributesAtPath:(NSString *)path
                                   error:(NSError **)error {
    if ([path isEqualToString:helloPath]) {
        NSNumber* finderFlags = [NSNumber numberWithLong:kHasCustomIcon];
        return [NSDictionary dictionaryWithObject:finderFlags
                                           forKey:kGMUserFileSystemFinderFlagsKey];
    }
    return nil;
}

- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error {
    if ([path isEqualToString:helloPath]) {
        NSString *file = [[NSBundle mainBundle] pathForResource:@"hellodoc" ofType:@"icns"];
        return [NSDictionary dictionaryWithObject:[NSData dataWithContentsOfFile:file]
                                           forKey:kGMUserFileSystemCustomIconDataKey];
    }
    return nil;
}

@end
