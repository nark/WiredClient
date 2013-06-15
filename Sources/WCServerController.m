//
//  WCServerConnectionController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 23/02/13.
//
//

#import "WCServerController.h"
#import "WCPublicChatController.h"
#import "WCBoardsViewController.h"
#import "WCMainWindowController.h"




#pragma mark -

@interface WCServerController (Private)

- (id)_initServerControllerWithConnection:(WCServerConnection *)connection;

@end


@implementation WCServerController (Private)

- (id)_initServerControllerWithConnection:(WCServerConnection *)connection {
    self = [super init];
    if (self) {
        [self setConnection:connection];
    }
    return self;
}

@end







@implementation WCServerController

#pragma mark - 

+ (id)serverControllerWithConnection:(WCServerConnection *)connection {
    return [[[self alloc] _initServerControllerWithConnection:connection] autorelease];
}



#pragma mark -

- (void)dealloc
{
    [_chatController release];
    [_boardsController release];
    
    [super dealloc];
}



#pragma mark -

- (NSView *)viewForIdentifier:(NSString *)identifier {
    NSView *view;
            
    if([identifier isEqualToString:@"Chat"]) {
        view = [_chatController view];
        
    } else if([identifier isEqualToString:@"Boards"]) {
        view = [_boardsController view];
        
    } else if([identifier isEqualToString:@"Messages"]) {
        view = nil;
        
    } else if([identifier isEqualToString:@"Files"]) {
        view = nil;
        
    } else {
        view = nil;
        
    }
    return view;
}






#pragma mark -

- (void)setConnection:(WCServerConnection *)connection {
	[connection retain];
	[_connection release];
	
	_connection = connection;
    
    [_connection addObserver:self
					selector:@selector(linkConnectionDidConnect:)
						name:WCLinkConnectionDidConnectNotification];
	
	[_connection addObserver:self
					selector:@selector(linkConnectionLoggedIn:)
						name:WCLinkConnectionLoggedInNotification];
    
	[_connection addObserver:self
					selector:@selector(serverConnectionThemeDidChange:)
						name:WCServerConnectionThemeDidChangeNotification];
}



- (WCServerConnection *)connection {
	return _connection;
}



- (WCPublicChatController *)chatController {
    return _chatController;
}


- (WCBoardsViewController *)boardsController {
    return _boardsController;
}




#pragma mark -

- (void)linkConnectionDidConnect:(NSNotification *)notification {
    if(!_chatController) {
        _chatController	= [[WCPublicChatController publicChatControllerWithConnection:[self connection]] retain];
    }
    
    if(!_boardsController) {
        _boardsController = [[WCBoardsViewController boardsControllerWithConnection:[self connection]] retain];
    }
}


- (void)linkConnectionLoggedIn:(NSNotification *)notification {
    [[WCMainWindowController mainWindow] addServerController:self];
    [[WCMainWindowController mainWindow] selectServerController:self];
    [[WCMainWindowController mainWindow] showWindow:self];
}


- (void)serverConnectionThemeDidChange:(NSNotification *)notification {
    
}



@end
