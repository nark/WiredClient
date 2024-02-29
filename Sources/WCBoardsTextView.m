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

#import "WCBoardsTextView.h"
#import "WCFile.h"
#import "WCFiles.h"

@implementation WCBoardsTextView

- (NSArray *)acceptableDragTypes {
	NSArray		*acceptableDragTypes;
	
	acceptableDragTypes = [super acceptableDragTypes];
	
	return [acceptableDragTypes arrayByAddingObject:WCFilePboardType];
}



- (NSArray *)readablePasteboardTypes {
	NSArray		*readablePasteboardTypes;
	
	readablePasteboardTypes = [super readablePasteboardTypes];
	
	return [readablePasteboardTypes arrayByAddingObject:WCFilePboardType];
}



- (NSDragOperation)dragOperationForDraggingInfo:(id <NSDraggingInfo>)info type:(NSString *)type {
	if([type isEqualToString:WCFilePboardType])
		return NSDragOperationCopy;
	
	return [super dragOperationForDraggingInfo:info type:type];
}



- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pasteboard type:(NSString *)type {
    NSEnumerator        *enumerator;
    NSMutableArray        *array;
    NSArray                    *sources;
    WCFile                    *file;
    
    if([type isEqualToString:WCFilePboardType]) {
        array        = [NSMutableArray array];
        sources        = [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:type]];
        enumerator    = [sources objectEnumerator];
        
        while((file = [enumerator nextObject])) {
            NSString *escapedPath = [[file path] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
            NSString *fileString = [NSString stringWithFormat:@"wiredp7://%@%@",
                                    escapedPath,
                                    [file isFolder] ? @"/" : @""];
            [array addObject:fileString];
        }
        
        [[self window] makeFirstResponder:self];
        NSRange replacementRange = NSMakeRange([[self string] length], 0); // Appending at the end
        [self insertText:[array componentsJoinedByString:@", "] replacementRange:replacementRange];
        
        return YES;
    }

    return [super readSelectionFromPasteboard:pasteboard type:type];
}


@end
