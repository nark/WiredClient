/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
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

#import <WiredAppKit/WIOutlineView.h>
#import "WITableViewManager.h"

@interface WIOutlineView(Private)

- (void)_initTableView;

@end


@implementation WIOutlineView(Private)

- (void)_initTableView {
	_tableViewManager = [[WITableViewManager alloc] initWithTableView:(WITableView *) self];
}

@end



@implementation WIOutlineView

- (id)initWithFrame:(NSRect)rect {
	self = [super initWithFrame:rect];
	
	[self _initTableView];
    
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	[self _initTableView];
    
	return self;
}



- (id)initWithFrame:(NSRect)frame tableColumns:(NSArray *)tableColumns {
	NSEnumerator		*enumerator;
	NSTableColumn		*tableColumn;
	
	self = [super initWithFrame:frame];
	
	enumerator = [tableColumns objectEnumerator];
	
	while((tableColumn = [enumerator nextObject]))
		[self addTableColumn:tableColumn];
	
	[self _initTableView];
	
	return self;
}



- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:_tableViewManager];

	[_tableViewManager release];

	[super dealloc];
}



#pragma mark -

- (void)keyDown:(NSEvent *)event {
	if(![_tableViewManager keyDown:event])
		[super keyDown:event];
}



- (void)insertText:(id)string {
	[_tableViewManager insertText:string];
}



- (void)copy:(id)sender {
	[_tableViewManager copy:sender];
}



- (void)flagsChanged:(id)sender {
	[_tableViewManager flagsChanged:sender];
}



#pragma mark -

- (void)selectRowWithStringValue:(NSString *)string {
	[_tableViewManager selectRowWithStringValue:string];
}



- (void)selectRowWithStringValue:(NSString *)string options:(NSUInteger)options {
	[_tableViewManager selectRowWithStringValue:string options:options];
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	return [_tableViewManager validateMenuItem:item];
}



- (IBAction)showViewOptions:(id)sender {
	[_tableViewManager showViewOptions:sender];
}



- (NSArray *)allTableColumns {
	return [_tableViewManager allTableColumns];
}



- (void)includeTableColumn:(NSTableColumn *)tableColumn {
	[_tableViewManager includeTableColumn:tableColumn];
}



- (void)includeTableColumnWithIdentifier:(NSString *)identifier {
	[_tableViewManager includeTableColumnWithIdentifier:identifier];
}



- (void)excludeTableColumn:(NSTableColumn *)tableColumn {
	[_tableViewManager excludeTableColumn:tableColumn];
}



- (void)excludeTableColumnWithIdentifier:(NSString *)identifier {
	[_tableViewManager excludeTableColumnWithIdentifier:identifier];
}



- (WISortOrder)sortOrder {
	return [_tableViewManager sortOrder];
}



- (void)setAutosaveName:(NSString *)name {
	[name retain];
	[_WI_autosaveName release];
	
	_WI_autosaveName = name;
}



- (NSString *)autosaveName {
	return _WI_autosaveName;
}



- (void)setAutosaveTableColumns:(BOOL)value {
	[_tableViewManager setAutosaveTableColumns:value];
	
	_WI_autosaveTableColumns = value;
}



- (BOOL)autosaveTableColumns {
	return _WI_autosaveTableColumns;
}



- (void)setHighlightedTableColumn:(NSTableColumn *)tableColumn {
	[_tableViewManager setHighlightedTableColumn:tableColumn];

	[super setHighlightedTableColumn:tableColumn];
}



#pragma mark -

- (void)setPropertiesFromDictionary:(NSDictionary *)dictionary {
	[_tableViewManager setPropertiesFromDictionary:dictionary];
}



- (NSDictionary *)propertiesDictionary {
	return [_tableViewManager propertiesDictionary];
}



- (void)setAllowsUserCustomization:(BOOL)value {
	[_tableViewManager setAllowsUserCustomization:value];
}



- (BOOL)allowsUserCustomization {
	return [_tableViewManager allowsUserCustomization];
}



- (void)setDefaultTableColumnIdentifiers:(NSArray *)columns {
	[_tableViewManager setDefaultTableColumnIdentifiers:columns];
}



- (NSArray *)defaultTableColumnIdentifiers {
	return [_tableViewManager defaultTableColumnIdentifiers];
}



- (void)setDefaultHighlightedTableColumnIdentifier:(NSString *)identifier {
	[_tableViewManager setDefaultHighlightedTableColumnIdentifier:identifier];
}



- (NSString *)defaultHighlightedTableColumnIdentifier {
	return [_tableViewManager defaultHighlightedTableColumnIdentifier];
}



- (void)setDefaultSortOrder:(WISortOrder)order {
	[_tableViewManager setDefaultSortOrder:order];
}



- (WISortOrder)defaultSortOrder {
	return [_tableViewManager defaultSortOrder];
}



- (void)setHighlightedTableColumn:(NSTableColumn *)tableColumn sortOrder:(WISortOrder)sortOrder {
	[_tableViewManager setHighlightedTableColumn:tableColumn sortOrder:sortOrder];
}



- (void)setUpAction:(SEL)action {
	[_tableViewManager setUpAction:action];
}



- (SEL)upAction {
	return [_tableViewManager upAction];
}



- (void)setDownAction:(SEL)action {
	[_tableViewManager setDownAction:action];
}



- (SEL)downAction {
	return [_tableViewManager downAction];
}



- (void)setBackAction:(SEL)action {
	[_tableViewManager setBackAction:action];
}



- (SEL)backAction {
	return [_tableViewManager backAction];
}



- (void)setForwardAction:(SEL)action {
	[_tableViewManager setForwardAction:action];
}



- (SEL)forwardAction {
	return [_tableViewManager forwardAction];
}



- (void)setEscapeAction:(SEL)action {
	[_tableViewManager setEscapeAction:action];
}



- (SEL)escapeAction {
	return [_tableViewManager escapeAction];
}



- (void)setDeleteAction:(SEL)action {
	[_tableViewManager setDeleteAction:action];
}



- (SEL)deleteAction {
	return [_tableViewManager deleteAction];
}



- (void)setSpaceAction:(SEL)action {
	[_tableViewManager setSpaceAction:action];
}



- (SEL)spaceAction {
	return [_tableViewManager spaceAction];
}



- (void)setFont:(NSFont *)font {
	[_tableViewManager setFont:font];
}



- (NSFont *)font {
	return [_tableViewManager font];
}



#pragma mark -

- (NSRect)labelRectForRow:(NSInteger)row {
	NSRect		rect;
	
	rect = [self rectOfRow:row];
	
	rect.origin.x += 2.0;

	if([[self selectedRowIndexes] containsIndex:row])
		rect.size.width = 18.0;
	else
		rect.size.width -= 4.0;
	
	rect.size.height -= 1.0;
	
	return rect;
}



#pragma mark -

- (NSMenu *)menuForEvent:(NSEvent *)event {
	return [_tableViewManager menuForEvent:event defaultMenu:[super menuForEvent:event]];
}



- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect {
	[_tableViewManager drawRow:row clipRect:clipRect];
	
	[super drawRow:row clipRect:clipRect];
}

@end
