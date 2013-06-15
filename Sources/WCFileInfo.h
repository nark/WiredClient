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

#import "WCInfoController.h"

@class WCFile;

@interface WCFileInfo : WCInfoController {
	IBOutlet NSImageView			*_iconImageView;
	IBOutlet NSTextField			*_fileTextField;

	IBOutlet NSTextField			*_kindTitleTextField;
	IBOutlet NSTextField			*_kindTextField;
	IBOutlet NSPopUpButton			*_kindPopUpButton;
	IBOutlet NSTextField			*_sizeTitleTextField;
	IBOutlet NSTextField			*_sizeTextField;
	IBOutlet NSTextField			*_whereTitleTextField;
	IBOutlet NSTextField			*_whereTextField;
	IBOutlet NSTextField			*_createdTitleTextField;
	IBOutlet NSTextField			*_createdTextField;
	IBOutlet NSTextField			*_modifiedTitleTextField;
	IBOutlet NSTextField			*_modifiedTextField;
	IBOutlet NSTextField			*_labelTitleTextField;
	IBOutlet NSPopUpButton			*_labelPopUpButton;
	IBOutlet NSTextField			*_ownerTitleTextField;
	IBOutlet NSPopUpButton			*_ownerPopUpButton;
	IBOutlet NSPopUpButton			*_ownerPermissionsPopUpButton;
	IBOutlet NSTextField			*_groupTitleTextField;
	IBOutlet NSPopUpButton			*_groupPopUpButton;
	IBOutlet NSPopUpButton			*_groupPermissionsPopUpButton;
	IBOutlet NSTextField			*_everyoneTitleTextField;
	IBOutlet NSPopUpButton			*_everyonePermissionsPopUpButton;
	IBOutlet NSTextField			*_commentTitleTextField;
	IBOutlet NSTextField			*_commentTextField;

	NSArray							*_files;
	NSMutableArray					*_info;
	WIDateFormatter					*_dateFormatter;
	WISizeFormatter					*_sizeFormatter;
}

+ (id)fileInfoWithConnection:(WCServerConnection *)connection file:(WCFile *)file;
+ (id)fileInfoWithConnection:(WCServerConnection *)connection files:(NSArray *)files;

@end
