//
//  WCBookmarkController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 26/06/13.
//
//

#import "WCBookmarkController.h"
#import "WCPreferences.h"


@interface WCBookmarkController (Private)

- (BOOL)_validate;
- (void)_bookmarkDidChange:(NSDictionary *)bookmark;

@end



@implementation WCBookmarkController (Private)

- (BOOL)_validate {
    return ([[_bookmarksAddressTextField stringValue] length] > 0);
}

- (void)_bookmarkDidChange:(NSDictionary *)bookmark {
	[[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarkDidChangeNotification object:bookmark];
	[[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
}

@end





@implementation WCBookmarkController


#pragma mark -

@synthesize bookmark = _bookmark;




#pragma mark -

- (void)dealloc
{
    [_bookmark release];
    [_oldBookmark release];
    [_bookmarksPassword release];
    
    [super dealloc];
}




#pragma mark -

- (void)setBookmark:(NSMutableDictionary *)bookmark {
    if(_bookmark)
        [_bookmark release]; _bookmark = nil;
    
    if(_oldBookmark)
        [_oldBookmark release]; _oldBookmark = nil;
    
    _bookmark       = [bookmark retain];
    _oldBookmark    = [bookmark copy];
}



#pragma mark -

- (void)reset {
    [_bookmarksNameTextField setStringValue:@""];
    [_bookmarksAddressTextField setStringValue:@""];
    [_bookmarksLoginTextField setStringValue:@""];
    [_bookmarksPasswordTextField setStringValue:@""];
    
    [self setBookmark:nil];
    [_bookmarksNameTextField becomeFirstResponder];
}



#pragma mark -

- (IBAction)ok:(id)sender {
    if([self _validate]) {
        [[WCSettings settings] synchronize];
        [super ok:sender];
    } else {
        NSBeep();
    }
}

- (IBAction)cancel:(id)sender {
    [super cancel:sender];
}



@end
