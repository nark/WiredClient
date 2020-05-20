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

#import "WCApplicationController.h"
#import "WCChatController.h"
#import "WCPublicChat.h"
#import "WCConversation.h"
#import "WCConversationController.h"
#import "WCMessage.h"
#import "WCMessages.h"
#import "WCFiles.h"
#import "WCFile.h"
#import "WCTransfers.h"
#import "WDWiredModel.h"
#import "WCDatabaseController.h"
#import "WCMessageTableCellView.h"

#import "NSManagedObjectContext+Fetch.h"
#import "NSString+Emoji.h"
#import "NSImage+Data.h"
#import "NSDate_TimeAgo/NSDate+TimeAgo.h"



@interface WCConversationController (Private)
- (void)_configureCell:(WCMessageTableCellView *)cell forRow:(NSInteger)row;
@end



@implementation WCConversationController (Private)

- (void)_configureCell:(WCMessageTableCellView *)cell forRow:(NSInteger)row {
    NSSortDescriptor        *descriptor;
    WDMessage               *message;
    
    descriptor      = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    message         = [[[[self conversation] messages] sortedArrayUsingDescriptors:@[descriptor]] objectAtIndex:row];
    
    if (message != nil) {
        cell.nickTextField.stringValue = [message nick];
        cell.serverNameTextField.stringValue = [[self conversation] serverName];
        cell.timeTextField.stringValue = [message.date timeAgoWithLimit:(3600*24*30) dateFormatter:[[WCApplicationController sharedController] dateFormatter]];
        cell.iconImageView.image = [[message user] icon];
        
        if(![[message messageString] hasPrefix:@"<img src='data:image/png;base64,"]) {
            NSAttributedString *attrString = [self _attributedStringWithClickableURLs:[[message messageString] stringByReplacingEmojiCheatCodesWithUnicode]];
            cell.messageTestField.attributedStringValue = attrString;
            cell.messageTestField.font = [self font];
            cell.messageTestField.allowsEditingTextAttributes = YES;
            
        } else if ([[message messageString] hasPrefix:@"<img src='http"]) {
            NSData *imageData = [[message messageString] dataUsingEncoding:NSUTF8StringEncoding];
            NSAttributedString *imageString = [[NSAttributedString alloc] initWithHTML:imageData documentAttributes:nil];
            
            if (imageString) {
                cell.messageTestField.attributedStringValue = imageString;
            }
        } else {
            NSArray *comps = [[message messageString] componentsSeparatedByString:@"base64,"];
            NSString *base64String = [[comps lastObject] substringToIndex:[[comps lastObject] length] - 3];
            NSImage *image = [NSImage imageWithData:[NSData dataWithBase64EncodedString:base64String]];
            
            id <NSTextAttachmentCell> attachmentCell = [[[NSTextAttachmentCell alloc] initImageCell:image] autorelease];

            NSTextAttachment *attachment = [[[NSTextAttachment alloc] initWithData:nil ofType:nil] autorelease];
            [attachment setAttachmentCell:attachmentCell];
            
            NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:attachment];

            cell.messageTestField.attributedStringValue = attrString;
        }
        
        if (message.directionValue == WDMessageFrom) {
            cell.iconImageView.image = [[self conversation] userIcon];
        } else {
            cell.iconImageView.image = [NSImage imageWithData:
                                        [NSData dataWithBase64EncodedString:[[WCSettings settings] objectForKey:WCIcon]]];
        }
    }
}



- (void)_sendLocalImage:(NSURL *)url {
    NSString            *html;
    NSString            *base64ImageString;
    NSData              *imageData;
    
    imageData = [NSData dataWithContentsOfURL:url];
    base64ImageString = [imageData base64EncodedString];
    
    html = [NSSWF:@"<img src='data:image/png;base64, %@'/>", base64ImageString];
    
    if(html && [html length] > 0) {
         [[WCMessages messages] sendMessage:html toUser:self.conversation.user];
    }
}


- (NSAttributedString *)_attributedStringWithClickableURLs:(NSString *)text {
    NSMutableAttributedString        *string;
    NSRange                           range;
    
    string = [NSMutableAttributedString attributedStringWithString:text];
    
    [string addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, text.length-1)];
    
    range = [text rangeOfRegex:[NSSWF:@"(^|\\s)(%@)(\\.|,|:|\\?|!)?(\\s|$)", [NSString URLRegex]]
                       options:RKLCaseless | RKLMultiline
                       capture:0];
    if (range.location != NSNotFound) {
        [string addAttribute:NSLinkAttributeName value:[text substringWithRange:range] range:range];
    }
    
    range = [text rangeOfRegex:[NSSWF:@"(^|\\s)(%@)(\\.|,|:|\\?|!)?(\\s|$)", [NSString schemelessURLRegex]]
                       options:RKLCaseless | RKLMultiline
                       capture:0];
    if (range.location != NSNotFound) {
        [string addAttribute:NSLinkAttributeName value:[text substringWithRange:range] range:range];
    }
    
    range = [text rangeOfRegex:[NSSWF:@"(^|\\s)(%@)(\\.|,|:|\\?|!)?(\\s|$)", [NSString mailtoURLRegex]]
                       options:RKLCaseless | RKLMultiline
                       capture:0];
    if (range.location != NSNotFound) {
        [string addAttribute:NSLinkAttributeName value:[text substringWithRange:range] range:range];
    }
    
    return string;
}


@end



@implementation WCConversationController

- (id)init {
	self = [super init];
	
    _conversation = nil;
	
	return self;
}



- (void)awakeFromNib {
    [_conversationTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [_conversationTableView setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleNone];
}


- (void)dealloc {
    
	[_font release];
	[_textColor release];
    [_URLTextColor release];
	[_backgroundColor release];
    
    [_conversation release];
	
	[super dealloc];
}




#pragma mark -

- (void)setConversation:(WDConversation *)conversation {
    [conversation retain];
	[_conversation release];
    
	_conversation	= conversation;
        
    [self reloadData];
}

- (WDConversation *)conversation {
    return _conversation;
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





#pragma mark -

- (void)appendMessage:(WDMessage *)message {
    NSInteger lastRow = [[[self conversation] messages] count] == 0 ? 0 : [[[self conversation] messages] count] - 1;
    NSIndexSet *lastRowIndexSet = [NSIndexSet indexSetWithIndex:lastRow];
        
    [_conversationTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:lastRow]
                                  withAnimation:NSTableViewAnimationEffectFade];
    
    [_conversationTableView scrollToBottomAnimated];
    
    lastRow = [_conversationTableView numberOfRows] - 1;
    lastRowIndexSet = [NSIndexSet indexSetWithIndex:lastRow];
    [_conversationTableView reloadDataForRowIndexes:lastRowIndexSet columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    
    [_conversationTableView scrollToBottomAnimated];
}








#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[_conversation messages] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    WCMessageTableCellView  *cell;
    
    cell = [tableView makeViewWithIdentifier:@"WCMessageTableCellView" owner:self];
    
    [self _configureCell:cell forRow:row];
        
    return cell;
}


#pragma mark -

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSArray *draggedFilenames = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    NSString *filepath = [draggedFilenames firstObject];
    NSImage *image = [NSImage imageWithContentsOfFile:filepath];
    
    if (!image) return NO;
    
    NSURL *url = [NSURL fileURLWithPath:filepath];
    
    [self _sendLocalImage:url];
    
    return YES;
}


- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    NSArray *draggedFilenames = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    if (![NSImage isImageAtPath:[draggedFilenames firstObject]]) {
        return NSDragOperationNone;
    }
    
    return NSDragOperationCopy;
}




#pragma mark -

- (void)reloadData {
    [_conversationTableView reloadData];
    
    [_conversationTableView performSelector:@selector(scrollToBottomAnimated) afterDelay:0.1];
}

- (void)reloadView {
    [_conversationTableView setNeedsDisplay];
}

@end
