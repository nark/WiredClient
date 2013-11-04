//
//  WCEmoticonPreferences.h
//  WiredClient
//
//  Created by Rafaël Warnault on 30/09/13.
//
//

#import <WiredFoundation/WiredFoundation.h>
#import "WCPreferencesController.h"

@interface WCEmoticonPreferences : WCPreferencesController <NSTableViewDelegate, NSTableViewDataSource> {
    IBOutlet NSTableView            *_emoticonPacksTableView;
    IBOutlet NSTableView            *_emoticonsTableView;
    
    NSMutableArray                  *_availableEmoticonPacks;
    NSMutableArray                  *_enabledEmoticonPacks;
    NSMutableArray                  *_emoticons;
    NSMutableArray                  *_emoticonEquivalents;
    
    NSIndexSet                      *_dragRows;
}

- (NSArray *)availableEmoticonPacks;
- (NSArray *)enabledEmoticonPacks;
- (NSArray *)computedEmoticonPacks;
- (NSArray *)enabledEmoticons;
- (NSArray *)emoticonEquivalents;

- (WIEmoticon *)emoticonForEquivalent:(NSString *)equivalent;

- (void)reloadEmoticons;

- (IBAction)enablePack:(id)sender;

@end
