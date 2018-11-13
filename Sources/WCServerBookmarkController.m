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
- (void)_reloadThemes;

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

- (void)_reloadThemes {
	NSEnumerator	*enumerator;
	NSDictionary	*theme;
	NSMenuItem		*item;
	NSInteger		index;
	
	while((index = [_bookmarksThemePopUpButton indexOfItemWithTag:0]) != -1)
		[_bookmarksThemePopUpButton removeItemAtIndex:index];
	
	enumerator = [[[WCSettings settings] objectForKey:WCThemes] objectEnumerator];
	
	while((theme = [enumerator nextObject])) {
		item = [NSMenuItem itemWithTitle:[theme objectForKey:WCThemesName]];
		[item setRepresentedObject:[theme objectForKey:WCThemesIdentifier]];
		[item setImage:[[WCPreferences preferences] imageForTheme:theme size:NSMakeSize(16.0, 12.0)]];
		
		[[_bookmarksThemePopUpButton menu] addItem:item];
	}
}


@end

@implementation WCServerBookmarkController

#pragma mark -

- (void)load {
    NSDictionary    *theme;
    NSInteger		index;
    
    [self _reloadThemes];
    
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
        
        theme = [_bookmark objectForKey:WCBookmarksTheme];
        
        if(theme && (index = [_bookmarksThemePopUpButton indexOfItemWithRepresentedObject:theme]) != -1)
            [_bookmarksThemePopUpButton selectItemAtIndex:index];
        else
            [_bookmarksThemePopUpButton selectItemAtIndex:0];
        
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
        
        if([_bookmarksThemePopUpButton representedObjectOfSelectedItem])
            [_bookmark setObject:[_bookmarksThemePopUpButton representedObjectOfSelectedItem] forKey:WCBookmarksTheme];
        else
            [_bookmark removeObjectForKey:WCBookmarksTheme];
        
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
        
        if([_bookmarksThemePopUpButton representedObjectOfSelectedItem])
            [_bookmark setObject:[_bookmarksThemePopUpButton representedObjectOfSelectedItem] forKey:WCBookmarksTheme];
        else
            [_bookmark removeObjectForKey:WCBookmarksTheme];
        
        [_bookmark setBool:[_bookmarksAutoConnectButton state] forKey:WCBookmarksAutoConnect];
        [_bookmark setBool:[_bookmarksAutoReconnectButton state] forKey:WCBookmarksAutoReconnect];
        [_bookmark setObject:[_bookmarksNickTextField stringValue] forKey:WCBookmarksNick];
        [_bookmark setObject:[_bookmarksStatusTextField stringValue] forKey:WCBookmarksStatus];
        
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
