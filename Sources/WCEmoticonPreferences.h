//
//  WCEmoticonPreferences.h
//  WiredClient
//
//  Created by Rafaël Warnault on 30/09/13.
//
//

#import <WiredFoundation/WiredFoundation.h>

@interface WCEmoticonPreferences : WIWindowController <NSTableViewDelegate, NSTableViewDataSource> {
    IBOutlet NSTableView            *_emoticonPacksTableView;
    IBOutlet NSTableView            *_emoticonsTableView;
}

- (IBAction)open:(id)sender;
- (IBAction)close:(id)sender;

- (IBAction)enablePack:(id)sender;

@end
