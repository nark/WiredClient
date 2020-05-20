/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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
#import "WCApplicationController.h"
#import "WCBoard.h"
#import "WCBoardPost.h"
#import "WCBoards.h"
#import "WCBoardThread.h"
#import "WCBoardThreadController.h"
#import "WCChatController.h"
#import "WCFile.h"
#import "WCFiles.h"
#import "WCTransfers.h"
#import "WCBoardPostCellView.h"
#import "NSDate_TimeAgo/NSDate+TimeAgo.h"


@interface WCBoardThreadController(Private)

- (void)_configureCell:(WCBoardPostCellView *)cell forRow:(NSInteger)row;
- (NSAttributedString *)_attributedStringForPostText:(NSString *)text;

@end



@implementation WCBoardThreadController(Private)

- (void)_applyHTMLToMutableString:(NSMutableString *)text {
    NSString                        *substring;
    NSRange                         range;
    
    [WCChatController applyHTMLTagsForSmileysToMutableString:text];
    
    [text replaceOccurrencesOfString:@"&" withString:@"&#38;"];
    [text replaceOccurrencesOfString:@"<" withString:@"&#60;"];
    [text replaceOccurrencesOfString:@">" withString:@"&#62;"];
    [text replaceOccurrencesOfString:@"\"" withString:@"&#34;"];
    [text replaceOccurrencesOfString:@"\'" withString:@"&#39;"];
    [text replaceOccurrencesOfString:@"\n" withString:@"<br />"];
    
    [text replaceOccurrencesOfRegex:@"\\[code\\](.+?)\\[/code\\]"
                         withString:@"<pre>$1</pre>"
                            options:RKLCaseless | RKLDotAll];
    
    [text replaceOccurrencesOfRegex:@"\\[b\\](.+?)\\[/b\\]"
                         withString:@"<b>$1</b>"
                            options:RKLCaseless | RKLDotAll];
    [text replaceOccurrencesOfRegex:@"\\[u\\](.+?)\\[/u\\]"
                         withString:@"<u>$1</u>"
                            options:RKLCaseless | RKLDotAll];
    [text replaceOccurrencesOfRegex:@"\\[i\\](.+?)\\[/i\\]"
                         withString:@"<i>$1</i>"
                            options:RKLCaseless | RKLDotAll];
    [text replaceOccurrencesOfRegex:@"\\[color=(.+?)\\](.+?)\\[/color\\]"
                         withString:@"<span style=\"color: $1\">$2</span>"
                            options:RKLCaseless | RKLDotAll];
    [text replaceOccurrencesOfRegex:@"\\[center\\](.+?)\\[/center\\]"
                         withString:@"<div class=\"center\">$1</div>"
                            options:RKLCaseless | RKLDotAll];
    
    /* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
    do {
        range = [text rangeOfRegex:@"\\[url]wiredp7://(/.+?)\\[/url\\]" options:RKLCaseless capture:0];
        
        if(range.location != NSNotFound) {
            substring = [text substringWithRange:[text rangeOfRegex:@"\\[url]wiredp7://(/.+?)\\[/url\\]" options:RKLCaseless capture:1]];
            
            [text replaceCharactersInRange:range withString:
             [NSSWF:@"<img src=\"data:image/tiff;base64,%@\" /> <a href=\"wiredp7://%@\">%@</a>",
              _fileLinkBase64String, substring, substring]];
        }
    } while(range.location != NSNotFound);
    
    [text replaceOccurrencesOfRegex:@"\\[url=(.+?)\\](.+?)\\[/url\\]"
                         withString:@"<a href=\"$1\">$2</a>"
                            options:RKLCaseless];
    
    /* Do this in a custom loop to avoid corrupted strings when using $1 multiple times */
    do {
        range = [text rangeOfRegex:@"\\[url](.+?)\\[/url\\]" options:RKLCaseless capture:0];
        
        if(range.location != NSNotFound) {
            substring = [text substringWithRange:[text rangeOfRegex:@"\\[url](.+?)\\[/url\\]" options:RKLCaseless capture:1]];
            
            [text replaceCharactersInRange:range withString:[NSSWF:@"<a href=\"%@\">%@</a>", substring, substring]];
        }
    } while(range.location != NSNotFound);
    
    [text replaceOccurrencesOfRegex:@"\\[email=(.+?)\\](.+?)\\[/email\\]"
                         withString:@"<a href=\"mailto:$1\">$2</a>"
                            options:RKLCaseless];
    [text replaceOccurrencesOfRegex:@"\\[email](.+?)\\[/email\\]"
                         withString:@"<a href=\"mailto:$1\">$1</a>"
                            options:RKLCaseless];
    [text replaceOccurrencesOfRegex:@"\\[img](.+?)\\[/img\\]"
                         withString:@"<img src=\"$1\" alt=\"\" style=\"height:auto\" />&nbsp;"
                            options:RKLCaseless];
    
    [text replaceOccurrencesOfRegex:@"\\[quote=(.+?)\\](.+?)\\[/quote\\]"
                         withString:[NSSWF:@"<blockquote><b>%@</b><br />$2</blockquote>", NSLS(@"$1 wrote:", @"Board quote (nick)")]
                            options:RKLCaseless | RKLDotAll];
    
    [text replaceOccurrencesOfRegex:@"\\[quote\\](.+?)\\[/quote\\]"
                         withString:@"<blockquote>$1</blockquote>"
                            options:RKLCaseless | RKLDotAll];
}


- (NSString *)_CSS {
    return [NSSWF:@"html { color: %@; font-family: %@, Helvetica; font-size: %lupx; } img { height: auto; } br { margin-bottom: 30px; } pre { font-family: monospace; } blockquote { background: lightyellow; color: black; pre { background: lightgray; } }",
            [NSSWF:@"#%.6lx", (unsigned long)[[NSColor controlTextColor] HTMLValue]],
            [[self font] fontName],
            (NSInteger)[[self font] pointSize]];
}


- (NSAttributedString *)_attributedStringForPostText:(NSString *)text {
    NSString                *htmlBody;
    NSMutableString         *string;
    NSData                  *htmlData;
    NSAttributedString      *attrString;
    NSDictionary            *options;
    
    string = [NSMutableString stringWithString:text];
    
    [self _applyHTMLToMutableString:string];
    
    htmlBody        = [NSSWF:@"<html><head><style>%@</style></head>%@</html>", [self _CSS], [string stringByAppendingString:@"\n"]];
    htmlData        = [htmlBody dataUsingEncoding:NSUnicodeStringEncoding];
    options         = @{NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)};
    attrString      = [[NSAttributedString alloc] initWithHTML:htmlData options:options documentAttributes:nil];
    
    return [attrString autorelease];
}


- (void)_configureCell:(WCBoardPostCellView *)cell forRow:(NSInteger)row {
    WCBoardPost         *post;
    NSString            *formattedDate;
    NSImage             *iconImage;
    NSString            *icon, *editDate, *postDate, *postID;
    NSAttributedString  *text;
    WCAccount           *account;
    WIDateFormatter     *dateFormatter;
    BOOL                own, writable, replyDisabled, quoteDisabled, editDisabled, deleteDisabled, smart;
    NSArray             *posts = [@[_thread] arrayByAddingObjectsFromArray:[_thread posts]];
    
    post = [posts objectAtIndex:row];
    
    if (post) {
        dateFormatter       = [[WCApplicationController sharedController] dateFormatter];
        
        text                = [self attributedStringForText:[post text]];
        icon                = (NSString*)(([post icon] && sizeof([post icon]) > 0) ? [post icon] : _defaultIconBase64String);
        account             = [(WCServerConnection *)[_board connection] account];
        postDate            = [dateFormatter stringFromDate:[post postDate]];
        editDate            = ([post editDate] ? [dateFormatter stringFromDate:[post editDate]] : @"");
        
        postID              = ([post isKindOfClass:[WCBoardPost class]] ? [post postID] : [(WCBoardThread *)post threadID]);
        own                 = ([post isKindOfClass:[WCBoardPost class]] ? [post isOwnPost] : [(WCBoardThread *)post isOwnThread]);
        writable            = [_board isWritable];
        smart               = ([[[WCBoards boards] selectedBoard] isKindOfClass:[WCSmartBoard class]]);
        
        quoteDisabled       = !(([account boardAddPosts] && writable) || smart);
        editDisabled        = !((([account boardEditAllThreadsAndPosts] || ([account boardEditOwnThreadsAndPosts] && own)) && writable) || smart);
        deleteDisabled      = !((([account boardDeleteAllThreadsAndPosts] || ([account boardDeleteOwnThreadsAndPosts] && own)) && writable) || smart);
        replyDisabled       = !([account boardAddPosts] && writable);
        
        formattedDate       = (editDate.length > 0 ? [NSSWF:@"%@ - Edited on %@", postDate, editDate] : [NSSWF:@"%@", postDate]);
        iconImage           = [NSImage imageWithData:[NSData dataWithBase64EncodedString:icon]];
        
        [cell.nickTextField setStringValue:[post nick]];
        [cell.timeTextField setStringValue:formattedDate];
        
        [cell.messageTextField setMaximumNumberOfLines:0];
        [cell.messageTextField setAttributedStringValue:text];
        
        [cell.iconImageView setImage:iconImage];
        [cell.unreadImageView setHidden:![post isUnread]];
        
        [cell.replyButton setEnabled:!replyDisabled];
        [cell.quoteButton setEnabled:!quoteDisabled];
        [cell.editButton setEnabled:!editDisabled];
        [cell.deleteButton setEnabled:!deleteDisabled];
        
        [cell.quoteButton setTitle:NSLS(@"Quote", @"Quote post button title")];
        [cell.editButton setTitle:NSLS(@"Edit", @"Edit post button title")];
        [cell.deleteButton setTitle:NSLS(@"Delete", @"Delete post button title")];
        [cell.replyButton setTitle:NSLS(@"Post Reply", @"Post reply button title")];
        
        [cell setObjectValue:post];
        [cell setDelegate:self];
        
        cell.heightConstraint.constant = [text size].height;
        
        [text enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, text.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            if (![value isKindOfClass:[NSTextAttachment class]])
               return;
            
            NSTextAttachment *attachment = (NSTextAttachment*)value;
            CGRect bounds = attachment.bounds;
            attachment.bounds = bounds;
                            
            cell.heightConstraint.constant = [text size].height ;
        }];
        
       // [cell.messageTextField sizeToFit];
    }
}


@end





@implementation WCBoardThreadController

- (id)init {
	self = [super initWithNibName:@"ThreadView" bundle:nil];
		
	_loadingQueue = [[NSOperationQueue alloc] init];
	[_loadingQueue setMaxConcurrentOperationCount:1];
	
	_dateFormatter		= [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	_fileLinkBase64String		= [[[[NSImage imageNamed:@"FileLink"] TIFFRepresentation] base64EncodedString] retain];
	_defaultIconBase64String	= [[[[NSImage imageNamed:@"DefaultIcon"] TIFFRepresentation] base64EncodedString] retain];

	return self;
}



- (void)dealloc {
	[_thread release];
	
	[_loadingQueue release];
	
	[_fileLinkBase64String release];
	[_defaultIconBase64String release];
	
	[_font release];
	[_textColor release];
	[_backgroundColor release];
    [_URLTextColor release];
	
	[_dateFormatter release];
	
	[_selectPost release];
	
	[super dealloc];
}




- (void)awakeFromNib {
    _scrollEndReached = NO;
    
    id clipView = [[_threadTableView enclosingScrollView] contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myBoundsChangeNotificationHandler:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:clipView];
}


- (void)myBoundsChangeNotificationHandler:(NSNotification *)aNotification {
    if ([aNotification object] == [[_threadTableView enclosingScrollView] contentView]) {
        NSClipView *clipView = [[_threadTableView enclosingScrollView] contentView];
        CGFloat currentPosition = [clipView bounds].origin.y + [clipView bounds].size.height;
        CGFloat tableViewHeight = [_threadTableView bounds].size.height;

        if (currentPosition > tableViewHeight) {
            _scrollEndReached = YES;
        }
    }
}


# pragma mark -

- (NSAttributedString *)attributedStringForText:(NSString *)text {
    //NSString * string = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@"\n"];
    
    return [self _attributedStringForPostText:text];
}


#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _thread ? [[_thread posts] count] + 1 : 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    WCBoardPostCellView  *cell;
    
    cell = [tableView makeViewWithIdentifier:@"WCBoardPostCellView" owner:self];
    
    [self _configureCell:cell forRow:row];
            
    return cell;
}



#pragma mark -

- (void)postCell:(WCBoardPostCellView *)cell replyButtonClicked:(NSButton *)sender {
    [[WCBoards boards] replyToThread];
}

- (void)postCell:(WCBoardPostCellView *)cell quoteButtonClicked:(NSButton *)sender {
    WCBoardPost     *post;
    NSString        *selectedText;
    
    post = (WCBoardPost *)[cell objectValue];
    
    selectedText = [[[cell messageTextField] stringValue] substringWithRange:[[[cell messageTextField] currentEditor] selectedRange]];
        
    if(post)
        [[WCBoards boards] replyToPostWithID:[post postID] selectedText:selectedText];
}

- (void)postCell:(WCBoardPostCellView *)cell editButtonClicked:(NSButton *)sender {
    WCBoardPost *post;
    
    if ([[cell objectValue] isKindOfClass:[WCBoardPost class]]) {
        post = (WCBoardPost *)[cell objectValue];
        
        if(post)
            [[WCBoards boards] editPostWithID:[post postID]];
    } else {
        [[WCBoards boards] editPostWithID:[_thread threadID]];
    }
}

- (void)postCell:(WCBoardPostCellView *)cell deleteButtonClicked:(NSButton *)sender {
        WCBoardPost *post;
    
    post = (WCBoardPost *)[cell objectValue];
    
    if(post)
        [[WCBoards boards] deletePostWithID:[post postID]];
}




#pragma mark -

- (void)setBoard:(WCBoard *)board {
	[board retain];
	[_board release];
	
	[_loadingQueue cancelAllOperations];
	
	_board = board;
}



- (WCBoard *)board {
	return _board;
}



- (void)setThread:(WCBoardThread *)thread {
	[thread retain];
	[_thread release];
	
	[_loadingQueue cancelAllOperations];
	
	_thread = thread;
}



- (WCBoardThread *)thread {
	return _thread;
}





- (void)setFont:(NSFont *)font {
	[font retain];
	[_font release];
	
	_font = font;
}



- (NSFont *)font {
	return _font;
}



- (void)setTextColor:(NSColor *)textColor {
	[textColor retain];
	[_textColor release];
	
	_textColor = textColor;
}



- (NSColor *)textColor {
	return _textColor;
}



- (void)setURLTextColor:(NSColor *)textColor {
    [textColor retain];
    [_URLTextColor release];
    
    _URLTextColor = textColor;
}



- (NSColor *)URLTextColor {
    return _URLTextColor;
}



- (void)setBackgroundColor:(NSColor *)backgroundColor {
	[backgroundColor retain];
	[_backgroundColor release];
	
	_backgroundColor = backgroundColor;
}



- (NSColor *)backgroundColor {
	return _backgroundColor;
}

- (NSTableView *)threadTableView {
    return _threadTableView;
}

#pragma mark -

- (void)reloadData {
    _scrollEndReached = NO;

    [_threadTableView reloadData];
    [_threadTableView setNeedsLayout:YES];
    [_threadTableView layoutSubtreeIfNeeded];
    
    if([_threadTableView numberOfRows] > 1)
        [_threadTableView performSelector:@selector(scrollToBottomAnimated) afterDelay:0.2];
        
}



- (void)reloadDataAndScrollToCurrentPosition {
    [self reloadData];
}



- (void)reloadDataAndSelectPost:(WCBoardPost *)selectPost {
    [self reloadData];
    
//    [_threadTableView noteNumberOfRowsChanged];
//
//    if([_threadTableView numberOfRows] > 1)
//        [_threadTableView performSelector:@selector(scrollToBottomAnimated) afterDelay:0.2];
    
//    NSArray *syms = [NSThread  callStackSymbols];
//    if ([syms count] > 1) {
//        NSLog(@"<%@ %p> %@ - caller: %@ ", [self class], self, NSStringFromSelector(_cmd),[syms objectAtIndex:1]);
//    } else {
//        NSLog(@"<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd));
//    }
//    [self _reloadDataAndScrollToCurrentPosition:NO selectPost:selectPost];
}




#pragma mark -
#pragma mark Reload

- (void)reloadView {
    [_threadTableView reloadData];
}


@end
