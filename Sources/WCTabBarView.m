//
//  WCTabBarView.m
//  WiredClient
//
//  Created by Rafaël Warnault on 04/03/13.
//
//

#import "WCTabBarView.h"
#import "WCTabBarItem.h"


@implementation WCTabBarView

#pragma mark -

- (NSTabViewItem *)tabViewItemWithIdentifier:(NSString *)identifier {
    for(NSTabViewItem *item in [[self tabView] tabViewItems]) {
        if([[[item identifier] valueForKey:@"identifier"] isEqualToString:identifier])
            return item;
    }
    return nil;
}


@end
