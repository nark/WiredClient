//
//  WCThreadWindow.m
//  WiredClient
//
//  Created by nark on 21/10/13.
//
//

#import "WCThreadWindow.h"
#import "WCServerConnectionObject.h"
#import "WCBoardThreadController.h"
#import "WCBoardThread.h"
#import "WCBoards.h"
#import "WCBoard.h"


static NSMutableArray *_WCThreadWindowControllers;


@interface WCThreadWindow (Private)

- (void)_retainWindowController:(WCThreadWindow *)controller;
- (void)_releaseWindowController:(WCThreadWindow *)controller;

@end



@implementation WCThreadWindow (Private)

- (void)_retainWindowController:(WCThreadWindow *)controller {
    [_WCThreadWindowControllers addObject:controller];
}


- (void)_releaseWindowController:(WCThreadWindow *)controller {
    [_WCThreadWindowControllers removeObject:controller];
}

@end



@implementation WCThreadWindow

+ (void)initialize {
    _WCThreadWindowControllers = [[NSMutableArray alloc] init];
}


#pragma mark -

+ (WCThreadWindow *)threadWindowWithThread:(WCBoardThread *)thread board:(WCBoard *)board {
    return [[[[self class] alloc] initWithThread:thread board:board] autorelease];
}


+ (NSArray *)threadWindows {
    return _WCThreadWindowControllers;
}



#pragma mark -

- (id)initWithThread:(WCBoardThread *)thread board:(WCBoard *)board;
{
    self = [super initWithWindowNibName:@"ThreadWindow"];
    if (self) {
        _thread             = [thread retain];
        _board              = [board retain];
        _threadController   = [[WCBoardThreadController alloc] init];
    }
    return self;
}



- (void)dealloc
{
    [_threadController release];
    [_thread release];
    [_board release];
    
    [super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
    NSDictionary		*theme;
	NSString			*templatePath, *title;
	NSBundle			*templateBundle;
	
	theme				= [[_board connection] theme];
	templateBundle		= [[WCSettings settings] templateBundleWithIdentifier:[theme objectForKey:WCThemesTemplate]];
	templatePath		= [templateBundle bundlePath];
    
    [_threadController setBoard:_board];
    [_threadController setThread:_thread];
    [_threadController setTemplatePath:templatePath];
    
    [_threadController reloadData];
    
    title = [NSSWF:@"%@ - %@ - %@", [[_board connection] name], [_board path], [_thread subject]];
    
    [self setShouldCascadeWindows:YES];
    [[self window] setContentView:[_threadController view]];
    [[self window] setTitle:title];
    
    [self _retainWindowController:self];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self _releaseWindowController:self];
}




#pragma mark -

- (WCBoardThread *)thread {
    return _thread;
}


- (WCBoardThreadController *)threadController {
    return _threadController;
}



@end
