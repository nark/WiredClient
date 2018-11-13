//
//  WCTrackerBookmarkController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 25/06/13.
//
//

#import "WCTrackerBookmarkController.h"
#import "WCServerItem.h"
#import "WCKeychain.h"
#import "WCPreferences.h"


@interface WCTrackerBookmarkController (Private)

- (void)_savePasswordForTrackerBookmark:(NSArray *)arguments;

@end



@implementation WCTrackerBookmarkController (Private)

#pragma mark -

- (void)_savePasswordForTrackerBookmark:(NSArray *)arguments {
	NSDictionary		*oldBookmark = [arguments objectAtIndex:0];
	NSDictionary		*bookmark = [arguments objectAtIndex:1];
	NSString			*password = [arguments objectAtIndex:2];
	
	if(![oldBookmark isEqual:bookmark])
		[[WCKeychain keychain] deletePasswordForTrackerBookmark:oldBookmark];
	
	if([password length] > 0)
		[[WCKeychain keychain] setPassword:password forTrackerBookmark:bookmark];
	else
		[[WCKeychain keychain] deletePasswordForTrackerBookmark:bookmark];
}

- (void)_bookmarkDidChange:(NSDictionary *)bookmark {
    [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarkDidChangeNotification object:bookmark];
    [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
}

@end




@implementation WCTrackerBookmarkController

#pragma mark -

- (void)load {    
    if(_bookmark) {
        [_bookmarksNameTextField setStringValue:[_bookmark objectForKey:WCTrackerBookmarksName]];
        [_bookmarksAddressTextField setStringValue:[_bookmark objectForKey:WCTrackerBookmarksAddress]];
        [_bookmarksLoginTextField setStringValue:[_bookmark objectForKey:WCTrackerBookmarksLogin]];
        
        [_bookmarksPassword release];
        _bookmarksPassword = [[[WCKeychain keychain] passwordForBookmark:_bookmark] copy];
        
        if([[_bookmark objectForKey:WCTrackerBookmarksAddress] length] > 0 && [_bookmarksPassword length] > 0)
            [_bookmarksPasswordTextField setStringValue:_bookmarksPassword];
        else
            [_bookmarksPasswordTextField setStringValue:@""];
        
    } else {
        [_bookmarksNameTextField setStringValue:NSLS(@"Untitled", @"Untitled tracker bookmark")];
    }
}



- (void)save {
    NSString        *password;
    NSInteger       row;
    BOOL            passwordChanged = NO;
    
    if(_bookmark) {
        // update
        password    = [_bookmarksPasswordTextField stringValue];
        row         = [[WCSettings settings] indexOfObject:_oldBookmark inArrayForKey:WCTrackerBookmarks];
        
        [_bookmark setObject:[_bookmarksNameTextField stringValue] forKey:WCTrackerBookmarksName];
        [_bookmark setObject:[_bookmarksAddressTextField stringValue] forKey:WCTrackerBookmarksAddress];
        [_bookmark setObject:[_bookmarksLoginTextField stringValue] forKey:WCTrackerBookmarksLogin];
        
        if(!_bookmarksPassword || ![_bookmarksPassword isEqualToString:password] ||
           ![[_oldBookmark objectForKey:WCTrackerBookmarksAddress] isEqualToString:[_bookmark objectForKey:WCTrackerBookmarksAddress]]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(_savePasswordForTrackerBookmark:)
                       withObject:[NSArray arrayWithObjects:_oldBookmark, _bookmark, password, NULL]
                       afterDelay:0.0];
            
            [_bookmarksPassword release];
            _bookmarksPassword = [password copy];
            
            passwordChanged = YES;
        }
        
        if(![_oldBookmark isEqualToDictionary:_bookmark] || passwordChanged) {
            [[WCSettings settings] replaceObjectAtIndex:row withObject:_bookmark inArrayForKey:WCTrackerBookmarks];
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_bookmarkDidChange:) object:_oldBookmark];
            [self performSelector:@selector(_bookmarkDidChange:) withObject:_bookmark afterDelay:0.0];
        }
    } else {
        // create
        _bookmark   = [[NSMutableDictionary alloc] init];
        
        password    = [_bookmarksPasswordTextField stringValue];
        row         = [[WCSettings settings] indexOfObject:_oldBookmark inArrayForKey:WCTrackerBookmarks];
        
        [_bookmark setObject:[NSString UUIDString] forKey:WCTrackerBookmarksIdentifier];
        [_bookmark setObject:[_bookmarksNameTextField stringValue] forKey:WCTrackerBookmarksName];
        [_bookmark setObject:[_bookmarksAddressTextField stringValue] forKey:WCTrackerBookmarksAddress];
        [_bookmark setObject:[_bookmarksLoginTextField stringValue] forKey:WCTrackerBookmarksLogin];
        
        [[WCKeychain keychain] setPassword:password forBookmark:_bookmark];
        
        [_bookmarksPassword release];
        _bookmarksPassword = [password copy];
        
        [[WCSettings settings] addObject:_bookmark toArrayForKey:WCTrackerBookmarks];
        
        [self performSelector:@selector(_bookmarkDidChange:) withObject:_bookmark afterDelay:0.0];
    }
}



@end
