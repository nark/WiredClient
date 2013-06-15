//
//  WCTrackerServerInfo.h
//  WiredClient
//
//  Created by Rafaël Warnault on 28/08/12.
//
//

#import "WCInfoController.h"

@class WCServerTrackerServer;

@interface WCTrackerServerInfo : WCInfoController {
	IBOutlet NSTextField			*_nameTextField;
    
	IBOutlet NSTextField			*_descriptionTitleTextField;
	IBOutlet NSTextField			*_descriptionTextField;
	IBOutlet NSTextField			*_urlTitleTextField;
	IBOutlet NSTextField			*_urlTextField;
	IBOutlet NSTextField			*_filesTitleTextField;
	IBOutlet NSTextField			*_filesTextField;
	IBOutlet NSTextField			*_sizeTitleTextField;
	IBOutlet NSTextField			*_sizeTextField;
    IBOutlet NSTextField			*_trackerTextField;
	IBOutlet NSTextField			*_trackerTitleTextField;
    
    WCServerTrackerServer           *_server;
}

+ (id)trackerServerInfoWithTrackerServer:(WCServerTrackerServer *)server;

@end
