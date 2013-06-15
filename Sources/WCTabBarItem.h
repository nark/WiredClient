//
//  WCTabBarItem.h
//  WiredClient
//
//  Created by Rafaël Warnault on 07/03/13.
//
//

#import <Foundation/Foundation.h>
#import <MMTabBarView/MMTabBarItem.h>

@interface WCTabBarItem : NSObject <MMTabBarItem> {
    NSString    *_title;
	BOOL        _isProcessing;
	NSImage     *_icon;
    NSImage     *_largeImage;
	NSString    *_iconName;
    NSString    *_identifier;
	NSInteger   _objectCount;
    NSColor     *_objectCountColor;
	BOOL        _isEdited;
    BOOL        _hasCloseButton;
}

@property (copy)   NSString *title;
@property (retain) NSImage  *largeImage;
@property (retain) NSImage  *icon;
@property (retain) NSString *iconName;
@property (retain) NSString *identifier;

@property (assign) BOOL      isProcessing;
@property (assign) NSInteger objectCount;
@property (retain) NSColor   *objectCountColor;
@property (assign) BOOL      isEdited;
@property (assign) BOOL      hasCloseButton;

// designated initializer
- (id)init;

@end
