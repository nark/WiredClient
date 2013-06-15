/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "WCAccount.h"
#import "WCServerConnection.h"
#import "WCSettingsController.h"

#define WCTrackerPboardType				@"WCTrackeryPboardType"
#define WCCategoryPboardType			@"WCCategoryPboardType"


@interface WCSettingsController(Private)

- (void)_validate;

- (void)_requestSettings;
- (void)_setSettings;

@end


@implementation WCSettingsController(Private)

- (void)_validate {
	BOOL		connected, edit;
	
	connected = [[_administration connection] isConnected];
	edit = [[[_administration connection] account] settingsSetSettings];
	
	[_nameTextField setEnabled:(edit && connected)];
	[_descriptionTextField setEnabled:(edit && connected)];
	[_bannerImageView setEnabled:(edit && connected)];
	[_downloadsTextField setEnabled:(edit && connected)];
	[_downloadSpeedTextField setEnabled:(edit && connected)];
	[_uploadsTextField setEnabled:(edit && connected)];
	[_uploadSpeedTextField setEnabled:(edit && connected)];
	
	[_registerWithTrackersButton setEnabled:(edit && connected)];
	[_addTrackerButton setEnabled:(edit && connected)];
	[_deleteTrackerButton setEnabled:(edit && connected && [_trackersTableView selectedRow] >= 0)];
	
	[_enableTrackerButton setEnabled:(edit && connected)];
	[_addCategoryButton setEnabled:(edit && connected)];
	[_deleteCategoryButton setEnabled:(edit && connected && [_categoriesTableView selectedRow] >= 0)];
	
	[_saveButton setEnabled:(edit && connected && _touched)];
}



#pragma mark -

- (void)_requestSettings {
	WIP7Message		*message;
	
	if([[_administration connection] isConnected] && [[[_administration connection] account] settingsGetSettings] && !_touched) {
		message = [WIP7Message messageWithName:@"wired.settings.get_settings" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredSettingsGetSettingsReply:)];
		
		[_progressIndicator startAnimation:self];
	}
}



- (void)_setSettings {
	WIP7Message		*message;
	NSImage			*image;
	NSData			*data;
	
	message = [WIP7Message messageWithName:@"wired.settings.set_settings" spec:WCP7Spec];
	[message setString:[_nameTextField stringValue] forName:@"wired.info.name"];
	[message setString:[_descriptionTextField stringValue] forName:@"wired.info.description"];
	
	image = [_bannerImageView image];
	
	if(image) {
		data = [[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]]
			representationUsingType:NSPNGFileType properties:NULL];
	} else {
		data = [NSData data];
	}
	
	[message setData:data forName:@"wired.info.banner"];
	[message setUInt32:[_downloadsTextField intValue] forName:@"wired.info.downloads"];
	[message setUInt32:[_downloadSpeedTextField intValue] * 1024 forName:@"wired.info.download_speed"];
	[message setUInt32:[_uploadsTextField intValue] forName:@"wired.info.uploads"];
	[message setUInt32:[_uploadSpeedTextField intValue] * 1024 forName:@"wired.info.upload_speed"];
	[message setBool:[_registerWithTrackersButton state] forName:@"wired.settings.register_with_trackers"];
	[message setList:_trackers forName:@"wired.settings.trackers"];
	[message setBool:[_enableTrackerButton state] forName:@"wired.tracker.tracker"];
	[message setList:_categories forName:@"wired.tracker.categories"];
	
	[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredSettingsSetSettingsReply:)];
}

@end



@implementation WCSettingsController

- (void)dealloc {
	[_trackers release];
	[_categories release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	NSComboBoxCell		*comboBoxCell;
	
	[_bannerImageView setMaxImageSize:NSMakeSize(200.0, 32.0)];
	
	[_trackersTableView registerForDraggedTypes:[NSArray arrayWithObject:WCTrackerPboardType]];
	[_categoriesTableView registerForDraggedTypes:[NSArray arrayWithObject:WCCategoryPboardType]];

    comboBoxCell = [[NSComboBoxCell alloc] init];
    [comboBoxCell setControlSize:NSSmallControlSize];
	[comboBoxCell setFont:[NSFont smallSystemFont]];
    [comboBoxCell setUsesDataSource:NO];
	[comboBoxCell addItemsWithObjectValues:[NSArray arrayWithObjects:
		@"Chat",
		@"Movies",
		@"Music",
		@"Regional/Asia",
		@"Regional/Europe",
		@"Regional/Oceania",
		@"Regional/North America",
		@"Regional/South America",
		@"Software",
		@"Trackers",
		NULL]];
    [comboBoxCell setNumberOfVisibleItems:[comboBoxCell numberOfItems]];
    [comboBoxCell setEditable:YES];
    [_categoryTableColumn setDataCell:comboBoxCell];
    [comboBoxCell release];
	
	[self _validate];
}



- (void)controlTextDidChange:(NSNotification *)notification {
	[self touch:self];
}



- (NSSize)controllerWindowWillResizeToSize:(NSSize)proposedFrameSize {
	return [[_administration window] frame].size;
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	if([[_administration window] isVisible] && [_administration selectedController] == self)
		[self _requestSettings];
}



- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
	if([[_administration window] isVisible] && [_administration selectedController] == self)
		[self _requestSettings];
	
	[self _validate];
}



- (void)wiredSettingsGetSettingsReply:(WIP7Message *)message {
	NSImage			*image;
	WIP7UInt32		downloads, uploads, downloadSpeed, uploadSpeed;
	WIP7Bool		registerWithTrackers, tracker;

	if([[message name] isEqualToString:@"wired.settings.settings"]) {
		[message getUInt32:&downloads forName:@"wired.info.downloads"];
		[message getUInt32:&uploads forName:@"wired.info.uploads"];
		[message getUInt32:&downloadSpeed forName:@"wired.info.download_speed"];
		[message getUInt32:&uploadSpeed forName:@"wired.info.upload_speed"];
		[message getBool:&registerWithTrackers forName:@"wired.settings.register_with_trackers"];
		[message getBool:&tracker forName:@"wired.tracker.tracker"];
		
		[_nameTextField setStringValue:[message stringForName:@"wired.info.name"]];
		[_descriptionTextField setStringValue:[message stringForName:@"wired.info.description"]];
		
		image = [[NSImage alloc] initWithData:[message dataForName:@"wired.info.banner"]];
		[_bannerImageView setImage:image];
		[image release];
		
		if(downloads > 0)
			[_downloadsTextField setIntValue:downloads];
		else
			[_downloadsTextField setStringValue:@""];
		
		if(downloadSpeed > 0)
			[_downloadSpeedTextField setIntValue:(double) downloadSpeed / 1024.0];
		else
			[_downloadSpeedTextField setStringValue:@""];
		
		if(uploads > 0)
			[_uploadsTextField setIntValue:uploads];
		else
			[_uploadsTextField setStringValue:@""];
		
		if(uploadSpeed > 0)
			[_uploadSpeedTextField setIntValue:(double) uploadSpeed / 1024.0];
		else
			[_uploadSpeedTextField setStringValue:@""];
		
		[_registerWithTrackersButton setState:registerWithTrackers];
		
		[_trackers release];
		_trackers = [[message listForName:@"wired.settings.trackers"] mutableCopy];
		[_trackersTableView reloadData];

		[_enableTrackerButton setState:tracker];
		
		[_categories release];
		_categories = [[message listForName:@"wired.tracker.categories"] mutableCopy];
		[_categoriesTableView reloadData];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		// error
	}
	
	[_progressIndicator stopAnimation:self];
}



- (void)wiredSettingsSetSettingsReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"]) {
		// error
	}
}



#pragma mark -

- (void)controllerWindowDidBecomeKey {
	[self _requestSettings];
}



- (void)controllerDidSelect {
	[[_administration window] setShowsResizeIndicator:NO];
	[[_administration window] makeFirstResponder:_nameTextField];
	
	[self _requestSettings];
}



- (void)controllerDidUnselect {
	[[_administration window] setShowsResizeIndicator:YES];
}



#pragma mark -

- (NSSize)maximumWindowSize {
	return NSMakeSize(712.0, 619.0);
}



- (NSSize)minimumWindowSize {
	return [self maximumWindowSize];
}



#pragma mark -

- (IBAction)addTracker:(id)sender {
	NSInteger		row;
	
	[_trackers addObject:@"wired:///"];
	
	row = [_trackers count] - 1;
	
	[_trackersTableView reloadData];
	[_trackersTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[_trackersTableView editColumn:0 row:row withEvent:NULL select:YES];

	[self touch:self];
}



- (IBAction)deleteTracker:(id)sender {
	NSInteger		row;
	
	row = [_trackersTableView selectedRow];
	
	[_trackers removeObjectAtIndex:row];
	[_trackersTableView reloadData];
	
	[self touch:self];
}



- (IBAction)addCategory:(id)sender {
	NSInteger		row;
	
	[_categories addObject:@""];
	
	row = [_categories count] - 1;
	
	[_categoriesTableView reloadData];
	[_categoriesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[_categoriesTableView editColumn:0 row:row withEvent:NULL select:YES];

	[self touch:self];
}



- (IBAction)deleteCategory:(id)sender {
	NSInteger		row;
	
	row = [_categoriesTableView selectedRow];
	
	[_categories removeObjectAtIndex:row];
	[_categoriesTableView reloadData];
	
	[self touch:self];
}



- (IBAction)save:(id)sender {
	[self _setSettings];
	
	_touched = NO;

	[self _validate];
	[self _requestSettings];
}



- (IBAction)touch:(id)sender {
	_touched = YES;
	
	[self _validate];
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if(tableView == _trackersTableView)
		return [_trackers count];
	else if(tableView == _categoriesTableView)
		return [_categories count];

	return 0;
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	WIURL		*url;
	
	if(tableView == _trackersTableView) {
		url = [WIURL URLWithString:[_trackers objectAtIndex:row]];
		
		if(tableColumn == _trackerTableColumn) {
			return [url hostpair];
		}
		else if(tableColumn == _userTableColumn) {
			return [url user];
		}
		else if(tableColumn == _passwordTableColumn) {
			return [url password];
		}
		else if(tableColumn == _categoryTableColumn) {
			if([[url path] length] > 1)
				return [[url path] substringFromIndex:1];
		}
	}
	else if(tableView == _categoriesTableView) {
		return [_categories objectAtIndex:row];
	}

	return NULL;
}



- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	WIURL		*url;
	
	if(tableView == _trackersTableView) {
		url = [WIURL URLWithString:[_trackers objectAtIndex:row] scheme:@"wiredp7"];

		if(tableColumn == _trackerTableColumn)
			[url setHostpair:object];
		else if(tableColumn == _userTableColumn)
			[url setUser:object];
		else if(tableColumn == _passwordTableColumn)
			[url setPassword:[object SHA1]];
		else if(tableColumn == _categoryTableColumn)
			[url setPath:[NSSWF:@"/%@", object]];
		
		[_trackers replaceObjectAtIndex:row withObject:[url humanReadableString]];
	}
	else if(tableView == _categoriesTableView) {
		[_categories replaceObjectAtIndex:row withObject:object];
	}
	
	[self touch:self];
}



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self _validate];
}



- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	NSUInteger		index;
	
	index = [indexes firstIndex];
	
	if(tableView == _trackersTableView) {
		[pasteboard declareTypes:[NSArray arrayWithObject:WCTrackerPboardType] owner:NULL];
		[pasteboard setString:[NSSWF:@"%ld", index] forType:WCTrackerPboardType];
	}
	else if(tableView == _categoriesTableView) {
		[pasteboard declareTypes:[NSArray arrayWithObject:WCCategoryPboardType] owner:NULL];
		[pasteboard setString:[NSSWF:@"%ld", index] forType:WCCategoryPboardType];
	}
	
	return YES;
}



- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	if(operation != NSTableViewDropAbove)
		return NSDragOperationNone;

	return NSDragOperationGeneric;
}



- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard	*pasteboard;
	NSArray			*types;
	NSInteger		fromRow;
	
	pasteboard = [info draggingPasteboard];
	types = [pasteboard types];
	
	if([types containsObject:WCTrackerPboardType]) {
		fromRow = [[pasteboard stringForType:WCTrackerPboardType] integerValue];
		[_trackers moveObjectAtIndex:fromRow toIndex:row];
		[_trackersTableView reloadData];
		
		[self touch:self];
		
		return YES;
	}
	else if([types containsObject:WCCategoryPboardType]) {
		fromRow = [[pasteboard stringForType:WCCategoryPboardType] integerValue];
		[_categories moveObjectAtIndex:fromRow toIndex:row];
		[_categoriesTableView reloadData];
		
		[self touch:self];
		
		return YES;
	}
	
	return NO;
}

@end
