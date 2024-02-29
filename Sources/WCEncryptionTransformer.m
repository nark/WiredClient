//
//  WCEncryptionTransformer.m
//  WiredClient
//
//  Created by Rafaël Warnault on 13/09/13.
//
//

#import "WCEncryptionTransformer.h"
#import "WCDatabaseController.h"
#import "WCKeychain.h"

@implementation WCEncryptionTransformer

+ (Class)transformedValueClass
{
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (NSString*)key
{
    // Your version of this class might get this key from the app delegate or elsewhere.
    return [[WCDatabaseController sharedController] secretKey];
}


- (id)transformedValue:(NSData*)data
{
    // If there's no key (e.g. during a data migration), don't try to transform the data
    if (nil == [self key])
    {
        return data;
    }
    
    if (nil == data)
    {
        return nil;
    }
    
    return [data AES256EncryptedDataUsingKey:[self key] error:nil];
}

- (id)reverseTransformedValue:(NSData*)data
{
    // If there's no key (e.g. during a data migration), don't try to transform the data
    if (nil == [self key])
    {
        return data;
    }
    
    if (nil == data)
    {
        return nil;
    }
    
    return [data decryptedAES256DataUsingKey:[self key] error:nil];
}

@end
