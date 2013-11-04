//
//  WCThemesPreferences.m
//  WiredClient
//
//  Created by nark on 14/10/13.
//
//

#import "WCPreferences.h"
#import "WCThemesPreferences.h"
#import "WCApplicationController.h"
#import "WCSettings.h"


NSString * const WCThemesDidChangeNotification      = @"WCThemesDidChangeNotification";


@interface WCThemesPreferences (Private)

- (NSArray *)               _themeNames;
- (NSDictionary *)          _selectedTheme;

@end




@implementation WCThemesPreferences (Private)

- (NSDictionary *)_selectedTheme {
    NSDictionary    *theme;
    NSInteger       row;
    
    row     = [_themesTableView selectedRow];
    theme   = nil;

    if(row < 0)
        return nil;
    
    theme = [[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row];
    
    return theme;
}


- (NSArray *)_themeNames {
	NSEnumerator		*enumerator;
	NSDictionary		*theme;
	NSMutableArray		*array;
	
	array			= [NSMutableArray array];
	enumerator		= [[[WCSettings settings] objectForKey:WCThemes] objectEnumerator];
	
	while((theme = [enumerator nextObject]))
		[array addObject:[theme objectForKey:WCThemesName]];
	
	return array;
}


@end





@implementation WCThemesPreferences

#pragma mark -

@dynamic themeSelected;



#pragma mark -

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themesDidChange:)
                                                 name:WCThemesDidChangeNotification
                                               object:nil];
    
    [_themesTableView setDataSource:self];
    [_themesTableView setDelegate:self];
}


- (void)themesDidChange:(NSNotification *)notification {
    [_themesTableView reloadData];
}





#pragma mark -

- (IBAction)duplicateTheme:(id)sender {
    NSMutableDictionary		*theme;
    NSString                *copiedName;
	
	theme = [[[self _selectedTheme] mutableCopy] autorelease];
	
    if(!theme) return;
    
    copiedName = [WCApplicationController copiedNameForName:[theme objectForKey:WCThemesName]
                                              existingNames:[self _themeNames]];
    
	[theme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
	[theme removeObjectForKey:WCThemesBuiltinName];
	[theme setObject:copiedName forKey:WCThemesName];
	
	[[WCSettings settings] addObject:theme toArrayForKey:WCThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCThemesDidChangeNotification
                                                        object:theme];
}


- (IBAction)renameTheme:(id)sender {
    [_themesTableView editColumn:0
                             row:[_themesTableView selectedRow]
                       withEvent:nil
                          select:YES];
}


- (IBAction)deleteTheme:(id)sender {
    NSDictionary    *theme;
    NSString		*identifier;
    
    theme       = [self _selectedTheme];
    identifier  = [theme objectForKey:WCThemesIdentifier];
    
    // can't remove buil-tin themes
    if([theme objectForKey:WCThemesBuiltinName]) {
        NSBeep();
        return;
    }
    
    // if the removed theme is the selected, so select the first available theme
    if([[[WCSettings settings] objectForKey:WCTheme] isEqualToString:identifier]) {
        identifier = [[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:0] objectForKey:WCThemesIdentifier];
        
        [[WCSettings settings] setObject:identifier forKey:WCTheme];
        [[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification
                                                            object:nil];
    }
    
    [[WCSettings settings] removeObject:theme fromArrayForKey:WCThemes];
    [[NSNotificationCenter defaultCenter] postNotificationName:WCThemesDidChangeNotification
                                                        object:nil];
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[[WCSettings settings] objectForKey:WCThemes] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    id value;
    
    value = [[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row] objectForKey:WCThemesName];
    
    return value;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSMutableDictionary		*dictionary;
    NSString                *newName;
    
    newName     = (NSString *)object;
    
    if([newName length] > 0 && ![[self _themeNames] containsObject:newName]) {
        dictionary = [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row] mutableCopy] autorelease];
        
        [dictionary setObject:object forKey:WCThemesName];
        
        [[WCSettings settings] replaceObjectAtIndex:row withObject:dictionary inArrayForKey:WCThemes];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCThemesDidChangeNotification
                                                            object:nil];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self willChangeValueForKey:@"themeSelected"];
    [self didChangeValueForKey:@"themeSelected"];
}




#pragma mark -

- (BOOL)themeSelected {
    return ([self _selectedTheme] != nil);
}

@end
