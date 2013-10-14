//
//  WCEmoticonPreferences.m
//  WiredClient
//
//  Created by Rafaël Warnault on 30/09/13.
//
//

#import "WCEmoticonPreferences.h"
#import "WCApplicationController.h"
#import "WCEmoticonPackTableCellView.h"
#import "WCPreferences.h"


@interface WCEmoticonPreferences (Private)

- (WIEmoticonPack *)_selectedPack;

@end



@implementation WCEmoticonPreferences (Private)

- (WIEmoticonPack *)_selectedPack {
    NSInteger		row;
    
    row = [_emoticonPacksTableView clickedRow];
	
    if(row < 0)
        row = [_emoticonPacksTableView selectedRow];
    
	if(row >= 0) {
		return [[[WCApplicationController sharedController] computedEmoticonPacks] objectAtIndex:row];
	}
    
    return nil;
}


@end



@implementation WCEmoticonPreferences


#pragma mark -

- (IBAction)open:(id)sender {
    [_emoticonPacksTableView reloadData];
    
    [NSApp beginSheet:self.window
       modalForWindow:[[WCPreferences preferences] window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}


- (IBAction)close:(id)sender {
    if ([[self window] isSheet]) {
        [NSApp endSheet:[self window]];
    }
    [[self window] orderOut:nil];
}


- (IBAction)enablePack:(id)sender {
    NSButton            *button;
    WIEmoticonPack      *pack;
    NSInteger           index;
    BOOL                enabled, changed;
    
    button  = (NSButton *)sender;
    pack    = (WIEmoticonPack *)[(NSTableCellView *)[button superview] objectValue];
    enabled = ([button state] == NSOnState ? YES: NO);
    changed = NO;
    
    for(WIEmoticonPack *cPack in [[WCApplicationController sharedController] computedEmoticonPacks]) {
        if([[cPack packKey] isEqualToString:[pack packKey]]) {
            [cPack setEnabled:enabled all:YES];
            
            if(enabled) {
                [[WCSettings settings] addObject:[cPack packKey] toArrayForKey:WCEnabledEmoticonPacks];
            } else {
                index = [[[WCSettings settings] objectForKey:WCEnabledEmoticonPacks] indexOfObject:[cPack packKey]];
                
                [[WCSettings settings] removeObjectAtIndex:index fromArrayForKey:WCEnabledEmoticonPacks];
            }
            
            changed = YES;
        }
    }
    
    if(changed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WCEmoticonsDidChangeNotification];
        
        [_emoticonsTableView reloadData];
        [_emoticonsTableView setEnabled:[[self _selectedPack] isEnabled]];
    }
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSInteger result = 0;
    
    if(tableView == _emoticonPacksTableView) {
        result = [[[WCApplicationController sharedController] computedEmoticonPacks] count];
    }
    else if(tableView == _emoticonsTableView) {
        result = [[[self _selectedPack] emoticons] count];
    }
    
    return result;
}


- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    WCEmoticonPackTableCellView     *cellView;
    WIEmoticonPack                  *pack;
    
    cellView = nil;
    
    if(tableView == _emoticonPacksTableView) {
        cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
        pack = [[[WCApplicationController sharedController] computedEmoticonPacks] objectAtIndex:row];
        
        cellView.textField.stringValue  = [pack name];
        cellView.enabledButton.state    = ([pack isEnabled]) ? NSOnState : NSOffState;
        cellView.emoticonImage1.image   = [[[pack emoticons] objectAtIndex:0] image];
        cellView.emoticonImage2.image   = [[[pack emoticons] objectAtIndex:1] image];
        cellView.emoticonImage3.image   = [[[pack emoticons] objectAtIndex:2] image];
        cellView.emoticonImage4.image   = [[[pack emoticons] objectAtIndex:3] image];
        cellView.emoticonImage5.image   = [[[pack emoticons] objectAtIndex:4] image];
        
        [cellView setObjectValue:pack];
    }
    
    return cellView;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    id value = nil;
    
    if(tableView == _emoticonsTableView) {
        WIEmoticon *emoticon = [[[self _selectedPack] emoticons] objectAtIndex:row];
        if([[tableColumn identifier] isEqualToString:@"enabled"]) {
            value = [NSNumber numberWithBool:[emoticon enabled]];
        }
        else if([[tableColumn identifier] isEqualToString:@"name"]) {
            value = [emoticon name];
        }
        else if([[tableColumn identifier] isEqualToString:@"image"]) {
            value = [emoticon image];
        }
        else if([[tableColumn identifier] isEqualToString:@"equivalent"]) {
            value = [[emoticon textEquivalents] objectAtIndex:0];
        }
    }
    
    return value;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if(tableView == _emoticonsTableView) {
        if([[tableColumn identifier] isEqualToString:@"enabled"]) {
            WIEmoticon *emoticon = [[[self _selectedPack] emoticons] objectAtIndex:row];
            NSDictionary *disabledEmoticons = [[WCSettings settings] objectForKey:WCDisabledEmoticons];
            NSMutableArray *disabledNames = [NSMutableArray arrayWithArray:[disabledEmoticons valueForKey:[[emoticon pack] packKey]]];
            
            [emoticon setEnabled:[object boolValue]];
            
            if([object boolValue]) {
                if(![[emoticon pack] isEnabled]) {
//                    NSMutableArray *names = [NSMutableArray array];
//                    NSArray *emoticons = [[emoticon pack] emoticons];
//                    
//                    for(WIEmoticon *emoticon in  emoticons) {
//                        [names addObject:[emoticon name]];
//                    }
//                    [[WCSettings settings] addObject:[[emoticon pack] packKey] toArrayForKey:WCEnabledEmoticonPacks];
//                    [[WCSettings settings] setObject:names forKey:[[emoticon pack] packKey] inDictionaryForKey:WCDisabledEmoticons];
//                    
//                    NSInteger index = [[[WCApplicationController sharedController] computedEmoticonPacks] indexOfObject:[emoticon pack]];
//                    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
//                    [_emoticonPacksTableView reloadDataForRowIndexes:indexSet
//                                                       columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                }
                [disabledNames removeObject:[emoticon name]];
            }
            else {
                if(![disabledNames containsObject:[emoticon name]])
                    [disabledNames addObject:[emoticon name]];
            }
                        
            [[WCSettings settings] setObject:disabledNames
                                      forKey:[[emoticon pack] packKey]
                          inDictionaryForKey:WCDisabledEmoticons];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:WCEmoticonsDidChangeNotification];
        }
    }
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if([notification object] == _emoticonPacksTableView) {
        [_emoticonsTableView reloadData];
        [_emoticonsTableView setEnabled:[[self _selectedPack] isEnabled]];
    }
}

@end
