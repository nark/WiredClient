//
//  WCTrackerServerInfo.m
//  WiredClient
//
//  Created by Rafaël Warnault on 28/08/12.
//
//

#import "WCTrackerServerInfo.h"
#import "WCServerItem.h"



@interface WCTrackerServerInfo (Private)

- (id)_initTrackerServerInfoWithTrackerServer:(WCServerTrackerServer *)server;

- (void)_showServerInfo;

@end



@implementation WCTrackerServerInfo (Private)

- (id)_initTrackerServerInfoWithTrackerServer:(WCServerTrackerServer *)server {
	self = [super initWithWindowNibName:@"TrackerServerInfo"];
    
	_server = [server retain];
    
	[self window];
    
	return self;
}


- (void)_showServerInfo {
    WISizeFormatter     *sizeFormatter;
    WIURL               *url;
        
	url                 = [[[_server URL] copy] autorelease];
	sizeFormatter       = [[WISizeFormatter alloc] init];
    
    [url setUser:NULL];
	[url setPassword:NULL];
    
    [_nameTextField setStringValue:[_server name]];
    [_descriptionTextField setStringValue:[_server serverDescription]];
    [_urlTextField setStringValue:[url humanReadableString]];
    [_sizeTextField setStringValue:[sizeFormatter stringFromSize:[_server filesSize]]];
    [_filesTextField setIntValue:[_server filesCount]];
    [_trackerTextField setStringValue:[NSSWF:@"%@", ([_server isTracker] ? @"YES" : @"NO")]];
    
//    [self setYOffset:18.0];
//	
//	[self resizeTitleTextField:_trackerTitleTextField withTextField:_trackerTextField];
//	[self resizeTitleTextField:_sizeTitleTextField withTextField:_sizeTextField];
//	[self resizeTitleTextField:_filesTitleTextField withTextField:_filesTextField];
//	[self resizeTitleTextField:_urlTitleTextField withTextField:_urlTextField];
//	[self resizeTitleTextField:_descriptionTitleTextField withTextField:_descriptionTextField];
    
    [sizeFormatter release];
    
    if(![[self window] isOnScreen])
		[self showWindow:self];
}


@end




@implementation WCTrackerServerInfo

+ (id)trackerServerInfoWithTrackerServer:(WCServerTrackerServer *)server {
    return [[self alloc] _initTrackerServerInfoWithTrackerServer:server];
}



- (void)dealloc
{
    [_server release];
    [super dealloc];
}




- (void)windowDidLoad {
	
	[[self window] setTitle:[NSSWF: NSLS(@"%@ Info", @"Server info window title (server)"), [_server name]]];
	
	[self setShouldCascadeWindows:YES];
	[self setShouldSaveWindowFrameOriginOnly:YES];
	[self setWindowFrameAutosaveName:@"TrackerServerInfo"];
	
    [self _showServerInfo];
    
	[super windowDidLoad];
}


@end
