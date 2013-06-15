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

#import "WCAdministration.h"

@interface WCSettingsController : WCAdministrationController {
	IBOutlet NSBox							*_box;
	
	IBOutlet NSTextField					*_nameTextField;
	IBOutlet NSTextField					*_descriptionTextField;
	IBOutlet WIImageViewWithImagePicker		*_bannerImageView;
	IBOutlet NSTextField					*_downloadsTextField;
	IBOutlet NSTextField					*_downloadSpeedTextField;
	IBOutlet NSTextField					*_uploadsTextField;
	IBOutlet NSTextField					*_uploadSpeedTextField;
	
	IBOutlet NSButton						*_registerWithTrackersButton;
	IBOutlet NSTableView					*_trackersTableView;
	IBOutlet NSTableColumn					*_trackerTableColumn;
	IBOutlet NSTableColumn					*_userTableColumn;
	IBOutlet NSTableColumn					*_passwordTableColumn;
	IBOutlet NSTableColumn					*_categoryTableColumn;
	IBOutlet NSButton						*_addTrackerButton;
	IBOutlet NSButton						*_deleteTrackerButton;
	
	IBOutlet NSButton						*_enableTrackerButton;
	IBOutlet NSTableView					*_categoriesTableView;
	IBOutlet NSButton						*_addCategoryButton;
	IBOutlet NSButton						*_deleteCategoryButton;
	
	IBOutlet NSProgressIndicator			*_progressIndicator;
	IBOutlet NSButton						*_saveButton;
	
	NSMutableArray							*_trackers;
	NSMutableArray							*_categories;

	BOOL									_touched;
	NSSize									_windowSize;
	NSSize									_minWindowSize;
}

- (IBAction)addTracker:(id)sender;
- (IBAction)deleteTracker:(id)sender;
- (IBAction)addCategory:(id)sender;
- (IBAction)deleteCategory:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)touch:(id)sender;

@end
