//
//  WCServerBookmarkController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 25/06/13.
//
//

#import "WCServerBookmarkController.h"
#import "WCServerItem.h"
#import "WCKeychain.h"
#import "WCPreferences.h"


@interface WCServerBookmarkController (Private)

- (void)_savePasswordForBookmark:(NSArray *)arguments;
- (void)_reloadCiphers;

@end



@implementation WCServerBookmarkController (Private)

#pragma mark -

- (void)_savePasswordForBookmark:(NSArray *)arguments {
	NSDictionary		*oldBookmark    = [arguments objectAtIndex:0];
	NSDictionary		*bookmark       = [arguments objectAtIndex:1];
	NSString			*password       = [arguments objectAtIndex:2];
    
	if(![oldBookmark isEqual:bookmark])
		[[WCKeychain keychain] deletePasswordForBookmark:oldBookmark];
	
	if([_bookmarksPassword length] > 0)
		[[WCKeychain keychain] setPassword:password forBookmark:bookmark];
	else
		[[WCKeychain keychain] deletePasswordForBookmark:bookmark];
}

#pragma mark -

- (void)_reloadCiphers {
	NSMenuItem		*item;
    NSDictionary    *schemes;
    NSArray         *schemeKeys;
    NSString        *cipherName, *menuName;
    BOOL            deprecated;
    NSUInteger      options = 0;
    [[_bookmarksCipherPopUpButton menu] removeAllItems];
        
    schemes     = [WCP7Spec encryptionSchemes];
    schemeKeys  = [[schemes allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
    for(NSNumber *key in schemeKeys) {
        options = 1 << ([key unsignedLongLongValue] + 1);
        
        cipherName  = [WCP7Spec nameForEncryptionSchemeID:[key stringValue]];
        deprecated  = WI_P7_DEPRECATED_ENCRYPTION_CIPHER(options);
        menuName    = [NSSWF:@"%@%@", cipherName, (deprecated ? @" (deprecated)": @"")];
        item        = [NSMenuItem itemWithTitle:menuName tag:[key intValue]];
        
        [[_bookmarksCipherPopUpButton menu] addItem:item];
    }
}


@end

@implementation WCServerBookmarkController

#pragma mark -

- (void)load {
    NSNumber        *encryptionCipher;
    
    [self _reloadCiphers];
    
    if(_bookmark) {
        [_bookmarksNameTextField setStringValue:[_bookmark objectForKey:WCBookmarksName]];
        [_bookmarksAddressTextField setStringValue:[_bookmark objectForKey:WCBookmarksAddress]];
        [_bookmarksLoginTextField setStringValue:[_bookmark objectForKey:WCBookmarksLogin]];
        
        [_bookmarksPassword release];
        _bookmarksPassword = [[[WCKeychain keychain] passwordForBookmark:_bookmark] copy];
        
        if([[_bookmark objectForKey:WCBookmarksAddress] length] > 0 && [_bookmarksPassword length] > 0)
            [_bookmarksPasswordTextField setStringValue:_bookmarksPassword];
        else
            [_bookmarksPasswordTextField setStringValue:@""];
        
        encryptionCipher = [_bookmark objectForKey:WCBookmarksEncryptionCipher];
        
        if (encryptionCipher)
            [_bookmarksCipherPopUpButton selectItemWithTag:[encryptionCipher intValue]];
        else
            [_bookmarksCipherPopUpButton selectItemWithTag:[[WCSettings settings] intForKey:WCNetworkEncryptionCipher]];
        
        [_bookmarksAutoConnectButton setState:[_bookmark boolForKey:WCBookmarksAutoConnect]];
        [_bookmarksAutoReconnectButton setState:[_bookmark boolForKey:WCBookmarksAutoReconnect]];
        [_bookmarksNickTextField setStringValue:[_bookmark objectForKey:WCBookmarksNick]];
        [_bookmarksStatusTextField setStringValue:[_bookmark objectForKey:WCBookmarksStatus]];
    
    } else {
        [_bookmarksNameTextField setStringValue:NSLS(@"Untitled", @"Untitled bookmark")];
    }
}

- (void)_bookmarkDidChange:(NSDictionary *)bookmark {
    [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarkDidChangeNotification object:bookmark];
    [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
}

- (void)save {
    NSString        *password;
    NSInteger       row;
    BOOL            nickChanged = NO, passwordChanged = NO;
    
    if(_bookmark) {
        // update
        password    = [_bookmarksPasswordTextField stringValue];
        row         = [[WCSettings settings] indexOfObject:_oldBookmark inArrayForKey:WCBookmarks];
        
        [_bookmark setObject:[_bookmarksNameTextField stringValue] forKey:WCBookmarksName];
        [_bookmark setObject:[_bookmarksAddressTextField stringValue] forKey:WCBookmarksAddress];
        [_bookmark setObject:[_bookmarksLoginTextField stringValue] forKey:WCBookmarksLogin];
        
        [_bookmark setBool:[_bookmarksAutoConnectButton state] forKey:WCBookmarksAutoConnect];
        [_bookmark setBool:[_bookmarksAutoReconnectButton state] forKey:WCBookmarksAutoReconnect];
        [_bookmark setObject:[_bookmarksNickTextField stringValue] forKey:WCBookmarksNick];
        [_bookmark setObject:[_bookmarksStatusTextField stringValue] forKey:WCBookmarksStatus];
        
        nickChanged = ([_bookmarksLoginTextField stringValue] != [_oldBookmark objectForKey:WCBookmarksLogin]);
        
        if(nickChanged || !_bookmarksPassword || ![_bookmarksPassword isEqualToString:password] ||
           ![[_oldBookmark objectForKey:WCBookmarksAddress] isEqualToString:[_bookmark objectForKey:WCBookmarksAddress]]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            [self performSelector:@selector(_savePasswordForBookmark:)
                       withObject:[NSArray arrayWithObjects:_oldBookmark, _bookmark, password, NULL]
                       afterDelay:0.0];
            
            [_bookmarksPassword release];
            _bookmarksPassword = [password copy];
            
            passwordChanged = YES;
        }
        
        if(([_bookmarksCipherPopUpButton selectedTag] != [[WCSettings settings] intForKey:WCNetworkEncryptionCipher]) ||
           ([_bookmark integerForKey:WCBookmarksEncryptionCipher] != [_bookmarksCipherPopUpButton selectedTag]))
            [_bookmark setObject:[NSNumber numberWithInt:[_bookmarksCipherPopUpButton selectedTag]] forKey:WCBookmarksEncryptionCipher];
        
        if(![_oldBookmark isEqualToDictionary:_bookmark] || passwordChanged) {
            [[WCSettings settings] replaceObjectAtIndex:row withObject:_bookmark inArrayForKey:WCBookmarks];
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_bookmarkDidChange:) object:_oldBookmark];
            [self performSelector:@selector(_bookmarkDidChange:) withObject:_bookmark afterDelay:0.0];
        }
    } else {
        // create
        _bookmark   = [[NSMutableDictionary alloc] init];
        
        password    = [_bookmarksPasswordTextField stringValue];
        row         = [[WCSettings settings] indexOfObject:_oldBookmark inArrayForKey:WCBookmarks];
        
        [_bookmark setObject:[NSString UUIDString] forKey:WCBookmarksIdentifier];
        [_bookmark setObject:[_bookmarksNameTextField stringValue] forKey:WCBookmarksName];
        [_bookmark setObject:[_bookmarksAddressTextField stringValue] forKey:WCBookmarksAddress];
        [_bookmark setObject:[_bookmarksLoginTextField stringValue] forKey:WCBookmarksLogin];
        
        [_bookmark setBool:[_bookmarksAutoConnectButton state] forKey:WCBookmarksAutoConnect];
        [_bookmark setBool:[_bookmarksAutoReconnectButton state] forKey:WCBookmarksAutoReconnect];
        [_bookmark setObject:[_bookmarksNickTextField stringValue] forKey:WCBookmarksNick];
        [_bookmark setObject:[_bookmarksStatusTextField stringValue] forKey:WCBookmarksStatus];
        
        if([[WCSettings settings] intForKey:WCNetworkEncryptionCipher] != [_bookmarksCipherPopUpButton selectedTag])
            [_bookmark setObject:[NSNumber numberWithInt:[_bookmarksCipherPopUpButton selectedTag]] forKey:WCBookmarksEncryptionCipher];
        
        [[WCKeychain keychain] setPassword:password forBookmark:_bookmark];
        
        [_bookmarksPassword release];
        _bookmarksPassword = [password copy];
        
        [[WCSettings settings] addObject:_bookmark toArrayForKey:WCBookmarks];
        [self performSelector:@selector(_bookmarkDidChange:) withObject:_bookmark afterDelay:0.0];
    }
}


- (void)reset {
    [_bookmarksAutoConnectButton setState:NO];
    [_bookmarksAutoReconnectButton setState:NO];
    [_bookmarksNickTextField setStringValue:@""];
    [_bookmarksStatusTextField setStringValue:@""];
    
    [super reset];
}


@end
