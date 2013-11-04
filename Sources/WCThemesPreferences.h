//
//  WCThemesPreferences.h
//  WiredClient
//
//  Created by nark on 14/10/13.
//
//

#import <WiredFoundation/WiredFoundation.h>
#import "WCPreferencesController.h"


extern NSString * const     WCThemesDidChangeNotification;


@interface WCThemesPreferences : WCPreferencesController <NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet NSTableView    *_themesTableView;
}

@property (readonly) BOOL themeSelected;

- (IBAction)duplicateTheme:(id)sender;
- (IBAction)renameTheme:(id)sender;
- (IBAction)deleteTheme:(id)sender;

@end
