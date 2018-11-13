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

- (WIEmoticonPack *)        _packAtIndex:(NSInteger)index;
- (WIEmoticonPack *)        _selectedPack;

- (NSArray *)               _emoticonPacksPaths;
- (void)                    _reloadEmoticons;

- (void)                    _saveEmoticonPackOrdering;
- (void)                    _sortArrayOfEmoticonPacks:(NSMutableArray *)packArray;
- (void)                    _moveEmoticonPacks:(NSArray *)packs toIndex:(NSUInteger)idx;

@end

NSInteger packSortFunction(id packA, id packB, void *packOrderingArray);

@implementation WCEmoticonPreferences (Private)

- (WIEmoticonPack *)_packAtIndex:(NSInteger)index {
    if(index >= 0) {
		return [[self computedEmoticonPacks] objectAtIndex:index];
	}
    return nil;
}


- (WIEmoticonPack *)_selectedPack {
    NSInteger row;
    
    row = [_emoticonPacksTableView clickedRow];
	
    if(row < 0)
        row = [_emoticonPacksTableView selectedRow];
    
	if(row >= 0) {
		return [[self computedEmoticonPacks] objectAtIndex:row];
	}
    
    return nil;
}



- (NSArray *)_emoticonPacksPaths {
    NSArray             *bundleTypes, *bundleLocations, *fileNames;
    NSMutableArray      *bundlePaths;
    NSError             *error;
    
    bundlePaths     = [NSMutableArray array];
    bundleTypes     = [NSArray arrayWithObjects:@"WiredEmoticons", @"AdiumEmoticonset", nil];
    bundleLocations = [NSArray arrayWithObjects:
                       [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Emoticons"],
                       [[[[WCApplicationController sharedController] applicationFilesDirectory] path] stringByAppendingPathComponent:@"Emoticons"],
                       nil];
    
    for(NSString *path in bundleLocations) {
        fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
        
        for(NSString *fileName in fileNames) {
            if([bundleTypes containsObject:[fileName pathExtension]])
                [bundlePaths addObject:[path stringByAppendingPathComponent:fileName]];
        }
    }
    
    return bundlePaths;
}


- (void)_reloadEmoticons {
    NSArray             *bundlePaths, *enabledKeys;
    NSDictionary        *disabledEmoticons;
    NSArray             *disabledNames;
    
    // Clean every cached local objects
    [_availableEmoticonPacks removeAllObjects];
    [_enabledEmoticonPacks removeAllObjects];
    [_emoticonEquivalents removeAllObjects];
    [_emoticons removeAllObjects];
    
    // Get paths of every Emoticon Packs
    bundlePaths = [self _emoticonPacksPaths];
    
    // Init EmoticonPack objects and cache them locally
    for(NSString *path in bundlePaths) {
        [_availableEmoticonPacks addObject:[WIEmoticonPack emoticonPackFromPath:path]];
    }
    
    // Sort Emoticon Packs with packSortFunction
    [self _sortArrayOfEmoticonPacks:_availableEmoticonPacks];
    
    // Load enabled Emoticon Packs
    enabledKeys = [[WCSettings settings] objectForKey:WCEnabledEmoticonPacks];
    for(WIEmoticonPack *pack in _availableEmoticonPacks) {
        if([enabledKeys containsObject:[pack packKey]]) // No duplicate
            [_enabledEmoticonPacks addObject:pack];
    }
    
    // Load disabled Emoticons
    disabledEmoticons   = [[WCSettings settings] objectForKey:WCDisabledEmoticons];
    for(WIEmoticonPack *pack in _availableEmoticonPacks) {
        disabledNames = [disabledEmoticons objectForKey:[pack packKey]];
        // Propagate disabled emoticons in packs
        if([enabledKeys containsObject:[pack packKey]]) {
            [pack setEnabled:YES];
            [pack setDisabledEmoticons:disabledNames];
        } else {
            [pack setEnabled:NO];
        }
    }
    
    // Build cahed arrays
    for(WIEmoticonPack *pack in _enabledEmoticonPacks) {
        for(WIEmoticon *emoticon in pack.enabledEmoticons) {
            [_emoticons addObject:emoticon];
            [_emoticonEquivalents addObjectsFromArray:emoticon.textEquivalents];
        }
    }
}



- (void)_moveEmoticonPacks:(NSArray *)packs toIndex:(NSUInteger)idx {
    //Remove each pack
    for (WIEmoticonPack *pack in packs) {
        if ([_availableEmoticonPacks indexOfObject:pack] < idx) idx--;
        [_availableEmoticonPacks removeObject:pack];
    }
	
    //Add back the packs in their new location
    for (WIEmoticonPack *pack in packs) {
        [_availableEmoticonPacks insertObject:pack atIndex:idx];
        idx++;
    }
    
    //Save our new ordering
    [self _saveEmoticonPackOrdering];
}


- (void)_saveEmoticonPackOrdering
{
    NSMutableArray      *nameArray;
    nameArray           = [NSMutableArray array];
    
    // Perepare an ordered array of pack keys
    for (WIEmoticonPack *pack in _availableEmoticonPacks) {
        [nameArray addObject:pack.packKey];
    }
    
    // Save ordered pack keys
    [[WCSettings settings] setObject:nameArray forKey:WCEmoticonPacksOrdering];
    
    // Launch notification to reload other controls (prefs, popover view)
    [[NSNotificationCenter defaultCenter] postNotificationName:WCEmoticonsDidChangeNotification];
}


- (void)_sortArrayOfEmoticonPacks:(NSMutableArray *)packs {
	// Load the saved ordering and sort the active array based on it
	NSArray *packOrderingArray = [[WCSettings settings] objectForKey:WCEmoticonPacksOrdering];
    
	// It's most likely quicker to create an empty array here than to do nil checks each time through the sort function
	if (!packOrderingArray) packOrderingArray = [NSArray array];
    
	[packs sortUsingFunction:packSortFunction context:(__bridge void *)packOrderingArray];
}


NSInteger packSortFunction(id packA, id packB, void *packOrderingArray) {
	NSInteger packAIndex = [(__bridge NSArray *)packOrderingArray indexOfObject:[packA packKey]];
	NSInteger packBIndex = [(__bridge NSArray *)packOrderingArray indexOfObject:[packB packKey]];
	
	BOOL notFoundA = (packAIndex == NSNotFound);
	BOOL notFoundB = (packBIndex == NSNotFound);
	
	// Packs which aren't in the ordering index sort to the bottom
	if (notFoundA && notFoundB) {
		return ([[packA packKey] compare:[packB packKey]]);
		
	} else if (notFoundA) {
		return (NSOrderedDescending);
		
	} else if (notFoundB) {
		return (NSOrderedAscending);
		
	} else if (packAIndex > packBIndex) {
		return NSOrderedDescending;
		
	} else {
		return NSOrderedAscending;
		
	}
}

@end





@implementation WCEmoticonPreferences

#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {
        _availableEmoticonPacks     = [[NSMutableArray alloc] init];
        _enabledEmoticonPacks       = [[NSMutableArray alloc] init];
        _emoticonEquivalents        = [[NSMutableArray alloc] init];
        _emoticons                  = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter]
             addObserver:self
                selector:@selector(emoticonsDidChange:)
                    name:WCEmoticonsDidChangeNotification];
    }
    return self;
}


- (void)dealloc
{
    [_availableEmoticonPacks    release];
    [_enabledEmoticonPacks      release];
    [_emoticonEquivalents       release];
    [_emoticons                 release];
    [_dragRows                  release];
    
    [super dealloc];
}

#pragma mark -

- (void)awakeFromNib {
    [_emoticonPacksTableView registerForDraggedTypes:[NSArray arrayWithObject:WIEmoticonPackPBoardType]];
    
    [self _reloadEmoticons];
}





#pragma mark -

- (IBAction)open:(id)sender {
    [_emoticonPacksTableView reloadData];
    [super open:sender];
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
    
    for(WIEmoticonPack *cPack in [self computedEmoticonPacks]) {
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
        [self _reloadEmoticons];
        [_emoticonsTableView reloadData];
        [_emoticonsTableView setEnabled:[[self _selectedPack] isEnabled]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCEmoticonsDidChangeNotification];
    }
}




#pragma mark -

- (NSArray *)availableEmoticonPacks {
    return _availableEmoticonPacks;
}


- (NSArray *)enabledEmoticonPacks {
    return _enabledEmoticonPacks;
}


- (NSArray *)computedEmoticonPacks {
    return _availableEmoticonPacks;
}


- (NSArray *)enabledEmoticons {
    return _emoticons;
}


- (NSArray *)emoticonEquivalents {
    return _emoticonEquivalents;
}

- (WIEmoticon *)emoticonForEquivalent:(NSString *)equivalent {
    __block WIEmoticonPack      *pack;
    __block WIEmoticon          *emoticon, *result;
    
    emoticon    = nil;
    
    [[_enabledEmoticonPacks reversedArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        pack = (WIEmoticonPack *)obj;
        
        [pack.enabledEmoticons enumerateObjectsUsingBlock:^(id subobj, NSUInteger subidx, BOOL *substop) {
            emoticon = (WIEmoticon *)subobj;
            
            [emoticon.textEquivalents enumerateObjectsUsingBlock:^(id subsubobj, NSUInteger subsubidx, BOOL *subsubstop) {
                if([subsubobj isEqualToString:equivalent]) {
                    result = emoticon;
                    return;
                }
            }];
            
            if(result) {
                substop = (BOOL*)YES;
                return;
            }
        }];
        
        if(result) {
            stop = (BOOL*)YES;
            return;
        }
    }];
    
    return result;
}



- (void)reloadEmoticons {
    [self _reloadEmoticons];
}



#pragma mark -

- (void)emoticonsDidChange:(NSNotification *)notification {

}




#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSInteger result = 0;
    
    if(tableView == _emoticonPacksTableView) {
        result = [[self computedEmoticonPacks] count];
    }
    else if(tableView == _emoticonsTableView && [self _selectedPack]) {
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
    
        pack = [[self computedEmoticonPacks] objectAtIndex:row];
        
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
                [disabledNames removeObject:[emoticon name]];
            }
            else {
                if(![disabledNames containsObject:[emoticon name]])
                    [disabledNames addObject:[emoticon name]];
            }
                        
            [[WCSettings settings] setObject:disabledNames
                                      forKey:[[emoticon pack] packKey]
                          inDictionaryForKey:WCDisabledEmoticons];
            
            [self _reloadEmoticons];
            
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



#pragma mark Drag and Drop

- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    if (tableView != _emoticonPacksTableView)
        return nil;
    
    // Release previous rows if needed
    if(_dragRows) [_dragRows release]; _dragRows = nil;
    
    // Retain given row
    _dragRows = [[NSIndexSet indexSetWithIndex:row] retain];
    
    return [self _packAtIndex:row];
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    // Check
	if (tableView == _emoticonPacksTableView && op == NSTableViewDropAbove && row != -1)
		return NSDragOperationMove;
	   
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard        *pasteboard;
    NSMutableArray      *movedPacks;
	NSString            *availableType;
    NSArray             *types;
    
    if (tableView != _emoticonPacksTableView)
		return NO;
    
    pasteboard  = [info draggingPasteboard];
	types       = [NSArray arrayWithObject:WIEmoticonPackPBoardType];
    
    // Check
	availableType = [pasteboard availableTypeFromArray:types];
	if (![availableType isEqualToString:WIEmoticonPackPBoardType])
		return NO;
    
	// Move
	movedPacks = [NSMutableArray array]; //Keep track of the packs we've moved
    
	[_dragRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[movedPacks addObject:[[self computedEmoticonPacks] objectAtIndex:idx]];
	}];

    [self _moveEmoticonPacks:movedPacks toIndex:row];
    
    // Reload
    [self _reloadEmoticons];
    
    [_emoticonPacksTableView reloadData];
    [_emoticonsTableView reloadData];
    
	return YES;
}


@end
