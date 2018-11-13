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

#import <WiredAppKit/NSEvent-WIAppKit.h>
#import <WiredAppKit/NSFont-WIAppKit.h>
#import <WiredAppKit/WITreeCell.h>
#import <WiredAppKit/WITreeTableView.h>
#import <WiredAppKit/WITreeScrollView.h>
#import <WiredAppKit/WITreeView.h>

#define _WITreeViewMinimumTableViewWidth				50.0
#define _WITreeViewMinimumDetailViewWidth				220.0
#define _WITreeViewInitialTableViewWidth				250.0
#define _WITreeViewAnimatedScrollingFPS					(1.0 / 60.0)


NSString * const WIFileIcon								= @"WIFileIcon";
NSString * const WIFileSize								= @"WIFileSize";
NSString * const WIFileKind								= @"WIFileKind";
NSString * const WIFileCreationDate						= @"WIFileCreationDate";
NSString * const WIFileModificationDate					= @"WIFileModificationDate";


@interface WITreeView(Private)

- (void)_initTreeView;

- (void)_addTableView;
- (void)_sizeToFit;
- (CGFloat)_widthOfTableViews:(NSUInteger)count;
- (void)_scrollToIndex:(NSUInteger)index;
- (void)_scrollToSelection;
- (void)_scrollForwardToSelectionAnimated;

- (void)_showDetailViewForPath:(NSString *)path;
- (NSString *)_HTMLStringForPath:(NSString *)path attributes:(NSDictionary *)attributes;
- (void)_hideDetailView;
- (void)_resizeDetailView;

- (void)_setPath:(NSString *)path;
- (NSString *)_path;
- (NSUInteger)_numberOfUsedPathComponents;

- (WITreeScrollView *)_newScrollViewWithTableView;
- (NSString *)_pathForTableView:(NSTableView *)tableView;
- (NSArray *)_tableViewsAheadOfTableView:(NSTableView *)tableView;

@end


@implementation WITreeView(Private)

- (void)_initTreeView {
	_views = [[NSMutableArray alloc] init];
	
	[WIDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	[NSBundle loadNibNamed:@"TreeDetail" owner:self];
	
	_detailTemplate = [[NSString alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"TreeDetail" ofType:@"html"]
													  encoding:NSUTF8StringEncoding
														 error:NULL];

	[self setPostsFrameChangedNotifications:YES];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(_WI_viewFrameDidChangeNotification:)
			   name:NSViewFrameDidChangeNotification
			 object:self];
	
	[self _setPath:@"/"];

	[self setRowHeight:17.0];
	[self setFont:[NSFont systemFont]];
	
	[self _addTableView];
	[self _addTableView];
}



#pragma mark -

- (void)_addTableView {
	NSScrollView		*scrollView;
	NSRect				frame;
	NSUInteger			i, count;
	CGFloat				offset = 0.0;
	
	scrollView = [self _newScrollViewWithTableView];

	count = [_views count];
	
	for(i = 0; i < count; i++)
		offset += [[[_views objectAtIndex:i] enclosingScrollView] frame].size.width - 1.0;
	
	frame = [scrollView frame];
	frame.origin.x = offset - 1.0;
	[scrollView setFrame:frame];
	
	[_views addObject:[scrollView documentView]];
	[self addSubview:scrollView];
	
	[scrollView release];
}



- (void)_sizeToFit {
	NSRect		frame;
	NSSize		size;
	
	frame = [self frame];
	frame.size.width = [self _widthOfTableViews:[self _numberOfUsedPathComponents] + 1];
	size = [[self enclosingScrollView] documentVisibleRect].size;
	
	if(frame.size.width < size.width)
		frame.size.width = size.width;

	[self setFrame:frame];
}



- (CGFloat)_widthOfTableViews:(NSUInteger)count {
	NSUInteger		i;
	CGFloat			width = 0.0;
	
	for(i = 0; i < count; i++)
		width += [[[_views objectAtIndex:i] enclosingScrollView] frame].size.width - 1.0;
	
	return width;
}



- (void)_scrollToIndex:(NSUInteger)index {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_scrollForwardToSelectionAnimated) object:NULL];
	
	_scrollingPoint = NSMakePoint([self _widthOfTableViews:index], 0.0);
	
	[self _scrollForwardToSelectionAnimated];
}



- (void)_scrollToSelection {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_scrollForwardToSelectionAnimated) object:NULL];
	
	_scrollingPoint = NSMakePoint([self frame].size.width, 0.0);
	
	[self _scrollForwardToSelectionAnimated];
}



- (void)_scrollForwardToSelectionAnimated {
	NSPoint		startPoint, point;
	
	startPoint = [[self enclosingScrollView] documentVisibleRect].origin;
	point = NSMakePoint(startPoint.x + ((_scrollingPoint.x - startPoint.x) * _WITreeViewAnimatedScrollingFPS * (1.0 / 0.2)), 0.0);
	
	[self scrollPoint:point];
	
	point = [[self enclosingScrollView] documentVisibleRect].origin;
	
	if(point.x > startPoint.x && point.x < _scrollingPoint.x)
		[self performSelector:@selector(_scrollForwardToSelectionAnimated) withObject:NULL afterDelay:_WITreeViewAnimatedScrollingFPS];
}



#pragma mark -

- (void)_showDetailViewForPath:(NSString *)path {
	NSDictionary	*attributes;
	NSImage			*icon;
	
	attributes = [[self delegate] treeView:self attributesForPath:path];
	
	if(!attributes) {
		[self _hideDetailView];
		
		return;
	}
	
	[self _resizeDetailView];
	
	icon = [attributes objectForKey:WIFileIcon];
	[icon setSize:NSMakeSize(128.0, 128.0)];
	[_iconImageView setImage:icon];
	
	[[_attributesWebView mainFrame] loadHTMLString:[self _HTMLStringForPath:path attributes:attributes] baseURL:NULL];
	
	[_moreInfoButton setHidden:![[self delegate] respondsToSelector:@selector(treeView:showMoreInfoForPath:)]];
	
	[self validate];

	if(![_detailView superview])
		[self addSubview:_detailView];
}



- (NSString *)_HTMLStringForPath:(NSString *)path attributes:(NSDictionary *)attributes {
	NSMutableString		*string;
	id					value;
	
	string = [[_detailTemplate mutableCopy] autorelease];
	
	[string replaceOccurrencesOfString:@"<? namelabel ?>" withString:WILS(@"Name:", @"Tree detail attribute label")];
	[string replaceOccurrencesOfString:@"<? kindlabel ?>" withString:WILS(@"Kind:", @"Tree detail attribute label")];
	[string replaceOccurrencesOfString:@"<? sizelabel ?>" withString:WILS(@"Size:", @"Tree detail attribute label")];
	[string replaceOccurrencesOfString:@"<? createdlabel ?>" withString:WILS(@"Created:", @"Tree detail attribute label")];
	[string replaceOccurrencesOfString:@"<? modifiedlabel ?>" withString:WILS(@"Modified:", @"Tree detail attribute label")];
	
	[string replaceOccurrencesOfString:@"<? name ?>" withString:[path lastPathComponent]];
	
	value = [attributes objectForKey:WIFileKind];

	[string replaceOccurrencesOfString:@"<? kind ?>" withString:value ? value : @""];
	
	value = [NSString humanReadableStringForSizeInBytes:[[attributes objectForKey:WIFileSize] unsignedLongLongValue]];

	[string replaceOccurrencesOfString:@"<? size ?>" withString:value];

	value = [attributes objectForKey:WIFileCreationDate];
	
	[string replaceOccurrencesOfString:@"<? created ?>" withString:value ? [_dateFormatter stringFromDate:value] : @""];

	value = [attributes objectForKey:WIFileModificationDate];
	
	[string replaceOccurrencesOfString:@"<? modified ?>" withString:value ? [_dateFormatter stringFromDate:value] : @""];
	
	return string;
}



- (void)_hideDetailView {
	[_detailView removeFromSuperview];
}



- (void)_resizeDetailView {
	id				object;
	NSRect			frame, lastScrollViewFrame, viewFrame;
	CGFloat			height;
	
	lastScrollViewFrame = [[[_views objectAtIndex:[self _numberOfUsedPathComponents]] enclosingScrollView] frame];
	
	frame				= [_detailView frame];
	frame.size.width	= lastScrollViewFrame.size.width - [NSScroller scrollerWidth] - 1.0;
	frame.size.height	= lastScrollViewFrame.size.height;
	frame.origin.x		= [self _widthOfTableViews:[self _numberOfUsedPathComponents]];

	[_detailView setFrame:frame];
	
	viewFrame			= [_iconImageView frame];
	viewFrame.origin.x	= (frame.size.width / 2.0) - (viewFrame.size.width / 2.0);
	
	[_iconImageView setFrame:viewFrame];
	
	object = [[_attributesWebView windowScriptObject] evaluateWebScript:@"document.getElementById(\"detail\").offsetHeight"];
	
	if(object != [WebUndefined undefined]) {
		height				= [object floatValue];
		viewFrame			= [_moreInfoButton frame];
		viewFrame.origin.y	= [_attributesWebView frame].origin.y + [_attributesWebView frame].size.height - height - 40.0;
	
		[_moreInfoButton setFrame:viewFrame];
	}
}



#pragma mark -

- (void)_setPath:(NSString *)path {
	[path retain];
	[_path release];
	
	_path = path;
	
	if(!_inChangedPath) {
		_inChangedPath = YES;
		[[self delegate] treeView:self changedPath:_path];
		_inChangedPath = NO;
	}
}



- (NSString *)_path {
	return _path;
}



- (NSUInteger)_numberOfUsedPathComponents {
	return [[[self _path] pathComponents] count] - 1;
}


- (void)tableViewSingleClick:(id)sender {
    if([sender isKindOfClass:[NSTableView class]]) {
        //        [[self _tableViewsAheadOfTableView:sender]
        //            makeObjectsPerformSelector:@selector(deselectAll:)
        //                            withObject:self];
    }
    
    if([self action])
        [[self target] performSelector:[self action] withObject:self];
}



- (void)tableViewDoubleClick:(id)sender {
    if([self doubleAction])
        [[self target] performSelector:[self doubleAction] withObject:self];
}



- (void)tableViewEscape:(id)sender {
    [sender deselectAll:self];
}



- (void)tableViewSpace:(id)sender {
    if([self spaceAction])
        [[self target] performSelector:[self spaceAction] withObject:self];
}

#pragma mark -

- (WITreeScrollView *)_newScrollViewWithTableView {
	NSTableColumn		*tableColumn;
	WITreeScrollView	*scrollView;
	WITreeTableView		*tableView;
	WITreeCell			*cell;
	NSRect				frame;
	
	frame = [self frame];
	
	cell = [[[WITreeCell alloc] init] autorelease];
	[cell setFont:_font];
	
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:@""] autorelease];
	[tableColumn setEditable:NO];
	[tableColumn setDataCell:cell];
	[tableColumn setWidth:230.0];
	
	tableView = [[[WITreeTableView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 10.0, 10.0)
										   tableColumns:[NSArray arrayWithObject:tableColumn]] autorelease];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView setHeaderView:NULL];
	[tableView setAllowsMultipleSelection:YES];
	[tableView setFocusRingType:NSFocusRingTypeNone];
	[tableView setTarget:self];
	[tableView setAction:@selector(tableViewSingleClick:)];
	[tableView setDoubleAction:@selector(tableViewDoubleClick:)];
	[tableView setEscapeAction:@selector(tableViewEscape:)];
	[tableView setSpaceAction:@selector(tableViewSpace:)];
	[tableView setFont:_font];
	[tableView setRowHeight:_rowHeight];
	[tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
	[tableView setDraggingSourceOperationMask:_draggingSourceOperationMaskForLocal forLocal:YES];
	[tableView setDraggingSourceOperationMask:_draggingSourceOperationMaskForNonLocal forLocal:NO];
	[tableView registerForDraggedTypes:[self registeredDraggedTypes]];
	[tableView setMenu:[self menu]];
	
	scrollView = [[WITreeScrollView alloc] initWithFrame:NSMakeRect(0.0, -1.0, _WITreeViewInitialTableViewWidth, frame.size.height + 2.0)];
	[scrollView setDelegate:self];
	[scrollView setDocumentView:tableView];
	[scrollView setBorderType:NSBezelBorder];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setAutoresizingMask:NSViewHeightSizable];

	return scrollView;
}



- (NSString *)_pathForTableView:(NSTableView *)tableView {
	NSArray			*components;
	NSString		*path;
	NSUInteger		index;
	
	index = [_views indexOfObject:tableView];
	
	if(index == NSNotFound)
		return NULL;
	
	if(index == 0) {
		path = @"/";
	} else {
		components = [[self _path] pathComponents];
		
		if(index + 1 > [components count])
			return NULL;
		
		path = [NSString pathWithComponents:[components subarrayToIndex:index + 1]];
	}
	
	return path;
}



- (NSArray *)_tableViewsAheadOfTableView:(NSTableView *)tableView {
	NSUInteger		index;
	
	index = [_views indexOfObject:tableView];
	
	if(index == NSNotFound || index == [_views count] - 1)
		return NULL;
	
	return [_views subarrayWithRange:NSMakeRange(index + 1, [_views count] - index - 1)];
}



#pragma mark -

- (void)_WI_viewFrameDidChangeNotification:(NSNotification *)notification {
	[self _sizeToFit];
	[self _resizeDetailView];
}

@end



@implementation WITreeView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	
	[self _initTreeView];
	
    return self;
}



- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	
	[self _initTreeView];
	
    return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_views release];
	[_path release];
	[_font release];
	[_detailView release];
	[_dateFormatter release];
	[_detailTemplate release];
	
	[super dealloc];
}



#pragma mark -

- (IBAction)moreInfo:(id)sender {
	[[self delegate] treeView:self showMoreInfoForPath:[self _path]];
}



#pragma mark -

- (void)validate {
	if([[self delegate] respondsToSelector:@selector(treeView:validateMoreInfoButtonForPath:)])
		[_moreInfoButton setEnabled:[[self delegate] treeView:self validateMoreInfoButtonForPath:[self _path]]];
	
}



#pragma mark -

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}




- (id)delegate {
	return delegate;
}



- (void)setDataSource:(id)newDataSource {
	dataSource = newDataSource;
}



- (id)dataSource {
	return dataSource;
}



- (void)setTarget:(id)target {
	_target = target;
}



- (id)target {
	return _target;
}



- (void)setDoubleAction:(SEL)doubleAction {
	_doubleAction = doubleAction;
}



- (SEL)doubleAction {
	return _doubleAction;
}



- (void)setSpaceAction:(SEL)spaceAction {
	_spaceAction = spaceAction;
}



- (SEL)spaceAction {
	return _spaceAction;
}



- (void)setFont:(NSFont *)font {
	NSEnumerator		*enumerator;
	NSTableView			*tableView;
	
	[font retain];
	[_font release];
	
	_font = font;
	
	enumerator = [_views objectEnumerator];
	
	while((tableView = [enumerator nextObject]))
		[tableView setFont:font];
}



- (NSFont *)font {
	return _font;
}



- (void)setRowHeight:(CGFloat)rowHeight {
	NSEnumerator		*enumerator;
	NSTableView			*tableView;
	
	_rowHeight = rowHeight;
	
	enumerator = [_views objectEnumerator];
	
	while((tableView = [enumerator nextObject]))
		[tableView setRowHeight:rowHeight];
}



- (CGFloat)rowHeight {
	return _rowHeight;
}



#pragma mark -

- (void)setDraggingSourceOperationMask:(NSDragOperation)mask forLocal:(BOOL)isLocal {
	NSEnumerator		*enumerator;
	NSTableView			*tableView;
	
	if(isLocal)
		_draggingSourceOperationMaskForLocal = mask;
	else
		_draggingSourceOperationMaskForNonLocal = mask;
	
	enumerator = [_views objectEnumerator];
	
	while((tableView = [enumerator nextObject]))
		[tableView setDraggingSourceOperationMask:mask forLocal:isLocal];
}



#pragma mark -

- (NSString *)selectedPath {
	return _path;
}



- (NSArray *)selectedPaths {
	NSTableView			*tableView, *lastSelectedTableView;
	NSMutableArray		*paths;
	NSIndexSet			*indexes;
	NSString			*path, *name;
	NSUInteger			i, index, count;
	
	lastSelectedTableView	= NULL;
	paths					= [NSMutableArray array];
	count					= [_views count];
	
	for(i = 0; i < count; i++) {
		tableView = [_views objectAtIndex:i];
		
		if([[tableView selectedRowIndexes] firstIndex] != NSNotFound && [self _pathForTableView:tableView])
			lastSelectedTableView = tableView;
		else
			break;
	}
	
	if(lastSelectedTableView) {
		path		= [self _pathForTableView:lastSelectedTableView];
		indexes		= [lastSelectedTableView selectedRowIndexes];
		index		= [indexes firstIndex];
		
		while(index != NSNotFound) {
			name = [[self dataSource] treeView:self nameForRow:index inPath:path];
			
			[paths addObject:[path stringByAppendingPathComponent:name]];
			
			index = [indexes indexGreaterThanIndex:index];
		}
	}
	
	return paths;
}



#pragma mark -

- (void)selectPath:(NSString *)path byExtendingSelection:(BOOL)byExtendingSelection {
	NSTableView		*tableView, *selectedTableView;
	NSArray			*components;
	NSString		*partialPath, *component, *name;
	NSUInteger		i, j, viewCount, componentCount, fileCount;
	
	if([_views count] == 0)
		return;

	partialPath			= @"/";
	components			= [[path pathComponents] subarrayFromIndex:1];
	tableView			= [_views objectAtIndex:0];
	selectedTableView	= NULL;
	viewCount			= [_views count];
	componentCount		= [components count];
	
	for(i = 0; i < viewCount; i++) {
		tableView = [_views objectAtIndex:i];

		if(i < componentCount) {
			component = [components objectAtIndex:i];
			fileCount = [[self delegate] treeView:self numberOfItemsForPath:partialPath];
			
			for(j = 0; j < fileCount; j++) {
				name = [[self delegate] treeView:self nameForRow:j inPath:partialPath];
				
				if([component isEqualToString:name]) {
					[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:j]
						   byExtendingSelection:byExtendingSelection];
					
					selectedTableView = tableView;
					break;
				}
			}
			
			partialPath = [partialPath stringByAppendingPathComponent:component];
		} else {
			//[tableView deselectAll:self];
		}
			
	}
	
	if(selectedTableView) {
		[[self window] makeFirstResponder:selectedTableView];
		
		[self scrollPoint:NSMakePoint([self _widthOfTableViews:[_views indexOfObject:selectedTableView]], 0.0)];
	}
}



- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extendingSelection {
	NSTableView		*tableView;
	
	tableView = [_views objectAtIndex:[self _numberOfUsedPathComponents]];
	
	_selectingProgrammatically = YES;
	
	[tableView selectRowIndexes:indexes byExtendingSelection:extendingSelection];

	_selectingProgrammatically = NO;
}



#pragma mark -

- (NSRect)frameOfRow:(NSInteger)row inPath:(NSString *)path {
	NSTableView		*tableView;
	NSRect			frame;
	NSUInteger		i, count;
	
	count = [_views count];
	
	for(i = 0; i < count; i++) {
		tableView = [_views objectAtIndex:i];
		
		if([[self _pathForTableView:tableView] isEqualToString:path]) {
			frame = [tableView frameOfCellAtColumn:0 row:row];
			
			return [tableView convertRect:frame toView:NULL];
		}
	}
	
	return NSZeroRect;
}



#pragma mark -

- (void)reloadData {
	_reloadingData = YES;
	[_views makeObjectsPerformSelector:@selector(reloadData)];
	_reloadingData = NO;
}



#pragma mark -

- (void)keyDown:(NSEvent *)event {
	NSString		*path, *name;
	NSTableView		*tableView;
	NSIndexSet		*indexes;
	id				responder;
	NSUInteger		index;
	NSInteger		row;
	BOOL			handled = NO;
	unichar			key;
	
	key = [event character];
	
	if(key == NSRightArrowFunctionKey || key == NSLeftArrowFunctionKey) {
		responder = [[self window] firstResponder];
		
		if([responder isKindOfClass:[NSTableView class]]) {
			path = [self _pathForTableView:responder];
			
			if(path) {
				row = [responder selectedRow];
				
				if(row >= 0) {
					if(key == NSRightArrowFunctionKey) {
						name		= [[self dataSource] treeView:self nameForRow:row inPath:path];
						path		= [path stringByAppendingPathComponent:name];
						index		= [_views indexOfObject:responder];
						
						if(index == [_views count] - 2)
							[self _addTableView];
						
						tableView = [_views objectAtIndex:index + 1];

						if([[self dataSource] treeView:self numberOfItemsForPath:path] > 0) {
							if([tableView selectedRow] == -1) {
								[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
									   byExtendingSelection:NO];
							}
							
							[[self window] makeFirstResponder:tableView];
							
							name = [[self dataSource] treeView:self nameForRow:[tableView selectedRow] inPath:path];
							
							[self _setPath:[path stringByAppendingPathComponent:name]];
							
							[tableView scrollRowToVisible:0];
						
							handled = YES;
						}
					} else {
						index = [_views indexOfObject:responder];
						
						if(index > 0) {
							tableView = [_views objectAtIndex:index - 1];

							if([[responder selectedRowIndexes] count] > 1)
								path = [self _path];
							else
								path = [[self _path] stringByDeletingLastPathComponent];
							
							[self _setPath:path];
							
							[[self window] makeFirstResponder:tableView];
							
//							[[self _tableViewsAheadOfTableView:tableView]
//								makeObjectsPerformSelector:@selector(deselectAll:)
//												withObject:self];

							handled = YES;
						}
					}
					
					if(handled) {
						[self _sizeToFit];
						[self _scrollToSelection];
						
						indexes = [tableView selectedRowIndexes];
						
						if(![[self dataSource] treeView:self isPathExpandable:[self _path]] && [indexes count] == 1)
							[self _showDetailViewForPath:[self _path]];
						else
							[self _hideDetailView];

						[self reloadData];
					}
				}
			}
		}
	}
	
	if(!handled)
		[super keyDown:event];
}



- (void)scrollWheel:(NSEvent *)event {
	[[self enclosingScrollView] scrollWheel:event];
}



- (void)registerForDraggedTypes:(NSArray *)types {
	[_views makeObjectsPerformSelector:@selector(registerForDraggedTypes:) withObject:types];
	
	[super registerForDraggedTypes:types];
}



- (void)setMenu:(NSMenu *)menu {
	[_views makeObjectsPerformSelector:@selector(setMenu:) withObject:menu];
	
	[super setMenu:menu];
}


#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSString		*path;
	
	path = [self _pathForTableView:tableView];
	
	if(!path)
		return 0;

	return [[self dataSource] treeView:self numberOfItemsForPath:path];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString		*path;
	
	path = [self _pathForTableView:tableView];
	
	if(!path)
		return NULL;

	return [[self dataSource] treeView:self nameForRow:row inPath:path];
}



- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString		*path, *name;
	
	if([[self delegate] respondsToSelector:@selector(treeView:willDisplayCell:forPath:)]) {
		path = [self _pathForTableView:tableView];
		
		if(path) {
			name = [[self dataSource] treeView:self nameForRow:row inPath:path];
			path = [path stringByAppendingPathComponent:name];
			
			[cell setLeaf:![[self dataSource] treeView:self isPathExpandable:path]];

			[[self delegate] treeView:self willDisplayCell:cell forPath:path];
		}
	}
}



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSTableView		*tableView;
	NSString		*path, *name;
	NSIndexSet		*indexes;
	NSUInteger		index;
	
	[self _hideDetailView];
	
	if(_selectingProgrammatically || _reloadingData || _inChangedSelection)
		return;
	
	_inChangedSelection		= YES;
	tableView				= [notification object];
	indexes					= [tableView selectedRowIndexes];
	path					= [self _pathForTableView:tableView];
	
	if(!path)
		return;
	
	if([indexes count] == 1) {
		index		= [indexes firstIndex];
		name		= [[self dataSource] treeView:self nameForRow:index inPath:path];
		path		= [path stringByAppendingPathComponent:name];
			
		if([_views indexOfObject:tableView] == [_views count] - 2)
			[self _addTableView];
	}
	
//	[[self _tableViewsAheadOfTableView:tableView]
//		makeObjectsPerformSelector:@selector(deselectAll:)
//						withObject:self];
	
	[self _setPath:path];
	[self _sizeToFit];
	[self _scrollToSelection];

	[self reloadData];
	
	if(![[self dataSource] treeView:self isPathExpandable:path] && [indexes count] == 1)
		[self _showDetailViewForPath:path];
	
	_inChangedSelection = NO;
}



- (NSColor *)tableView:(NSTableView *)tableView labelColorForRow:(NSInteger)row {
	NSString		*path, *name;
	
	if([[self delegate] respondsToSelector:@selector(treeView:labelColorForPath:)]) {
		path = [self _pathForTableView:tableView];

		if(path) {
			name = [[self dataSource] treeView:self nameForRow:row inPath:path];
			path = [path stringByAppendingPathComponent:name];
			
			return [[self delegate] treeView:self labelColorForPath:path];
		}
	}
	
	return NULL;
}



- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	NSMutableArray		*paths;
	NSString			*path, *name;
	NSUInteger			index;
	
	if([[self delegate] respondsToSelector:@selector(treeView:writePaths:toPasteboard:)]) {
		path = [self _pathForTableView:tableView];
		
		if(path) {
			paths = [NSMutableArray array];
			index = [indexes firstIndex];
			
			while(index != NSNotFound) {
				name = [[self dataSource] treeView:self nameForRow:index inPath:path];
				
				[paths addObject:[path stringByAppendingPathComponent:name]];
				
				index = [indexes indexGreaterThanIndex:index];
			}
			
			return [[self delegate] treeView:self writePaths:paths toPasteboard:pasteboard];
		}
	}

	return NO;
}



- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	NSString		*path;
	
	if([[self delegate] respondsToSelector:@selector(treeView:validateDrop:proposedPath:)]) {
		if(operation == NSTableViewDropAbove) {
			[tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
			
			row = -1;
		}
		
		path = [self _pathForTableView:tableView];
		
		if(path) {
			if(row >= 0)
				path = [path stringByAppendingPathComponent:[[self dataSource] treeView:self nameForRow:row inPath:path]];
			
			if(![[self dataSource] treeView:self isPathExpandable:path]) {
				[tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
				
				path = [path stringByDeletingLastPathComponent];
			}
			
			return [[self delegate] treeView:self validateDrop:info proposedPath:path];
		}
	}
	
	return NSDragOperationNone;
}



- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	NSString		*path;
	
	if([[self delegate] respondsToSelector:@selector(treeView:acceptDrop:path:)]) {
		path = [self _pathForTableView:tableView];
		
		if(path) {
			if(row >= 0)
				path = [path stringByAppendingPathComponent:[[self dataSource] treeView:self nameForRow:row inPath:path]];
			
			return [[self delegate] treeView:self acceptDrop:info path:path];
		}
	}
	
	return NO;
}



- (void)tableViewShouldCopyInfo:(NSTableView *)tableView {
	if([[self delegate] respondsToSelector:@selector(treeViewShouldCopyInfo:)])
		[[self delegate] treeViewShouldCopyInfo:self];
}



- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)destination forDraggedRowsWithIndexes:(NSIndexSet *)indexes {
	NSMutableArray		*paths;
	NSString			*path, *name;
	NSUInteger			index;
	
	if([[self delegate] respondsToSelector:@selector(treeView:namesOfPromisedFilesDroppedAtDestination:forDraggedPaths:)]) {
		path = [self _pathForTableView:tableView];
		
		if(path) {
			paths = [NSMutableArray array];
			index = [indexes firstIndex];
			
			while(index != NSNotFound) {
				name = [[self dataSource] treeView:self nameForRow:index inPath:path];
				
				[paths addObject:[path stringByAppendingPathComponent:name]];
				
				index = [indexes indexGreaterThanIndex:index];
			}

			return [[self delegate] treeView:self namesOfPromisedFilesDroppedAtDestination:destination forDraggedPaths:paths];
		}
	}
	
	return NULL;
}



#pragma mark -

- (void)treeScrollView:(WITreeScrollView *)scrollView shouldResizeToPoint:(NSPoint)point {
	WITreeScrollView	*eachScollView;
	NSRect				frame, windowFrame;
	CGFloat				width, difference;
	NSUInteger			i, index, count;
	
	count = [_views count];
	index = [_views indexOfObject:[scrollView documentView]];
	
	if(index == NSNotFound)
		return;
	
	frame = [scrollView frame];
	width = point.x;
	difference = width - frame.size.width;
	
	if(width < _WITreeViewMinimumTableViewWidth)
		return;
	
	if([_detailView superview] && index == [self _numberOfUsedPathComponents]) {
		if(width < _WITreeViewMinimumDetailViewWidth)
			return;
	}
	
	frame.size.width = width;
	[scrollView setFrame:frame];

	if(index != count - 1) {
		for(i = index + 1; i < count; i++) {
			eachScollView = (WITreeScrollView *) [[_views objectAtIndex:i] enclosingScrollView];
			frame = [eachScollView frame];
			frame.origin.x += difference;
			[eachScollView setFrame:frame];
		}
	}
	
	[self _resizeDetailView];
	
	if(index == [self _numberOfUsedPathComponents]) {
		frame			= [scrollView frame];
		windowFrame		= [[self window] frame];
		width			= frame.origin.x + frame.size.width - 2.0;
		
		if(width > windowFrame.size.width) {
			windowFrame.size.width += difference;
			[[self window] setFrame:windowFrame display:YES];
		}
	}
}



#pragma mark -

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {
	[self _resizeDetailView];
}



- (NSArray *)webView:(WebView *)webView contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	return NULL;
}



#pragma mark -

- (void)drawRect:(NSRect)rect {
	[[NSColor whiteColor] set];
	NSRectFill(rect);
}

@end
