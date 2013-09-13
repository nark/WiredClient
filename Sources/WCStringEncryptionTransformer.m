//
//  WCStringEncryptionTransformer.m
//  WiredClient
//
//  Created by Rafaël Warnault on 13/09/13.
//
//

#import "WCStringEncryptionTransformer.h"


@implementation WCStringEncryptionTransformer


+ (Class)transformedValueClass
{
    return [NSString class];
}


- (id)transformedValue:(NSString*)string
{
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [super transformedValue:data];
}


- (id)reverseTransformedValue:(NSData*)data
{
    if (nil == data)
    {
        return nil;
    }
    
    data = [super reverseTransformedValue:data];
    
    return [[[NSString alloc] initWithBytes:[data bytes]
                                     length:[data length]
                                   encoding:NSUTF8StringEncoding]
            autorelease];
}


@end
