//
//  WCChatHistory.m
//  WiredClient
//
//  Created by Rafaël Warnault on 20/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCChatHistory.h"
#import "WCApplicationController.h"
#import "WCPublicChat.h"



@interface WCChatHistory (Private)

- (void)_expandAllGroups;
- (void)_reloadWebView;

- (void)chatHistoryBundleAddedNotification:(NSNotification *)notification;

- (NSArray *)_selectedArtivesForFolderPath:(NSString *)path;

@end






@implementation WCChatHistory (Private)

- (void)_expandAllGroups {
	[_historyOutlineView expandItem:[_historyOutlineView itemAtRow:1]];
	[_historyOutlineView expandItem:[_historyOutlineView itemAtRow:0]];
}


- (NSArray *)_selectedArtivesForFolderPath:(NSString *)path {
	
	if([path containsSubstring:@"PrivateChatHistory.WiredHistory"])
		return [[[[WCApplicationController sharedController] logController] privateChatHistoryBundle] archivesInFolderWithName:[path lastPathComponent]];
	else if([path containsSubstring:@"PublicChatHistory.WiredHistory"])
		return [[[[WCApplicationController sharedController] logController] publicChatHistoryBundle] archivesInFolderWithName:[path lastPathComponent]];
	
	return nil;
}


- (void)_reloadWebView {
	NSInteger	selectedRow;
	WebArchive	*archive;
	NSString	*archivePath;
	
	if(!_selectedArchives) {
		[[_detailWebView mainFrame] loadHTMLString:@"" baseURL:[NSURL URLWithString:@"about:blank"]];
		return;
	}
	
	selectedRow = [_detailsTableView selectedRow];
	
	if(selectedRow == -1) {
		[[_detailWebView mainFrame] loadHTMLString:@"" baseURL:[NSURL URLWithString:@"about:blank"]];
		return;
	}
	
	archivePath = [_selectedArchives objectAtIndex:selectedRow];
	archive		= [[WebArchive alloc] initWithData:[NSData dataWithContentsOfFile:archivePath]];
	
	if(archive)
		[[_detailWebView mainFrame] loadArchive:archive];
	else
		[[_detailWebView mainFrame] loadHTMLString:@"" baseURL:[NSURL URLWithString:@"about:blank"]];
	
	[archive release];
}


- (void)chatHistoryBundleAddedNotification:(NSNotification *)notification {
	[_detailsTableView deselectAll:self];
	[_historyOutlineView deselectAll:self];
	
	[[[[WCApplicationController sharedController] logController] publicChatHistoryBundle] reloadData];
	[[[[WCApplicationController sharedController] logController] privateChatHistoryBundle] reloadData];
	
	[_historyOutlineView reloadData];
	[self _expandAllGroups];
}


@end





@implementation WCChatHistory


#pragma mark -

+ (id)chatHistory {
	
	static WCChatHistory   *sharedHistory;
	
	if(!sharedHistory)
		sharedHistory = [[self alloc] init];
	
	return sharedHistory;
}




#pragma mark -

- (id)init {
	self = [super initWithWindowNibName:@"History"];
	if(self != nil) {		
		NSString *chatLogPath;
		
		chatLogPath			= [[WCApplicationController sharedController] chatLogsPath];
		
		_categories			= [[NSArray alloc] initWithObjects:
                               NSLS(@"PUBLIC CHATS", @"Chat History sidebar category"),
                               NSLS(@"PRIVATE CHATS", @"Chat History sidebar category"),
                               nil];
        
		_filteredArchives	= [[NSMutableArray alloc] init];
		
		[self window];
	}
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [_categories release];
	[_selectedArchives release];
	[_filteredArchives release];
	
    [super dealloc];
}


- (void)windowDidLoad {
	[super windowDidLoad];
	
	[self _expandAllGroups];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(chatHistoryBundleAddedNotification:) 
												 name:WIChatHistoryBundleAddedNotification 
											   object:nil];
}





#pragma mark -

- (IBAction)clear:(id)sender {
    
	NSAlert *alert = [NSAlert alertWithMessageText:NSLS(@"Clear History", @"Clear chat history title")
                defaultButton:@"OK"
                    alternateButton:NSLS(@"Cancel", @"Clear chat history button") otherButton:nil
						 informativeTextWithFormat:NSLS(@"Are you sure to clear your entire chat history ? This operation is not cancellable.", @"Clear chat history message")];

	[alert beginSheetModalForWindow:[_detailsTableView window]
					  modalDelegate:self
					 didEndSelector:@selector(clearAlertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
}



- (void)clearAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

	if(returnCode == NSModalResponseOK) {
		[[[[WCApplicationController sharedController] logController] publicChatHistoryBundle] clearHistory];
		[[[[WCApplicationController sharedController] logController] privateChatHistoryBundle] clearHistory];
		
		[[_detailWebView mainFrame] loadHTMLString:@"" baseURL:[NSURL URLWithString:@"about:blank"]];
	}
}



- (IBAction)exportAsWebArchive:(id)sender {
	
}



- (IBAction)search:(id)sender {
	WebArchive	*archive;
	NSString	*searchString;
	NSString	*nick;
	NSString	*server;
	NSString	*date;
	NSString	*archiveString;
	NSArray		*components;
	NSError		*error;
	
	if(_selectedArchives) {
		searchString = [_searchField stringValue];
		
		if([searchString length] <= 0) {
			[_filteredArchives setArray:_selectedArchives];
			[_detailsTableView reloadData];
			return;
		}
		
		[_filteredArchives removeAllObjects];
		
		for(NSString *archivePath in _selectedArchives) {
			archive			= [[WebArchive alloc] initWithData:[NSData dataWithContentsOfFile:archivePath]];
			components		= [[[archivePath lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"-"];
			
			nick			= [components objectAtIndex:0];
			server			= [components objectAtIndex:1];
			date			= [[NSDate dateWithTimeIntervalSince1970:[[components objectAtIndex:2] doubleValue]] description];
			archiveString   = [NSString stringWithContentsOfFile:archivePath encoding:NSASCIIStringEncoding error:&error];
			
			if([nick containsSubstring:searchString]) {
				[_filteredArchives addObject:archivePath];
				continue;
			}
			
			if([server containsSubstring:searchString]) {
				[_filteredArchives addObject:archivePath];
				continue;
			}
			
			if([date containsSubstring:searchString]) {
				[_filteredArchives addObject:archivePath];
				continue;
			}
            			
			if([archiveString containsSubstring:searchString]) {
				[_filteredArchives addObject:archivePath];
				continue;
			}
			
		}
	
		[_detailsTableView reloadData];
		
	} else {

	}
}


- (IBAction)revealInFinder:(id)sender {
	NSString *archivePath = [_filteredArchives objectAtIndex:[_detailsTableView selectedRow]];
	
	[[NSWorkspace sharedWorkspace] selectFile:archivePath 
					 inFileViewerRootedAtPath:[archivePath stringByDeletingLastPathComponent]];
}




#pragma mark - 

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    BOOL enable;
	
	enable = NO;
	
    if ([toolbarItem action] == @selector(search:)) {
        enable = (_selectedArchives != nil);
		
    } else if ([toolbarItem action] == @selector(revealInFinder:)) {
        enable = (_filteredArchives != nil) && ([_detailsTableView selectedRow] != -1);
		
    } else if ([toolbarItem action] == @selector(clear:)) {
        enable = YES;
		
    } else if ([toolbarItem action] == @selector(exportAsWebArchive:)) {
        enable = (_filteredArchives != nil) && ([_detailsTableView selectedRow] != -1);
		
    }
	
    return enable;
}



#pragma mark - 

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSInteger count = 0;
	
	if(item == nil) {
		count = [_categories count];
		
	} else if([_categories containsObject:item]) {
		if([item isEqualTo:NSLS(@"PUBLIC CHATS", @"Chat History sidebar category")]) {
			count = [[[[[WCApplicationController sharedController] logController] publicChatHistoryBundle] folders] count];
			
		} else if([item isEqualTo:NSLS(@"PRIVATE CHATS", @"Chat History sidebar category")]) {
			count = [[[[[WCApplicationController sharedController] logController] privateChatHistoryBundle] folders] count];
			
		}
	}
	
	return count;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	id value;
	
	if(item == nil) {
		value = [_categories objectAtIndex:index];
		
	} else if([_categories containsObject:item]) {
		if([item isEqualTo:NSLS(@"PUBLIC CHATS", @"Chat History sidebar category")]) {
			value = [[[[[WCApplicationController sharedController] logController] publicChatHistoryBundle] folders] objectAtIndex:index];
			
		} else if([item isEqualTo:NSLS(@"PRIVATE CHATS", @"Chat History sidebar category")]) {
			value = [[[[[WCApplicationController sharedController] logController] privateChatHistoryBundle] folders] objectAtIndex:index];
		}
	}
	
	return value;
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	id value = nil;
	
	if(item == nil) {
		return nil;
		
	} else if(![_categories containsObject:item]) {
		value = [item lastPathComponent];
		
	} else {
		value = item;
	}
	
	return value;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	return (item == nil) ? NO : ![_categories containsObject:item];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return (item == nil) ? YES : [_categories containsObject:item];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return (item == nil) ? YES : [_categories containsObject:item];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSString *item = [[notification object] itemAtRow:[_historyOutlineView selectedRow]];
	
	if(![_categories containsObject:item]) {
		
		if(_selectedArchives)
            [_selectedArchives release]; _selectedArchives = nil;
		
		if(_filteredArchives)
            [_filteredArchives release]; _filteredArchives = nil;
		
		_filteredArchives = [[NSMutableArray alloc] init];
		_selectedArchives = [[self _selectedArtivesForFolderPath:item] retain];
		
		[_filteredArchives addObjectsFromArray:_selectedArchives];
		
		[_detailsTableView reloadData];
		[self _reloadWebView];
		
		return;
	}
	
	if(_selectedArchives)
        [_selectedArchives release]; _selectedArchives = nil;
	
	[_detailsTableView reloadData];
	[self _reloadWebView];
}





#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return (_filteredArchives == nil) ? 0 : [_filteredArchives count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString		*item;
	NSArray			*components;
	
	if(row == -1)
		return nil;
	
	item		= [_filteredArchives objectAtIndex:row];
	components	= [[[item lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"-"];
	
	if([[tableColumn identifier] isEqualToString:@"Nick"])
		return [components objectAtIndex:0];
	
	else if([[tableColumn identifier] isEqualToString:@"Server"])
		return [components objectAtIndex:1];
	
	else if([[tableColumn identifier] isEqualToString:@"Date"])
		return [NSDate dateWithTimeIntervalSince1970:[[components objectAtIndex:2] doubleValue]];	
			
	return nil;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self _reloadWebView];
}


- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	
	__block NSArray		*components1, *components2, *sortedArray;;
	__block NSString	*identifier, *string1, *string2;
	__block NSDate		*date1, *date2;
	
	[_detailsTableView setHighlightedTableColumn:tableColumn];	
	
	identifier	= [tableColumn identifier];
	
	sortedArray = [_filteredArchives sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSComparisonResult result;
		id tmpObj;
		
		tmpObj = obj1;
		
		if([_detailsTableView sortOrder] == WISortAscending) {
			obj1 = obj2;
			obj2 = tmpObj;
		}
		
		components1		= [[[obj1 lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"-"];
		components2		= [[[obj2 lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"-"];
		
		if([identifier isEqualToString:@"Nick"]) {
			string1			= [components1 objectAtIndex:0];
			string2			= [components2 objectAtIndex:0];
			result			= [string1 compare:string2];
			
		} else if([identifier isEqualToString:@"Server"]) {
			string1			= [components1 objectAtIndex:1];
			string2			= [components2 objectAtIndex:1];
			result			= [string1 compare:string2];
			
		} else if([identifier isEqualToString:@"Date"]) {
			date1			= [NSDate dateWithTimeIntervalSince1970:[[components1 objectAtIndex:2] doubleValue]];
			date2			= [NSDate dateWithTimeIntervalSince1970:[[components2 objectAtIndex:2] doubleValue]];
			
			result			= [date2 compare:date1];
		}
		return result;
	}];
	
	[_filteredArchives setArray:sortedArray];
	
	[_detailsTableView reloadData];
}






#pragma mark -

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
	if(splitView == _historySplitView)
		return proposedMin + 140.0;
	
	else if(splitView == _detailsSplitView)
		return proposedMin + 40.0;
	
	return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
	if(splitView == _historySplitView)
		return 200.0;
	
	else if(splitView == _detailsSplitView)
		return proposedMax - 40.0;
    
	return proposedMax;
}



- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    if(splitView == _historySplitView) {
        if(view == [[splitView subviews] objectAtIndex:1])
            return YES;
		
    } else if(splitView == _detailsSplitView) {
        if(view == [[splitView subviews] objectAtIndex:1])
            return YES;    
    }
    return NO;
}


@end
