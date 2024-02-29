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

#import "WCConnectionController.h"

@class WCSettingsController, WCMonitorController, WCEventsController, WCLogController, WCAccountsController, WCBanlistController;
@class WCErrorQueue;

@interface WCAdministration : WCConnectionController <NSWindowDelegate, NSToolbarDelegate> {
	IBOutlet NSView						*_settingsView;
	IBOutlet NSView						*_monitorView;
	IBOutlet NSView						*_eventsView;
	IBOutlet NSView						*_logView;
	IBOutlet NSView						*_accountsView;
	IBOutlet NSView						*_banlistView;
	
	IBOutlet WCSettingsController		*_settingsController;
	IBOutlet WCMonitorController		*_monitorController;
	IBOutlet WCEventsController			*_eventsController;
	IBOutlet WCLogController			*_logController;
	IBOutlet WCAccountsController		*_accountsController;
	IBOutlet WCBanlistController		*_banlistController;
	
	WCErrorQueue						*_errorQueue;
	
	NSMutableArray						*_identifiers;
	NSMutableDictionary					*_views;
	
	NSView								*_shownView;
	id									_shownController;
}

+ (id)administrationWithConnection:(WCServerConnection *)connection;

- (NSString *)newDocumentMenuItemTitle;
- (NSString *)deleteDocumentMenuItemTitle;

- (void)selectController:(id)controller;
- (id)selectedController;

- (WCSettingsController *)settingsController;
- (WCMonitorController *)monitorController;
- (WCEventsController *)eventsController;
- (WCLogController *)logController;
- (WCAccountsController *)accountsController;
- (WCBanlistController *)banlistController;

- (void)showError:(WCError *)error;

- (IBAction)newDocument:(id)sender;
- (IBAction)deleteDocument:(id)sender;
- (IBAction)toolbarItem:(id)sender;
- (IBAction)submitSheet:(id)sender;

@end


@interface WCAdministrationController : WIObject {
	IBOutlet WCAdministration			*_administration;
}

- (void)themeDidChange:(NSDictionary *)theme;
- (void)windowDidLoad;
- (void)linkConnectionLoggedIn:(NSNotification *)notification;
- (void)linkConnectionDidClose:(NSNotification *)notification;
- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification;

- (void)controllerWindowDidBecomeKey;
- (BOOL)controllerWindowShouldClose;
- (void)controllerWindowWillClose;
- (void)controllerDidSelect;
- (BOOL)controllerShouldUnselectForNewController:(id)controller;
- (void)controllerDidUnselect;

- (NSSize)maximumWindowSize;
- (NSSize)minimumWindowSize;

- (NSString *)newDocumentMenuItemTitle;
- (NSString *)deleteDocumentMenuItemTitle;

- (void)setAdministration:(WCAdministration *)administration;

@end
