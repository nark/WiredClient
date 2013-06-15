//
//  WCApplicationMenuController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 04/09/12.
//
//

#import "WCApplicationMenuController.h"

@implementation WCApplicationMenuController



#pragma mark -

static WCApplicationMenuController *_menuController = nil;



+ (id)menuController {
    if(!_menuController)
        _menuController = [[self alloc] init];
    
    return _menuController;
}





#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (void)dealloc
{
    
    [super dealloc];
}

@end
