//
//  NSImage+Data.h
//  Wired Client
//
//  Created by Rafael Warnault on 03/05/2020.
//

#import <Foundation/Foundation.h>

@interface NSImage (Data)

+ (BOOL)isImageAtPath:(NSString *)path;
+ (NSString *)contentTypeForImageData:(NSData *)data;

@end
