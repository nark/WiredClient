//
//  NSImage+Data.m
//  Wired Client
//
//  Created by Rafael Warnault on 03/05/2020.
//

#import "NSImage+Data.h"

@implementation NSImage (Data)

+ (BOOL)isImageAtPath:(NSString *)path {
    NSFileHandle    *handle;
    NSData          *data;
    
    handle = [NSFileHandle fileHandleForReadingAtPath:path];
    
    if (handle == nil) return NO;
    
    data = [handle readDataOfLength:4];
    
    if (data == nil) return NO;
        
    return ([NSImage contentTypeForImageData:data] != nil);
}

+ (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];

    switch (c) {
    case 0xFF:
        return @"image/jpeg";
    case 0x89:
        return @"image/png";
    case 0x47:
        return @"image/gif";
    case 0x49:
    case 0x4D:
        return @"image/tiff";
    }
    return nil;
}

@end
