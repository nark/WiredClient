//
//  WCTabBarItem.m
//  WiredClient
//
//  Created by Rafaël Warnault on 07/03/13.
//
//

#import "WCTabBarItem.h"

@implementation WCTabBarItem

#pragma mark -

@synthesize title               = _title;
@synthesize largeImage          = _largeImage;
@synthesize icon                = _icon;
@synthesize iconName            = _iconName;
@synthesize identifier          = _identifier;

@synthesize isProcessing        = _isProcessing;
@synthesize objectCount         = _objectCount;
@synthesize objectCountColor    = _objectCountColor;
@synthesize isEdited            = _isEdited;
@synthesize hasCloseButton      = _hasCloseButton;



#pragma mark -

- (id)init {
	if (self = [super init]) {
		_isProcessing       = NO;
		_icon               = nil;
		_iconName           = nil;
        _largeImage         = nil;
        _identifier         = nil;
		_objectCount        = 0;
		_isEdited           = NO;
        _hasCloseButton     = YES;
        _title              = [@"Untitled" retain];
        _objectCountColor   = nil;
	}
	return self;
}

- (void)dealloc {
    [_title release];               _title = nil;
    [_icon release];                _icon = nil;
    [_iconName release];            _iconName = nil;
    [_largeImage release];          _largeImage = nil;
    [_identifier release];          _identifier = nil;
    [_objectCountColor release];    _objectCountColor = nil;
    
    [super dealloc];
}

@end
