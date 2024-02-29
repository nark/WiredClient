/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "WCConnection.h"
#import "WCKeychain.h"

@implementation WCKeychain

+ (WCKeychain *)keychain {
	static WCKeychain	*sharedKeychain;

	if(!sharedKeychain)
		sharedKeychain = [[self alloc] init];

	return sharedKeychain;
}



#pragma mark -

- (NSString *)passwordForBookmark:(NSDictionary *)bookmark {
	WIURL	*url;
	
	url = [WIURL URLWithScheme:@"wiredp7" hostpair:[bookmark objectForKey:WCBookmarksAddress]];
	[url setUser:[bookmark objectForKey:WCBookmarksLogin]];
	[url setPath:[bookmark objectForKey:WCBookmarksIdentifier]];
	
	return [self passwordForURL:url];
}



- (void)setPassword:(NSString *)password forBookmark:(NSDictionary *)bookmark {
	WIURL	*url;
	
	url = [WIURL URLWithScheme:@"wiredp7" hostpair:[bookmark objectForKey:WCBookmarksAddress]];
	[url setUser:[bookmark objectForKey:WCBookmarksLogin]];
	[url setPath:[bookmark objectForKey:WCBookmarksIdentifier]];
	
	[self setPassword:password forURL:url];
}



- (void)deletePasswordForBookmark:(NSDictionary *)bookmark {
	WIURL	*url;
	
	url = [WIURL URLWithScheme:@"wiredp7" hostpair:[bookmark objectForKey:WCBookmarksAddress]];
	[url setUser:[bookmark objectForKey:WCBookmarksLogin]];
	[url setPath:[bookmark objectForKey:WCBookmarksIdentifier]];
	
	[self deletePasswordForURL:url];
}



#pragma mark -

- (NSString *)passwordForTrackerBookmark:(NSDictionary *)bookmark {
	WIURL	*url;
	
	url = [WIURL URLWithScheme:@"wiredp7" hostpair:[bookmark objectForKey:WCTrackerBookmarksAddress]];
	[url setUser:[bookmark objectForKey:WCTrackerBookmarksLogin]];
	[url setPath:[bookmark objectForKey:WCTrackerBookmarksIdentifier]];
	
	return [self passwordForURL:url];
}



- (void)setPassword:(NSString *)password forTrackerBookmark:(NSDictionary *)bookmark {
	WIURL	*url;
	
	url = [WIURL URLWithScheme:@"wiredp7" hostpair:[bookmark objectForKey:WCTrackerBookmarksAddress]];
	[url setUser:[bookmark objectForKey:WCTrackerBookmarksLogin]];
	[url setPath:[bookmark objectForKey:WCTrackerBookmarksIdentifier]];
	
	[self setPassword:password forURL:url];
}



- (void)deletePasswordForTrackerBookmark:(NSDictionary *)bookmark {
	WIURL	*url;
	
	url = [WIURL URLWithScheme:@"wiredp7" hostpair:[bookmark objectForKey:WCTrackerBookmarksAddress]];
	[url setUser:[bookmark objectForKey:WCTrackerBookmarksLogin]];
	[url setPath:[bookmark objectForKey:WCTrackerBookmarksIdentifier]];
	
	[self deletePasswordForURL:url];
}



#pragma mark -

- (NSString *)passwordForURL:(WIURL *)url {
	NSData				*data;
	void				*password;
	UInt32				length;
	OSStatus			err;
	SecProtocolType		type;
	
	if([[url scheme] isEqualToString:@"wiredp7"])
		type = kSecProtocolTypeWired;
	else
		type = kSecProtocolTypeHTTP;
	
	err = SecKeychainFindInternetPassword(NULL,
										  [[url host] UTF8StringLength],
										  [[url host] UTF8String],
										  0,
										  NULL,
										  [[url user] UTF8StringLength],
										  [[url user] UTF8String],
										  [[url path] UTF8StringLength],
										  [[url path] UTF8String],
										  [url port] != WCServerPort ? [url port] : 0,
										  type,
										  kSecAuthenticationTypeDefault,
										  &length,
										  &password,
										  NULL);

	if(err != noErr)
		return NULL;

	data = [NSData dataWithBytes:password length:length];

    SecKeychainItemFreeContent(NULL, password);
	return [NSString stringWithData:data encoding:NSUTF8StringEncoding];
}



- (void)setPassword:(NSString *)password forURL:(WIURL *)url {
	NSData				*data;
	SecKeychainItemRef	item;
	OSStatus			err;
	SecProtocolType		type;
	
	if([[url scheme] isEqualToString:@"wiredp7"])
		type = kSecProtocolTypeWired;
	else
		type = kSecProtocolTypeHTTP;

	data = [password dataUsingEncoding:NSUTF8StringEncoding];
	
	//NSLog(@"'%@' -> '%@'", url, password);
	
	err = SecKeychainFindInternetPassword(NULL,
										  [[url host] UTF8StringLength],
										  [[url host] UTF8String],
										  0,
										  NULL,
										  [[url user] UTF8StringLength],
										  [[url user] UTF8String],
										  [[url path] UTF8StringLength],
										  [[url path] UTF8String],
										  [url port] != WCServerPort ? [url port] : 0,
										  type,
										  kSecAuthenticationTypeDefault,
										  0,
										  NULL,
										  &item);

	if(err == noErr) {
		err = SecKeychainItemModifyAttributesAndData(item, NULL, [data length], [data bytes]);

		if(err != noErr) {
			NSLog(@"SecKeychainItemModifyAttributesAndData: %d", err);

			return;
		}
	} else {
		err = SecKeychainAddInternetPassword(NULL,
											 [[url host] UTF8StringLength],
											 [[url host] UTF8String],
											 0,
											 NULL,
											 [[url user] UTF8StringLength],
											 [[url user] UTF8String],
											 [[url path] UTF8StringLength],
											 [[url path] UTF8String],
											 [url port] != WCServerPort ? [url port] : 0,
											 type,
											 kSecAuthenticationTypeDefault,
											 [data length],
											 [data bytes],
											 NULL);

		if(err != noErr) {
			NSLog(@"SecKeychainAddInternetPassword: %d", err);

			return;
		}
	}
}



- (void)deletePasswordForURL:(WIURL *)url {
    OSStatus err;
    SecProtocolType type;
    
    if ([[url scheme] isEqualToString:@"wiredp7"])
        type = kSecProtocolTypeWired;
    else
        type = kSecProtocolTypeHTTP;

    // Create a dictionary with the query parameters
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecAttrProtocol: @(type),
        (__bridge id)kSecAttrServer: [url host],
        (__bridge id)kSecAttrAccount: [url user],
        (__bridge id)kSecAttrPath: [url path],
        (__bridge id)kSecAttrPort: @([url port] != WCServerPort ? [url port] : 0)
    };

    // Try to find the password item
    SecKeychainItemRef item = NULL;
    err = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&item);
    if (err != errSecSuccess) {
        NSLog(@"Error while finding password item: %d", (int)err);
        return;
    }

    // Delete the password item
    err = SecKeychainItemDelete(item);
    CFRelease(item);

    if (err != errSecSuccess) {
        NSLog(@"Error while deleting password item: %d", (int)err);
    }
}




#pragma mark -

- (void)setSecretKey:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSString *accountName = @"wiredclient";
    NSString *serviceName = @"wiredclient";
    NSDictionary *query;
    OSStatus status;

    query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: serviceName,
        (__bridge id)kSecAttrAccount: accountName,
    };

    // Check if the item already exists
    CFTypeRef result = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess) {
        // Item exists, update the password
        NSDictionary *updateAttributes = @{
            (__bridge id)kSecValueData: data
        };
        status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateAttributes);
    } else if (status == errSecItemNotFound) {
        // Item doesn't exist, add it
        NSMutableDictionary *addQuery = [query mutableCopy];
        [addQuery setObject:data forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
    }

    if (status != errSecSuccess) {
        NSLog(@"Error while setting Secret Key: %@", [self errorMessageForStatus:status]);
    }
}

- (NSString *)errorMessageForStatus:(OSStatus)status {
    CFStringRef errorMessageString = SecCopyErrorMessageString(status, NULL);
    NSString *errorMessage = ( NSString *)errorMessageString;
    return errorMessage;
}


- (NSString *)secretKey {
    NSString *result, *accountName, *serviceName;
    NSDictionary *query;
    CFTypeRef resultData = NULL;
    OSStatus status;

    result = nil;
    accountName = @"wiredclient";
    serviceName = @"wiredclient";

    query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: serviceName,
        (__bridge id)kSecAttrAccount: accountName,
        (__bridge id)kSecReturnData: @YES
    };

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultData);

    if (status == noErr && resultData != NULL) {
        NSData *data = ( NSData *)resultData;
        result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"Error while getting Secret Key: %d", (int)status);
    }

    return result;
}




@end
